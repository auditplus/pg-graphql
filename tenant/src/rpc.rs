use crate::failure::Failure;
use crate::QueryParams;
use axum::extract::ws;
use channel::Sender;
use serde::{Deserialize, Serialize};
use tokio_tungstenite::tungstenite;
use uuid::Uuid;

pub type QueryResult = Result<serde_json::Value, Failure>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueryStreamNotification {
    pub stream_id: Uuid,
    pub result: Option<serde_json::Value>,
}

#[derive(Debug, Serialize)]
pub struct ListenChannelResponse<T>
where
    T: Serialize + std::fmt::Debug,
{
    pub channel: &'static str,
    pub data: T,
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
}

impl DbResponse {
    pub fn try_from_message(message: &tungstenite::Message) -> anyhow::Result<Option<Self>> {
        match message {
            tungstenite::Message::Text(text) => {
                let res = serde_json::from_str(text)?;
                Ok(res)
            }
            tungstenite::Message::Binary(..) => {
                println!("Received a binary from the server");
                Ok(None)
            }
            tungstenite::Message::Ping(..) => {
                //println!("Received a ping from the server");
                Ok(None)
            }
            tungstenite::Message::Pong(..) => {
                println!("Received a pong from the server");
                Ok(None)
            }
            tungstenite::Message::Frame(..) => {
                println!("Received an unexpected frame from server");
                Ok(None)
            }
            tungstenite::Message::Close(..) => {
                println!("Received an unexpected close message");
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

impl Response {
    pub async fn send(self, chn: &Sender<ws::Message>) {
        let msg = ws::Message::Text(serde_json::to_string(&self).unwrap());
        // Send the message to the write channel
        if chn.send(msg).await.is_ok() {
            // println!("Msg sent");
        };
    }
}
