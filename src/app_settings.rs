use crate::EnvVars;

#[derive(Clone, serde::Serialize)]
pub struct AppSettings {
    pub jwt_private_key: String,
    pub gst_host: String,
    pub gst_auth_key: String,
}

impl AppSettings {
    pub fn build(env: EnvVars) -> String {
        let settings = Self {
            jwt_private_key: env.jwt_private_key.clone(),
            gst_host: env.gst_host.clone(),
            gst_auth_key: env.gst_auth_key.clone(),
        };
        serde_json::to_string(&settings).unwrap()
    }
}
