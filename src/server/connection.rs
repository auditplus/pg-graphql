use crate::server::constants::*;
use crate::server::session::Session;
use crate::server::WEBSOCKETS;
use axum::extract::ws::{Message, WebSocket};
use channel::{self, Receiver, Sender};
use futures_util::stream::{SplitSink, SplitStream};
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use std::collections::BTreeMap;
use std::sync::Arc;
use tokio::sync::{RwLock, Semaphore};
use tokio::task::JoinSet;
use tokio_util::sync::CancellationToken;
use tracing::Span;
use tracing::{debug, error, trace};
use uuid::Uuid;

pub struct Connection {
    pub id: Uuid,
    pub session: Session,
    pub vars: BTreeMap<String, Value>,
    pub limiter: Arc<Semaphore>,
    pub canceller: CancellationToken,
    pub channels: (Sender<Message>, Receiver<Message>),
}

impl Connection {
    /// Instantiate a new RPC
    pub fn new(id: Uuid, mut session: Session) -> Arc<RwLock<Connection>> {
        // Create and store the RPC connection
        Arc::new(RwLock::new(Connection {
            id,
            session,
            vars: BTreeMap::new(),
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
        // Calculate the length of the message
        let _len = match msg {
            Message::Text(ref msg) => {
                // Retrieve the length of the message
                msg.len()
            }
            _ => unreachable!(),
        };
        // Parse the request
        async move {
            let _span = Span::current();
            println!("{:?}", &msg);
            // Process the message
            let _res = Connection::process_message(rpc.clone(), &msg).await;
            // Process the response
            if chn.send(msg).await.is_ok() {
                println!("message sent");
            };
        }
        .await;
        // Drop the rate limiter permit
        drop(permit);
    }

    pub async fn process_message(_rpc: Arc<RwLock<Connection>>, _msg: &Message) -> String {
        debug!("Process RPC request");
        "Processed".to_string()
    }
}
