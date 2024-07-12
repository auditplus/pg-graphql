use std::env::var;

#[derive(Clone)]
pub struct EnvVars {
    pub listen_port: String,
    pub db_url: String,
    pub jwt_private_key: String,
    pub vault_key: String,
    pub gst_host: String,
    pub gst_auth_key: String,
}

impl EnvVars {
    pub fn init() -> Self {
        println!("LISTEN_PORT: {}", var("LISTEN_PORT").unwrap());
        println!("DB_URL: {}", var("DB_URL").unwrap());
        println!("JWT_PRIVATE_KEY: {}", var("JWT_PRIVATE_KEY").unwrap());
        println!("VAULT_KEY: {}", var("VAULT_KEY").unwrap());
        println!("GST_HOST: {}", var("GST_HOST").unwrap());
        println!("GST_AUTH_KEY: {}", var("GST_AUTH_KEY").unwrap());

        Self {
            listen_port: var("LISTEN_PORT").expect("LISTEN_PORT not set"),
            db_url: var("DB_URL").expect("DB_URL not set"),
            jwt_private_key: var("JWT_PRIVATE_KEY").expect("JWT_PRIVATE_KEY not set"),
            vault_key: var("VAULT_KEY").expect("VAULT_KEY not set"),
            gst_host: var("GST_HOST").expect("GST_HOST not set"),
            gst_auth_key: var("GST_AUTH_KEY").expect("GST_AUTH_KEY not set"),
        }
    }
}
