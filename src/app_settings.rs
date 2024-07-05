use crate::EnvVars;
use anyhow::Result;
use tenant::failure::Failure;

#[derive(Clone, serde::Serialize)]
pub struct AppSettings {
    pub jwt_private_key: String,
    pub gst_host: String,
    pub gst_auth_key: String,
}

impl From<EnvVars> for AppSettings {
    fn from(env: EnvVars) -> Self {
        Self {
            jwt_private_key: env.jwt_private_key.clone(),
            gst_host: env.gst_host.clone(),
            gst_auth_key: env.gst_auth_key.clone(),
        }
    }
}

impl AppSettings {
    pub fn to_string(&self) -> Result<String, Failure> {
        let x = serde_json::to_string(self).map_err(|e| Failure::custom(e.to_string()))?;
        Ok(x)
    }
}
