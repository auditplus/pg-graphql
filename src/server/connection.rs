use crate::env::EnvVars;
use crate::server::constants::*;
use crate::server::session::Session;
use crate::server::{switch_auth_context_ws, WEBSOCKETS};
use crate::{graphql, sql};
use axum::extract::ws::{Message, WebSocket};
use channel::{self, Receiver, Sender};
use futures_util::stream::{SplitSink, SplitStream};
use futures_util::{SinkExt, StreamExt};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, FromQueryResult, JsonValue, Statement, TransactionTrait};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::sync::Arc;
use tokio::sync::{RwLock, Semaphore};
use tokio::task::JoinSet;
use tokio_util::sync::CancellationToken;
use tracing::Span;
use tracing::{debug, error, trace};
use uuid::Uuid;

#[derive(Debug, Serialize)]
#[non_exhaustive]
#[serde(untagged)]
pub enum Data {
    One(serde_json::Value),
    All(Vec<serde_json::Value>),
}

#[derive(Debug, Clone, Deserialize)]
pub struct LoginParams {
    username: String,
    password: String,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "method", content = "params", rename_all = "snake_case")]
pub enum RequestData {
    Sql(sql::QueryParams),
    Gql(graphql::QueryParams),
    Login(LoginParams),
    Authenticate(String),
}

#[derive(Debug, Deserialize)]
pub struct Request {
    pub id: String,
    pub data: RequestData,
}

#[derive(Debug, Serialize)]
pub struct Response {
    id: String,
    result: Data,
}

impl Response {
    pub async fn send(self, chn: &Sender<Message>) {
        let msg = Message::Text(serde_json::to_string(&self).unwrap());
        // Send the message to the write channel
        if chn.send(msg).await.is_ok() {
            println!("Msg sent");
        };
    }
}

pub struct Connection {
    pub id: Uuid,
    pub session: Session,
    pub env_vars: EnvVars,
    pub vars: BTreeMap<String, serde_json::Value>,
    pub limiter: Arc<Semaphore>,
    pub canceller: CancellationToken,
    pub channels: (Sender<Message>, Receiver<Message>),
}

impl Connection {
    /// Instantiate a new RPC
    pub fn new(id: Uuid, mut session: Session, env_vars: EnvVars) -> Arc<RwLock<Connection>> {
        // Create and store the RPC connection
        Arc::new(RwLock::new(Connection {
            id,
            session,
            vars: BTreeMap::new(),
            env_vars,
            limiter: Arc::new(Semaphore::new(*WEBSOCKET_MAX_CONCURRENT_REQUESTS)),
            canceller: CancellationToken::new(),
            channels: channel::bounded(*WEBSOCKET_MAX_CONCURRENT_REQUESTS),
        }))
    }

    /// Serve the RPC endpoint
    pub async fn serve(rpc: Arc<RwLock<Connection>>, ws: WebSocket) {
        // Get the WebSocket ID
        let id = rpc.read().await.id;
        // Split the socket into sending and receiving streams
        let (sender, receiver) = ws.split();
        // Create an internal channel for sending and receiving
        let internal_sender = rpc.read().await.channels.0.clone();
        let internal_receiver = rpc.read().await.channels.1.clone();

        trace!("WebSocket {} connected", id);

        // Add this WebSocket to the list
        WEBSOCKETS.write().await.insert(id, rpc.clone());

        // Spawn async tasks for the WebSocket
        let mut tasks = JoinSet::new();
        tasks.spawn(Self::ping(rpc.clone(), internal_sender.clone()));
        tasks.spawn(Self::read(rpc.clone(), receiver, internal_sender.clone()));
        tasks.spawn(Self::write(rpc.clone(), sender, internal_receiver.clone()));

        // Wait until all tasks finish
        while let Some(res) = tasks.join_next().await {
            if let Err(err) = res {
                error!("Error handling RPC connection: {}", err);
            }
        }

        internal_sender.close();

        trace!("WebSocket {} disconnected", id);

        // Remove this WebSocket from the list
        WEBSOCKETS.write().await.remove(&id);
    }

