pub mod init;
pub mod rpc;

pub mod value;

pub mod failure;

use serde::{Deserialize, Serialize};
pub use value::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueryParams {
    pub query: String,
    #[serde(default)]
    pub variables: Vec<SQLValue>,
}

impl QueryParams {
    pub fn new(query: impl Into<String>) -> Self {
        Self {
            query: query.into(),
            variables: Vec::new(),
        }
    }
}
