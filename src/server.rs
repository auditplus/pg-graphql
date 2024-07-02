use crate::context::RequestContext;
use crate::env::EnvVars;
use crate::shutdown;
use crate::AppSettings;
use crate::{graphql, organization, rpc, sql, AppState};
use axum::http::StatusCode;
use axum::routing::{get, post};
use axum::Router;
use axum_server::Handle;
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, FromQueryResult, JsonValue, Statement};
use std::net::SocketAddr;
use std::time::Duration;
use tokio_util::sync::CancellationToken;
use tower::ServiceBuilder;
use tower_http::cors::CorsLayer;

pub async fn switch_auth_context<C>(
    conn: &C,
    ctx: RequestContext,
    org: &String,
    env_vars: &EnvVars,
) -> Result<(), (StatusCode, String)>
where
    C: ConnectionTrait,
{
    let sql = "select set_config('app.env', $1, true);";
    let app_settings = AppSettings::from(env_vars.clone())
        .to_string()
        .map_err(|e| (StatusCode::BAD_REQUEST, e.to_string()))?;
    let stm = Statement::from_sql_and_values(Postgres, sql, [app_settings.into()]);
    conn.execute(stm).await.unwrap();

    if let Some(token) = &ctx.token {
        let stm = Statement::from_string(Postgres, format!("select authenticate('{}')", token));
        let out = JsonValue::find_by_statement(stm)
            .one(conn)
            .await
            .unwrap()
            .unwrap();
        let out = out.get("authenticate").cloned().unwrap();
        let stm = Statement::from_string(
            Postgres,
            format!("select set_config('my.claims', '{}', true);", out),
        );
        let _ = conn.execute(stm).await.unwrap();
        if org == out["org"].as_str().unwrap_or_default() {
            let role = format!("{}_{}", &org, out["name"].as_str().unwrap());
            let stm = Statement::from_string(Postgres, format!("set local role to {}", role));
            conn.execute(stm).await.unwrap();
        } else {
            return Err((StatusCode::BAD_REQUEST, "Invalid organization token".into()));
        }
    } else {
        let role = format!("{}_anon", org);
        let stm = Statement::from_string(Postgres, format!("set local role to {}", role));
        conn.execute(stm).await.unwrap();
    }
    Ok(())
}

pub fn router<S>(app_state: AppState) -> Router<S>
where
    S: Clone + Send + Sync + 'static,
{
    Router::new()
        .route("/org-init", post(organization::organization_init))
        .route("/:organization/graphql", post(graphql::execute))
        .route("/:organization/rpc", get(rpc::get_handler))
        .route("/:organization/rpc", post(rpc::post_handler))
        .route("/sql/:output_type", post(sql::execute))
        .with_state(app_state)
}

pub async fn serve(app_state: AppState) {
    let ct = CancellationToken::new();
    // Build the middleware to our service.
    let service = ServiceBuilder::new();
    //.set_x_request_id(MakeRequestUuid)
    //.propagate_x_request_id();
    //let allow_header = [
    //    http::header::ACCEPT,
    //    http::header::AUTHORIZATION,
    //    http::header::CONTENT_TYPE,
    //    http::header::ORIGIN,
    //];

    let service = service.layer(CorsLayer::permissive().max_age(Duration::from_secs(86400)));

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
