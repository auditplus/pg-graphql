use crate::env::EnvVars;
use crate::rpc::connection::Connection;
use crate::rpc::constants::*;
use crate::session::Session;
use crate::{cdc, AppState};
use axum::body::Bytes;
use axum::extract::ws::{Message, WebSocket};
use axum::extract::{State, WebSocketUpgrade};
use axum::response::IntoResponse;
use channel::Receiver;
use once_cell::sync::Lazy;
use serde::Serialize;
use std::collections::HashMap;
use std::sync::Arc;
use tenant::rpc::ListenChannelResponse;
use tokio::sync::RwLock;
use uuid::Uuid;

type WebSocketConnection = Arc<RwLock<Connection>>;
type WebSockets = RwLock<HashMap<Uuid, WebSocketConnection>>;
pub static WEBSOCKETS: Lazy<WebSockets> = Lazy::new(WebSockets::default);

mod connection;

mod constants;

pub async fn start_db_change_stream(rx: Receiver<cdc::Transaction>) {
    while let Ok(txn) = rx.recv().await {
        let data = ListenChannelResponse {
            channel: "db_changes",
            data: txn,
        };
        let data = serde_json::to_string(&data).unwrap();

        for s in WEBSOCKETS.read().await.iter() {
            if s.1
                .read()
                .await
                .channels
                .0
                .send(Message::Text(data.clone()))
                .await
                .is_err()
            {
                println!("Error on sending db changes");
            }
        }
    }
}

pub async fn get_handler(
    State(app_state): State<AppState>,
    session: Session,
    ws: WebSocketUpgrade,
) -> impl IntoResponse {
    let id = Uuid::new_v4();

    // Check if a connection with this id already exists
    if WEBSOCKETS.read().await.contains_key(&id) {
        panic!("Connection exists");
        //return Err(Error::Request);
    }
    // Now let's upgrade the WebSocket connection
    ws
        // Set the potential WebSocket protocols
        .protocols(PROTOCOLS)
        // Set the maximum WebSocket frame size
        .max_frame_size(*WEBSOCKET_MAX_FRAME_SIZE)
        // Set the maximum WebSocket message size
        .max_message_size(*WEBSOCKET_MAX_MESSAGE_SIZE)
        // Handle the WebSocket upgrade and process messages
        .on_upgrade(move |socket| handle_socket(socket, session, id, app_state.env_vars))
}

async fn handle_socket(ws: WebSocket, sess: Session, id: Uuid, env_vars: EnvVars) {
    // Create a new connection instance
    let rpc = Connection::new(id, sess, env_vars);
    // Serve the socket connection requests
    Connection::serve(rpc, ws).await;
}

pub async fn post_handler(_body: Bytes) -> impl IntoResponse {
    println!("Post called");
}