    /// Send Ping messages to the client
    async fn ping(rpc: Arc<RwLock<Connection>>, internal_sender: Sender<Message>) {
        // Create the interval ticker
        let mut interval = tokio::time::interval(WEBSOCKET_PING_FREQUENCY);
        // Clone the WebSocket cancellation token
        let canceller = rpc.read().await.canceller.clone();
        // Loop, and listen for messages to write
        loop {
            tokio::select! {
                //
                biased;
                // Check if this has shutdown
                _ = canceller.cancelled() => break,
                // Send a regular ping message
                _ = interval.tick() => {
                    // Create a new ping message
                    let msg = Message::Ping(vec![]);
                    // Close the connection if the message fails
                    if internal_sender.send(msg).await.is_err() {
                        // Cancel the WebSocket tasks
                        rpc.read().await.canceller.cancel();
                        // Exit out of the loop
                        break;
                    }
                },
            }
        }
    }

    /// Write messages to the client
    async fn write(
        rpc: Arc<RwLock<Connection>>,
        mut sender: SplitSink<WebSocket, Message>,
        mut internal_receiver: Receiver<Message>,
    ) {
        // Clone the WebSocket cancellation token
        let canceller = rpc.read().await.canceller.clone();
        // Loop, and listen for messages to write
        loop {
            tokio::select! {
                //
                biased;
                // Check if this has shutdown
                _ = canceller.cancelled() => break,
                // Wait for the next message to send
                Some(res) = internal_receiver.next() => {
                    // Send the message to the client
                    if let Err(_err) = sender.send(res).await {
                        // Output any errors if not a close error
                        //if err.to_string() != CONN_CLOSED_ERR {
                    //		debug!("WebSocket error: {:?}", err);
                    //	}
                        // Cancel the WebSocket tasks
                        rpc.read().await.canceller.cancel();
                        // Exit out of the loop
                        break;
                    }
                },
            }
        }
    }

    /// Read messages sent from the client
    async fn read(
        rpc: Arc<RwLock<Connection>>,
        mut receiver: SplitStream<WebSocket>,
        internal_sender: Sender<Message>,
    ) {
        // Store spawned tasks so we can wait for them
        let mut tasks = JoinSet::new();
        // Clone the WebSocket cancellation token
        let canceller = rpc.read().await.canceller.clone();
        // Loop, and listen for messages to write
        loop {
            tokio::select! {
                //
                biased;
                // Check if this has shutdown
                _ = canceller.cancelled() => break,
                // Remove any completed tasks
                Some(out) = tasks.join_next() => match out {
                    // The task completed successfully
                    Ok(_) => continue,
                    // There was an uncaught panic in the task
                    Err(err) => {
                        // There was an error with the task
                        trace!("WebSocket request error: {:?}", err);
                        // Cancel the WebSocket tasks
                        rpc.read().await.canceller.cancel();
                        // Exit out of the loop
                        break;
                    }
                },
                // Wait for the next received message
                Some(msg) = receiver.next() => match msg {
                    // We've received a message from the client
                    Ok(msg) => match msg {
                        Message::Text(_) => {
                            tasks.spawn(Connection::handle_message(rpc.clone(), msg, internal_sender.clone()));
                        }
                        Message::Binary(_) => {
                            tasks.spawn(Connection::handle_message(rpc.clone(), msg, internal_sender.clone()));
                        }
                        Message::Close(_) => {
                            // Respond with a close message
                            if let Err(err) = internal_sender.send(Message::Close(None)).await {
                                trace!("WebSocket error when replying to the Close frame: {:?}", err);
                            };
                            // Cancel the WebSocket tasks
                            rpc.read().await.canceller.cancel();
                            // Exit out of the loop
                            break;
                        }
                        _ => {
                            // Ignore everything else
                        }
                    },
                    Err(err) => {
                        // There was an error with the WebSocket
                        trace!("WebSocket error: {:?}", err);
                        // Cancel the WebSocket tasks
                        rpc.read().await.canceller.cancel();
                        // Exit out of the loop
                        break;
                    }
                }
            }
        }
        // Wait for all tasks to finish
        while let Some(res) = tasks.join_next().await {
            if let Err(err) = res {
                // There was an error with the task
                trace!("WebSocket request error: {:?}", err);
            }
        }
        // Abort all tasks
        tasks.shutdown().await;
    }

