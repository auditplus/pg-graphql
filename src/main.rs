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
    Condition, ConnectionTrait, DatabaseTransaction, FromQueryResult, JsonValue, Statement,
    TransactionTrait,
};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use tokio::net::TcpListener;
use tokio::sync::{OnceCell, RwLock};
use tokio::{task, time};
use tower_http::cors::CorsLayer;

static DB_SESSIONS: OnceCell<DatabaseSessions> = OnceCell::const_new();

#[derive(Debug)]
pub struct DatabaseSessions {
    inner: Arc<RwLock<HashMap<uuid::Uuid, Arc<DatabaseTransaction>>>>,
    keys: Arc<RwLock<Vec<uuid::Uuid>>>,
}

impl Default for DatabaseSessions {
    fn default() -> Self {
        Self {
            inner: Arc::new(RwLock::new(HashMap::new())),
            keys: Arc::new(RwLock::new(Vec::new())),
        }
    }
}

impl DatabaseSessions {
    pub fn initialize() {
        DB_SESSIONS.set(DatabaseSessions::default()).unwrap();
    }

    pub fn instance() -> &'static DatabaseSessions {
        DB_SESSIONS.get().unwrap()
    }

    pub async fn add(&self, db: &Database) -> (uuid::Uuid, Arc<DatabaseTransaction>) {
        let id = uuid::Uuid::new_v4();
        let txn = Arc::new(db.begin().await.unwrap());
        self.inner.write().await.insert(id, txn.clone());
        self.keys.write().await.push(id);
        (id, txn)
    }

    pub async fn get(&self, key: &uuid::Uuid) -> Option<Arc<DatabaseTransaction>> {
        self.inner.read().await.get(key).cloned()
    }

    pub async fn take(&self, key: &uuid::Uuid) -> Option<Arc<DatabaseTransaction>> {
        self.inner.write().await.remove(key)
    }
}

#[derive(Clone)]
pub struct AppState {
    pub db: DbConnection,
}

pub async fn switch_auth_context<C>(
    conn: &C,
    ctx: RequestContext,
) -> Result<(), (StatusCode, String)>
where
    C: ConnectionTrait,
{
    let stm = Statement::from_string(Postgres, "set local search_path to public");
    conn.execute(stm).await.unwrap();
    let mut role = format!("{}_anon", ctx.org);
    // println!("role before token check: {}", &role);
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
        } else {
            return Err((StatusCode::BAD_REQUEST, "Invalid organization token".into()));
        }
    }
    // println!("role after token check: {}", &role);
    let stm = Statement::from_string(Postgres, format!("set local role to {}", role));
    conn.execute(stm).await.unwrap();
    Ok(())
}

async fn execute_query<C>(conn: &C, q: String) -> Vec<serde_json::Value>
where
    C: ConnectionTrait,
{
    let stm = Statement::from_string(Postgres, &q);
    let out = conn.query_all(stm.clone()).await.unwrap();
    let rows = out
        .iter()
        .map(|r| JsonValue::from_query_result(r, "").unwrap())
        .collect::<Vec<_>>();
    rows
}

async fn sql(
    db: Database,
    ctx: RequestContext,
    body: String,
) -> Result<axum::Json<Vec<serde_json::Value>>, (StatusCode, String)> {
    let q = body;
    let rows = if let Some(db_session) = ctx.db_session {
        let txn = DatabaseSessions::instance().get(&db_session).await.unwrap();
        switch_auth_context(txn.as_ref(), ctx).await.unwrap();
        let rows = execute_query(txn.as_ref(), q).await;
        rows
    } else {
        let txn = db.begin().await.unwrap();
        switch_auth_context(&txn, ctx).await.unwrap();
        let rows = execute_query(&txn, q).await;
        txn.commit().await.unwrap();
        rows
    };
    Ok(axum::Json(rows))
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
    switch_auth_context(&txn, ctx).await?;

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

async fn start_db_transaction(
    db: Database,
    ctx: RequestContext,
) -> Result<String, (StatusCode, String)> {
    let (x, txn) = DatabaseSessions::instance().add(&db).await;
    //switch_auth_context(txn.0.as_ref(), ctx).await;
    println!("{}", Arc::strong_count(&txn));
    Ok(x.to_string())
}

async fn commit_db_transaction(
    db: Database,
    ctx: RequestContext,
) -> Result<String, (StatusCode, String)> {
    if let Some(db_session) = ctx.db_session {
        if let Some(x) = DatabaseSessions::instance().take(&db_session).await {
            if let Some(x) = Arc::into_inner(x) {
                x.commit().await.unwrap();
                println!("Commited");
            }
        }
    }
    Ok("Commit".to_string())
}

async fn graphiql() -> impl IntoResponse {
    Html(GraphiQLSource::build().endpoint("/graphql").finish())
}

#[tokio::main]
async fn main() {
    let db_url = "postgresql://postgres:postgres@127.0.0.1:5432/postgres";
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
    DatabaseSessions::initialize();

    let forever = task::spawn(async {
        let mut interval = time::interval(Duration::from_secs(5));

        loop {
            interval.tick().await;
            let items = DatabaseSessions::instance().keys.read().await.clone();

            for key in items {
                if let Some(x) = DatabaseSessions::instance().take(&key).await {
                    println!("captured");
                    if let Some(x) = Arc::into_inner(x) {
                        println!("force rollback");
                        x.rollback().await.unwrap();
                    }
                }
            }
        }
    });
    let mut orgs: Vec<String> = vec![];
    let conn = DbConnection::default();
    for db in out {
        let db_name = db.get("datname").unwrap().as_str().unwrap();
        let db_url = format!("postgresql://postgres:postgres@127.0.0.1:5432/{db_name}");
        let db = sea_orm::Database::connect(db_url)
            .await
            .expect("Database connection failed");
        orgs.push(db_name.to_string());
        conn.add(db_name, db);
    }
    println!("\nConnected organizations:\n[ {} ]\n", orgs.join(", "));

    let app_state = AppState { db: conn };

    let app = Router::new()
        .route("/org-init", post(organization::organization_init))
        .route("/graphql", get(graphiql).post(gql))
        .route("/sql", post(sql))
        .route("/start-db-transaction", get(start_db_transaction))
        .route("/commit-db-transaction", get(commit_db_transaction))
        .layer(CorsLayer::permissive())
        .with_state(app_state);

    println!("\nGraphiQL IDE: http://localhost:8000\n");

    axum::serve(TcpListener::bind("0.0.0.0:8000").await.unwrap(), app)
        .await
        .unwrap();
}
