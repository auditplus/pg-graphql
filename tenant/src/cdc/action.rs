use super::Column;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InsertAction {
    pub columns: Vec<Column>,
    pub schema: String,
    pub table: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateAction {
    pub identity: Vec<Column>,
    pub columns: Vec<Column>,
    pub schema: String,
    pub table: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteAction {
    pub identity: Vec<Column>,
    pub schema: String,
    pub table: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "action")]
pub enum Action {
    #[serde(rename = "B")]
    Begin,
    #[serde(rename = "C")]
    Commit,
    #[serde(rename = "I")]
    Insert(InsertAction),
    #[serde(rename = "U")]
    Update(UpdateAction),
    #[serde(rename = "D")]
    Delete(DeleteAction),
}