    /// Handle individual WebSocket messages
    async fn handle_message(rpc: Arc<RwLock<Connection>>, msg: Message, chn: Sender<Message>) {
        // Acquire concurrent request rate limiter
        let permit = rpc
            .read()
            .await
            .limiter
            .clone()
            .acquire_owned()
            .await
            .unwrap();
        let req: Request = match msg {
            Message::Text(ref msg) => {
                // Retrieve the length of the message
                serde_json::from_str(msg).unwrap()
            }
            _ => unreachable!(),
        };
        // Parse the request
        async move {
            let _span = Span::current();
            let req_id = req.id.clone();
            // Process the message
            let res = Connection::process_message(rpc.clone(), req).await;
            // Process the response
            let res = Response {
                id: req_id,
                result: res,
            };
            res.send(&chn).await
        }
        .await;
        // Drop the rate limiter permit
        drop(permit);
    }

    pub async fn process_message(rpc: Arc<RwLock<Connection>>, req: Request) -> Data {
        match req.data {
            RequestData::Sql(data) => Connection::sql(rpc, data).await,
            RequestData::Gql(data) => Connection::gql(rpc, data).await,
            RequestData::Login(data) => Connection::login(rpc, data).await,
            RequestData::Authenticate(data) => Connection::authenticate(rpc, data).await,
        }
    }

    async fn sql(rpc: Arc<RwLock<Connection>>, params: sql::QueryParams) -> Data {
        let db = rpc.read().await.session.db.begin().await.unwrap();
        switch_auth_context_ws(&db, &rpc.read().await.session)
            .await
            .unwrap();
        let out = sql::execute_query_all(&db, params).await;
        Data::All(out)
    }

    async fn gql(rpc: Arc<RwLock<Connection>>, params: graphql::QueryParams) -> Data {
        println!("ROle {}", rpc.read().await.session.role);
        println!("ROle {:?}", &params);
        let db = rpc.read().await.session.db.begin().await.unwrap();
        switch_auth_context_ws(&db, &rpc.read().await.session)
            .await
            .unwrap();
        let out = graphql::execute_query(&db, params).await;
        println!("{:?}", &out);
        Data::One(out)
    }

    async fn login(rpc: Arc<RwLock<Connection>>, params: LoginParams) -> Data {
        let txn = rpc.read().await.session.db.begin().await.unwrap();
        let stm = format!(
            "select set_config('app.env.jwt_secret_key', '{}', true);",
            &rpc.read().await.env_vars.jwt_private_key
        );
        let stm = Statement::from_string(Postgres, stm);
        txn.execute(stm).await.unwrap();
        let stm = format!("select login('{}', '{}')", params.username, params.password);
        let stm = Statement::from_string(Postgres, stm);
        let out = JsonValue::find_by_statement(stm)
            .one(&txn)
            .await
            .unwrap()
            .unwrap();
        let out = out.get("login").cloned().unwrap();
        println!("{:?}", out);
        txn.commit().await.unwrap();
        Data::One(out)
    }

    async fn authenticate(rpc: Arc<RwLock<Connection>>, token: String) -> Data {
        let txn = rpc.read().await.session.db.begin().await.unwrap();
        let stm = Statement::from_string(Postgres, format!("select authenticate('{}')", token));
        let org = rpc.read().await.session.organization.clone();
        let out = JsonValue::find_by_statement(stm)
            .one(&txn)
            .await
            .unwrap()
            .unwrap();
        let out = out.get("authenticate").cloned().unwrap();
        if org != out["org"].as_str().unwrap_or_default() {
            panic!("Incorrect organization");
        }
        rpc.write().await.session.role = format!("{}_admin", org);
        Data::One(serde_json::Value::Null)
    }
}