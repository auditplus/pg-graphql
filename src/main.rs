mod db;
mod handler;
mod server;
mod session;
mod shutdown;
mod sql;
mod util;

use crate::db::DbConnection;
use sea_orm::prelude::Expr;
use sea_orm::sea_query::{Alias, PostgresQueryBuilder, Query};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{Condition, FromQueryResult, JsonValue, Statement};
use serde::{Deserialize, Serialize};
use std::env;
use tenant::cdc;
use tracing_subscriber::EnvFilter;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DbConfig {
    pub jwt_private_key: String,
    pub vault_key: String,
    pub gst_host: String,
    pub gst_auth_key: String,
}

#[derive(Clone, Debug, Deserialize)]
pub struct AppConfig {
    pub listen_port: String,
    pub db_url: String,
    #[serde(flatten)]
    pub db_config: DbConfig,
}

#[derive(Clone)]
pub struct AppState {
    pub db: DbConnection,
    pub app_config: AppConfig,
}

fn stream_db(db_name: String) {
    let (tx, rx) = channel::unbounded::<cdc::Transaction>();
    let rx_db_name = db_name.clone();
    tokio::spawn(async move { handler::rpc::start_db_change_stream(rx_db_name, rx).await });
    tokio::spawn(async move { cdc::watch::watch(db_name, tx).await });
}

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();
    if let Ok(level) = std::env::var("RUST_LOG") {
        let filter = &format!("{}={level}", env!("CARGO_PKG_NAME").replace('-', "_"),);
        tracing_subscriber::fmt()
            .with_env_filter(EnvFilter::new(filter))
            .init();
    }
    let app_config = envy::from_env::<AppConfig>().unwrap();
    println!("{:#?}", &app_config);

    let env_db_url = format!("{}/postgres", &app_config.db_url);
    let conn = sea_orm::Database::connect(env_db_url)
        .await
        .expect("Database connection failed");

    let conds = Condition::all()
        .add(Expr::col(Alias::new("datistemplate")).eq(false))
        .add(Expr::col(Alias::new("datname")).ne("postgres"));
    let q = Query::select()
        .expr(Expr::col(Alias::new("datname")))
        .from(Alias::new("pg_database"))
        .cond_where(conds)
        .to_string(PostgresQueryBuilder);
    let stm = Statement::from_string(Postgres, &q);
    let out = JsonValue::find_by_statement(stm).all(&conn).await.unwrap();
    let mut orgs: Vec<String> = vec![];
    let conn = DbConnection::default();
    for data in out {
        let db_name = data.get("datname").unwrap().as_str().unwrap();
        let db_url = format!("{}/{db_name}", &app_config.db_url);
        let db = sea_orm::Database::connect(db_url)
            .await
            .expect("Database connection failed");
        orgs.push(db_name.to_string());
        conn.add(db_name, db).await;
        stream_db(db_name.to_string());
    }
    println!("\nConnected organizations:\n[ {} ]\n", orgs.join(", "));

    let app_state = AppState {
        db: conn,
        app_config: app_config.clone(),
    };

    server::serve(app_state).await;
}
