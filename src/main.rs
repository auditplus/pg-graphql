mod connection;
mod context;
mod organization;
mod utils;

use crate::connection::{Database, DbConnection};
use crate::context::RequestContext;
use async_graphql::http::GraphiQLSource;
use axum::http::StatusCode;
use axum::response::Html;
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::Router;
use sea_orm::prelude::Expr;
use sea_orm::sea_query::{Alias, PostgresQueryBuilder, Query};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{
    Condition, ConnectionTrait, FromQueryResult, JsonValue, Statement, TransactionTrait,
};

use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;

#[derive(Clone)]
pub struct AppState {
    pub db: DbConnection,
}

async fn gql(
    db: Database,
    ctx: RequestContext,
    axum::Json(payload): axum::Json<serde_json::Value>,
) -> Result<axum::Json<serde_json::Value>, (StatusCode, String)> {
    let gql = payload.get("query").unwrap().as_str().unwrap();
    let vars = payload
        .get("variables")
        .cloned()
        .unwrap_or(serde_json::Value::Object(serde_json::Map::new()));

    let txn = db.begin().await.unwrap();
    let stm = Statement::from_string(Postgres, "set local search_path to public");
    txn.execute(stm).await.unwrap();
    let mut role = format!("{}_anon", ctx.org);
    println!("role before token check: {}", &role);
    if let Some(token) = &ctx.token {
        let stm = Statement::from_string(Postgres, format!("select authenticate('{}')", token));
        let out = JsonValue::find_by_statement(stm)
            .one(&txn)
            .await
            .unwrap()
            .unwrap();
        let out = out.get("authenticate").cloned().unwrap();
        role = format!("{}_{}", &ctx.org, out["name"].as_str().unwrap());
    }

    println!("role after token check: {}", &role);
    let stm = Statement::from_string(Postgres, format!("set local role to {}", role));
    txn.execute(stm).await.unwrap();

    let q = format!(
        "select graphql.resolve($${}$$, '{}'::jsonb) as out;",
        gql, vars
    );
    let stm = Statement::from_string(Postgres, &q);
    let out = JsonValue::find_by_statement(stm)
        .one(&txn)
        .await
        .unwrap()
        .unwrap();
    let out = out.get("out").cloned().unwrap();
    txn.commit().await.unwrap();
    Ok(axum::Json(out))
}

async fn graphiql() -> impl IntoResponse {
    Html(GraphiQLSource::build().endpoint("/").finish())
}

#[tokio::main]
async fn main() {
    let db_url = "postgresql://postgres:1@192.168.1.31:5432/postgres";
    let conn = sea_orm::Database::connect(db_url)
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

    let conn = DbConnection::default();
    for db in out {
        let db_name = db.get("datname").unwrap().as_str().unwrap();
        let db_url = format!("postgresql://postgres:1@192.168.1.31:5432/{db_name}");
        let db = sea_orm::Database::connect(db_url)
            .await
            .expect("Database connection failed");
        conn.add(db_name, db);
    }

    let app_state = AppState { db: conn };

    let app = Router::new()
        .route("/org-init", post(organization::organization_init))
        .route("/graphql", get(graphiql).post(gql))
        .layer(CorsLayer::permissive())
        .with_state(app_state);

    println!("GraphiQL IDE: http://localhost:8000");

    axum::serve(TcpListener::bind("0.0.0.0:8000").await.unwrap(), app)
        .await
        .unwrap();
}
