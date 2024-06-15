use crate::context::RequestContext;
use crate::env::EnvVars;
use crate::{db, graphql, organization, sql, AppState};
use async_graphql::http::GraphiQLSource;
use axum::http::StatusCode;
use axum::response::{Html, IntoResponse};
use axum::routing::{get, post};
use axum::{http, Router};
use axum_server::Handle;
use connection::Connection;
use once_cell::sync::Lazy;
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, FromQueryResult, JsonValue, Statement};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;
use tower::ServiceBuilder;
use tower_http::cors::{Any, CorsLayer};
use uuid::Uuid;

type WebSocket = Arc<RwLock<Connection>>;
type WebSockets = RwLock<HashMap<Uuid, WebSocket>>;
pub static WEBSOCKETS: Lazy<WebSockets> = Lazy::new(WebSockets::default);

mod connection;
mod shutdown;

mod constants;
mod rpc;
mod session;

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

pub fn router<S>(app_state: AppState) -> Router<S>
where
    S: Clone + Send + Sync + 'static,
{
    Router::new()
        .route("/org-init", post(organization::organization_init))
        .route("/rpc", get(rpc::get_handler))
        .route("/rpc", post(rpc::post_handler))
        .route("/graphql", get(graphiql).post(graphql::execute))
        .route("/sql/all", post(sql::query_all))
        .route("/sql/one", post(sql::query_one))
        .route("/db/start-transaction", get(db::start_transaction))
        .route("/db/commit-transaction", get(db::commit_transaction))
        .layer(CorsLayer::permissive())
        .with_state(app_state)
}

pub async fn serve(app_state: AppState) {
    let ct = CancellationToken::new();
    // Build the middleware to our service.
    let service = ServiceBuilder::new();
    //.set_x_request_id(MakeRequestUuid)
    //.propagate_x_request_id();
    let allow_header = [
        http::header::ACCEPT,
        http::header::AUTHORIZATION,
        http::header::CONTENT_TYPE,
        http::header::ORIGIN,
    ];

    let service = service.layer(
        CorsLayer::new()
            .allow_methods([
                http::Method::GET,
                http::Method::PUT,
                http::Method::POST,
                http::Method::PATCH,
                http::Method::DELETE,
                http::Method::OPTIONS,
            ])
            .allow_headers(allow_header)
            // allow requests from any origin
            .allow_origin(Any)
            .max_age(Duration::from_secs(86400)),
    );

    let axum_app = Router::new()
        .route("/status", get(|| async {}))
        .merge(router(app_state.clone()));

    let axum_app = axum_app.layer(service);

    // Get a new server handler
    let handle = Handle::new();
    // Setup the graceful shutdown handler
    let _shutdown_handler = shutdown::graceful_shutdown(ct.clone(), handle.clone());

    // Spawn a task to handle notifications
    //tokio::spawn(async move { notifications(ct.clone()).await });

    // Setup the Axum server
    let addr = format!("0.0.0.0:{}", &app_state.env_vars.listen_port)
        .parse()
        .unwrap();
    let server = axum_server::bind(addr);
    // Log the server startup to the CLI
    println!("Started web server on {}", &addr);
    // Start the server and listen for connections
    server
        .handle(handle)
        .serve(axum_app.into_make_service_with_connect_info::<SocketAddr>())
        .await
        .unwrap();
    // Wait for the shutdown to finish
    //let _ = shutdown_handler.await;
    // Log the server shutdown to the CLI
    println!("Web server stopped. Bye!");
}
