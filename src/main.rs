mod connection;
mod context;
mod env;
mod graphql;
mod organization;
mod rpc;
mod server;
mod shutdown;
mod sql;
mod utils;

use crate::connection::DbConnection;
use env::EnvVars;
use sea_orm::prelude::Expr;
use sea_orm::sea_query::{Alias, PostgresQueryBuilder, Query};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{Condition, FromQueryResult, JsonValue, Statement};

#[derive(Clone)]
pub struct AppState {
    pub db: DbConnection,
    pub env_vars: EnvVars,
}

#[tokio::main]
async fn main() {
    dotenv::dotenv().ok();
    let env_vars = env::EnvVars::init();
    let env_db_url = format!("{}/postgres", &env_vars.db_url);
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
    for db in out {
        let db_name = db.get("datname").unwrap().as_str().unwrap();
        let db_url = format!("{}/{db_name}", &env_vars.db_url);
        let db = sea_orm::Database::connect(db_url)
            .await
            .expect("Database connection failed");
        orgs.push(db_name.to_string());
        conn.add(db_name, db);
    }
    println!("\nConnected organizations:\n[ {} ]\n", orgs.join(", "));

    let app_state = AppState {
        db: conn,
        env_vars: env_vars.clone(),
    };

    server::serve(app_state).await;
}
