use crate::EnvVars;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use tenant::failure::Failure;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct AppSettings {
    pub jwt_private_key: String,
    pub vault_key: String,
    pub gst_host: String,
    pub gst_auth_key: String,
}

impl AppSettings {
    pub fn to_string(&self) -> Result<String, Failure> {
        let x = serde_json::to_string(self).map_err(|e| Failure::custom(e.to_string()))?;
        Ok(x)
    }
}
