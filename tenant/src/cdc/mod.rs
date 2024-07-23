pub mod action;

#[cfg(not(target_arch = "wasm32"))]
pub mod watch;

use action::Action;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Column {
    pub name: String,
    pub value: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub xid: Option<u32>,
    pub commit_time: Option<u32>,
    pub events: Vec<Action>,
}
