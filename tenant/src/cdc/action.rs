use crate::cdc::ChangeData;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InsertAction {
    #[serde(rename = "columns")]
    pub data: ChangeData,
    pub schema: String,
    pub table: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateAction {
    #[serde(rename = "identity")]
    pub key: ChangeData,
    #[serde(rename = "columns")]
    pub data: ChangeData,
    pub schema: String,
    pub table: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteAction {
    #[serde(rename = "identity")]
    pub key: ChangeData,
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
