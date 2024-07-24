use crate::QueryParams;
use crate::{cdc, failure::Failure};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

pub type QueryResult = Result<serde_json::Value, Failure>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueryStreamNotification {
    pub stream_id: Uuid,
    pub data: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListenChannelResponse {
    pub channel: String,
    pub data: cdc::Transaction,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoginParams {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TransactionAction {
    Begin,
    Commit,
    Rollback,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueryStreamParams {
    pub id: Uuid,
    pub params: QueryParams,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "method", content = "params", rename_all = "snake_case")]
pub enum RequestData {
    Query(QueryParams),
    Authenticate(String),
    Login(LoginParams),
    Transaction(TransactionAction),
    QueryStream(QueryStreamParams),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Request {
    pub id: String,
    pub data: RequestData,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum DbResponse {
    QueryResponse(Response),
    QueryStreamNotification(QueryStreamNotification),
    ListenChanel(ListenChannelResponse),
}

#[cfg(not(target_arch = "wasm32"))]
impl DbResponse {
    pub fn try_from_message(
        message: &tokio_tungstenite::tungstenite::Message,
    ) -> anyhow::Result<Option<Self>> {
        match message {
            tokio_tungstenite::tungstenite::Message::Text(text) => {
                let res = serde_json::from_str(text).unwrap();
                Ok(res)
            }
            tokio_tungstenite::tungstenite::Message::Binary(..) => {
                println!("Received a binary from the server");
                Ok(None)
            }
            tokio_tungstenite::tungstenite::Message::Ping(..) => {
                //println!("Received a ping from the server");
                Ok(None)
            }
            tokio_tungstenite::tungstenite::Message::Pong(..) => {
                println!("Received a pong from the server");
                Ok(None)
            }
            tokio_tungstenite::tungstenite::Message::Frame(..) => {
                println!("Received an unexpected frame from server");
                Ok(None)
            }
            tokio_tungstenite::tungstenite::Message::Close(..) => {
                println!("Received an unexpected close message");
                Ok(None)
            }
        }
    }
}

#[cfg(target_arch = "wasm32")]
impl DbResponse {
    pub fn try_from_message(message: &ws_stream_wasm::WsMessage) -> anyhow::Result<Option<Self>> {
        match message {
            ws_stream_wasm::WsMessage::Text(text) => {
                let res = serde_json::from_str(text).unwrap();
                Ok(res)
            }
            ws_stream_wasm::WsMessage::Binary(binary) => {
                println!("Received a binary from the server");
                Ok(None)
            }
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Response {
    pub id: String,
    pub result: QueryResult,
}

#[cfg(not(target_arch = "wasm32"))]
impl Response {
    pub async fn send(self, chn: &channel::Sender<axum::extract::ws::Message>) {
        let msg = axum::extract::ws::Message::Text(serde_json::to_string(&self).unwrap());
        // Send the message to the write channel
        if chn.send(msg).await.is_ok() {
            // println!("Msg sent");
        };
    }
}
