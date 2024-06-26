use crate::env::EnvVars;
use crate::failure::Failure;
use crate::rpc::constants::*;
use crate::rpc::session::Session;
use crate::rpc::WEBSOCKETS;
use crate::sql;
use crate::sql::custom::MyJsonValue;
use anyhow::Result;
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
use tracing::{error, trace};
use uuid::Uuid;

#[derive(Debug, Serialize)]
#[non_exhaustive]
#[serde(untagged)]
pub enum Data {
    One(Option<serde_json::Value>),
    All(Vec<serde_json::Value>),
}

#[derive(Debug, Clone, Deserialize)]
pub struct LoginParams {
    username: String,
    password: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TransactionAction {
    Begin,
    Commit,
    Rollback,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "method", content = "params", rename_all = "snake_case")]
pub enum RequestData {
    Query(sql::QueryParams),
    Login(LoginParams),
    Authenticate(String),
    Transaction(TransactionAction),
}

#[derive(Debug, Deserialize)]
pub struct Request {
    pub id: String,
    pub data: RequestData,
}

#[derive(Debug, Serialize)]
pub struct Response {
    id: String,
    result: Result<Data, Failure>,
}

impl Response {
    pub async fn send(self, chn: &Sender<Message>) {
        let msg = Message::Text(serde_json::to_string(&self).unwrap());
        // Send the message to the write channel
        if chn.send(msg).await.is_ok() {
            // println!("Msg sent");
        };
    }
}

async fn switch_auth_context<C>(conn: &C, session: &Session) -> Result<(), Failure>
where
    C: ConnectionTrait,
{
    let mut role = format!("{}_anon", session.organization);
    if let Some(ref claims) = session.claims {
        let role_name = claims
            .get("role")
            .and_then(|x| x.as_str())
            .ok_or(Failure::custom("role not found in context"))?;
        role = format!("{}_{}", session.organization, role_name);
        let stm = Statement::from_string(
            Postgres,
            format!("select set_config('my.claims', '{}', true);", &claims),
        );
        let _ = conn.execute(stm).await.unwrap();
    }
    let stm = Statement::from_string(Postgres, format!("set local role to {}", role));
    conn.execute(stm).await.unwrap();
    Ok(())
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
    pub fn new(id: Uuid, session: Session, env_vars: EnvVars) -> Arc<RwLock<Connection>> {
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
        let req = match msg {
            Message::Text(ref msg) => {
                // Retrieve the length of the message
                serde_json::from_str::<Request>(msg).ok()
            }
            _ => unreachable!(),
        };
        // Parse the request
        async move {
            let _span = Span::current();
            if let Some(req) = req {
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
        }
        .await;
        // Drop the rate limiter permit
        drop(permit);
    }

    pub async fn process_message(
        rpc: Arc<RwLock<Connection>>,
        req: Request,
    ) -> Result<Data, Failure> {
        match req.data {
            RequestData::Query(data) => Connection::query(rpc, data).await,
            RequestData::Login(data) => Connection::login(rpc, data).await,
            RequestData::Authenticate(data) => Connection::authenticate(rpc, data).await,
            RequestData::Transaction(data) => Connection::transaction(rpc, data).await,
        }
    }

    async fn transaction(
        rpc: Arc<RwLock<Connection>>,
        params: TransactionAction,
    ) -> Result<Data, Failure> {
        match params {
            TransactionAction::Begin => {
                let txn = rpc.read().await.session.db.begin().await?;
                let _ = rpc.write().await.session.txn.insert(txn);
            }
            TransactionAction::Commit => {
                if let Some(x) = rpc.write().await.session.txn.take() {
                    x.commit().await?;
                }
            }
            TransactionAction::Rollback => {
                if let Some(x) = rpc.write().await.session.txn.take() {
                    x.rollback().await?;
                }
            }
        }
        Ok(Data::One(Some(serde_json::Value::Null)))
    }

    async fn query(
        rpc: Arc<RwLock<Connection>>,
        params: sql::QueryParams,
    ) -> Result<Data, Failure> {
        let txn = rpc.read().await.session.db.begin().await?;
        //switch_auth_context(&txn, &rpc.read().await.session).await?;
        let vals: Vec<sea_orm::Value> = params
            .variables
            .into_iter()
            .map(sea_orm::Value::from)
            .collect();
        let stm = Statement::from_sql_and_values(Postgres, params.query, vals);
        let out = txn
            .query_all(stm)
            .await?
            .into_iter()
            .filter_map(|r| MyJsonValue::from_query_result(&r, "").ok().map(|x| x.0))
            .collect::<Vec<serde_json::Value>>();
        txn.commit().await?;
        Ok(Data::All(out))
    }

    async fn login(rpc: Arc<RwLock<Connection>>, params: LoginParams) -> Result<Data, Failure> {
        let txn = rpc.read().await.session.db.begin().await?;
        let stm = format!(
            "select set_config('app.env.jwt_secret_key', '{}', true);",
            &rpc.read().await.env_vars.jwt_private_key
        );
        let stm = Statement::from_string(Postgres, stm);
        txn.execute(stm).await?;
        let stm = format!("select login('{}', '{}')", params.username, params.password);
        let stm = Statement::from_string(Postgres, stm);
        let out = JsonValue::find_by_statement(stm)
            .one(&txn)
            .await?
            .ok_or(Failure::INTERNAL_ERROR)?
            .get("login")
            .cloned()
            .ok_or(Failure::INTERNAL_ERROR)?;
        let claims = out.get("claims").cloned().ok_or(Failure::INTERNAL_ERROR)?;
        let _ = rpc.write().await.session.claims.insert(claims);
        txn.commit().await.unwrap();
        Ok(Data::One(Some(out)))
    }

    async fn authenticate(rpc: Arc<RwLock<Connection>>, token: String) -> Result<Data, Failure> {
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
        let _ = rpc.write().await.session.claims.insert(out.clone());
        Ok(Data::One(Some(out)))
    }
}
