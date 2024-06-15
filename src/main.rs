mod connection;
mod context;
mod db;
mod env;
mod graphql;
mod organization;
mod sql;
mod utils;

use crate::connection::DbConnection;
use crate::context::RequestContext;
use async_graphql::http::GraphiQLSource;
use axum::http::StatusCode;
use axum::response::Html;
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::Router;
use env::EnvVars;
use sea_orm::prelude::Expr;
use sea_orm::sea_query::{Alias, PostgresQueryBuilder, Query};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{Condition, ConnectionTrait, FromQueryResult, JsonValue, Statement};

use crate::db::DatabaseSessions;
use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;

#[derive(Clone)]
pub struct AppState {
    pub db: DbConnection,
    pub env_vars: EnvVars,
}

pub async fn switch_auth_context<C>(
    conn: &C,
    ctx: RequestContext,
    env_vars: &EnvVars,
) -> Result<(), (StatusCode, String)>
where
    C: ConnectionTrait,
{
    let stm = Statement::from_string(
        Postgres,
        format!(
            "select set_config('app.env.jwt_secret_key', '{}', true);",
            &env_vars.jwt_private_key
        ),
    );
    conn.execute(stm).await.unwrap();
    let mut role = format!("{}_anon", ctx.org);
    // println!("role before token check: {}", &role);
    let stm = Statement::from_string(Postgres, format!("set local role to {}", role));
    conn.execute(stm).await.unwrap();

    if let Some(token) = &ctx.token {
        let stm = Statement::from_string(Postgres, format!("select authenticate('{}')", token));
        let out = JsonValue::find_by_statement(stm)
            .one(conn)
            .await
            .unwrap()
            .unwrap();
        let out = out.get("authenticate").cloned().unwrap();
        if ctx.org == out["org"].as_str().unwrap_or_default() {
            role = format!("{}_{}", &ctx.org, out["name"].as_str().unwrap());
            let stm = Statement::from_string(Postgres, format!("set local role to {}", role));
            conn.execute(stm).await.unwrap();
        } else {
            return Err((StatusCode::BAD_REQUEST, "Invalid organization token".into()));
        }
    }
    Ok(())
}

async fn graphiql() -> impl IntoResponse {
    Html(GraphiQLSource::build().endpoint("/graphql").finish())
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
    DatabaseSessions::initialize();

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

    let app = Router::new()
        .route("/org-init", post(organization::organization_init))
        .route("/graphql", get(graphiql).post(graphql::execute))
        .route("/sql/all", post(sql::query_all))
        .route("/sql/one", post(sql::query_one))
        .route("/db/start-transaction", get(db::start_transaction))
        .route("/db/commit-transaction", get(db::commit_transaction))
        .layer(CorsLayer::permissive())
        .with_state(app_state);

    println!(
        "\nGraphiQL IDE: http://localhost:{}\n",
        &env_vars.listen_port
    );

    axum::serve(
        TcpListener::bind(format!("0.0.0.0:{}", &env_vars.listen_port))
            .await
            .unwrap(),
        app,
    )
    .await
    .unwrap();
}
