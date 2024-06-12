use std::env::var;

#[derive(Clone)]
pub struct EnvVars {
    pub listen_port: String,
    pub db_url: String,
    pub jwt_private_key: String,
    pub auth_key: String,
}

impl EnvVars {
    pub fn init() -> Self {
        println!("LISTEN_PORT: {}", var("LISTEN_PORT").unwrap());
        println!("DB_URL: {}", var("DB_URL").unwrap());
        println!("JWT_PRIVATE_KEY: {}", var("JWT_PRIVATE_KEY").unwrap());
        println!("AUTH_KEY: {}", var("AUTH_KEY").unwrap());

        Self {
            listen_port: var("LISTEN_PORT").expect("LISTEN_PORT not set"),
            db_url: var("DB_URL").expect("DB_URL not set"),
            jwt_private_key: var("JWT_PRIVATE_KEY").expect("JWT_PRIVATE_KEY not set"),
            auth_key: var("AUTH_KEY").expect("AUTH_KEY not set"),
        }
    }
}
