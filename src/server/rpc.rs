use crate::server::connection::Connection;
use crate::server::constants::*;
use crate::server::session::Session;
use crate::server::WEBSOCKETS;
use axum::body::Bytes;
use axum::extract::ws::WebSocket;
use axum::extract::WebSocketUpgrade;
use axum::response::IntoResponse;
use uuid::Uuid;

pub async fn get_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
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
        .on_upgrade(move |socket| handle_socket(socket, Session::default(), id))
}

async fn handle_socket(ws: WebSocket, sess: Session, id: Uuid) {
    // Format::Unsupported is not in the PROTOCOLS list so cannot be the value of format here
    // Create a new connection instance
    let rpc = Connection::new(id, sess);
    // Serve the socket connection requests
    Connection::serve(rpc, ws).await;
}

pub async fn post_handler(_body: Bytes) -> impl IntoResponse {
    println!("Post called");
}
