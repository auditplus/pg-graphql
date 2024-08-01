use axum::body::Bytes;
use axum::extract::ws::{Message, WebSocket};
use axum::extract::{State, WebSocketUpgrade};
use axum::response::IntoResponse;
use channel::{Receiver, Sender};
use once_cell::sync::Lazy;
use std::collections::HashMap;
use std::sync::Arc;
use tenant::rpc::{ListenChannelResponse, QueryStreamNotification};
use tokio::sync::RwLock;
use uuid::Uuid;

use super::rpc::connection::Connection;
use super::rpc::constants::*;
use crate::session::{Session, SessionType};
use crate::AppConfig;
use crate::{cdc, AppState};

type WebSocketConnection = Arc<RwLock<Connection>>;

type WebSockets = RwLock<HashMap<Uuid, WebSocketConnection>>;

type QueryStreamNotificationSet = (Uuid, QueryStreamNotification);
pub static WEBSOCKETS: Lazy<WebSockets> = Lazy::new(WebSockets::default);
pub static QUERY_STREAM_NOTIFIER: Lazy<Sender<QueryStreamNotificationSet>> =
    Lazy::new(init_query_stream_notifier);

mod connection;

mod constants;

static CONN_CLOSED_ERR: &str = "Connection closed normally";

fn init_query_stream_notifier() -> Sender<QueryStreamNotificationSet> {
    let (tx, rx) = channel::bounded::<QueryStreamNotificationSet>(100);
    listen_query_stream_notifications(rx);
    tx
}

pub async fn start_db_change_stream(db_name: String, rx: Receiver<cdc::Transaction>) {
    while let Ok(txn) = rx.recv().await {
        let data = ListenChannelResponse {
            channel: "db_changes".into(),
            data: txn,
        };
        let data = serde_json::to_string(&data).unwrap();
        let msg = Message::Text(data);

        for s in WEBSOCKETS.read().await.iter() {
            let session = &s.1.read().await.session;
            if session.organization == db_name
                && session.claim_type() == Some(SessionType::PosServer)
                && s.1.read().await.channels.0.send(msg.clone()).await.is_err()
            {
                println!("Error on sending db changes");
            }
        }
    }
}

pub fn listen_query_stream_notifications(rx: Receiver<QueryStreamNotificationSet>) {
    tokio::task::spawn(async move {
        while let Ok((socket_id, notification)) = rx.recv().await {
            if let Some(socket) = WEBSOCKETS.read().await.get(&socket_id) {
                let data = serde_json::to_string(&notification).unwrap();
                if socket
                    .read()
                    .await
                    .channels
                    .0
                    .send(Message::Text(data))
                    .await
                    .is_err()
                {
                    println!("Error sending task notifications");
                }
            }
        }
    });
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
        .on_upgrade(move |socket| handle_socket(socket, session, id, app_state.app_config))
}

async fn handle_socket(ws: WebSocket, sess: Session, id: Uuid, app_config: AppConfig) {
    // Create a new connection instance
    let rpc = Connection::new(id, sess, app_config);
    // Serve the socket connection requests
    Connection::serve(rpc, ws).await;
}

pub async fn post_handler(_body: Bytes) -> impl IntoResponse {
    println!("Post called");
}
