use crate::shutdown;
use crate::{organization, rpc, AppState};
use axum::routing::{get, post};
use axum::Router;
use axum_server::Handle;
use std::net::SocketAddr;
use std::time::Duration;
use tokio_util::sync::CancellationToken;
use tower::ServiceBuilder;
use tower_http::cors::CorsLayer;

pub fn router<S>(app_state: AppState) -> Router<S>
where
    S: Clone + Send + Sync + 'static,
{
    Router::new()
        .route("/org-init", post(organization::organization_init))
        .route("/:organization/rpc", get(rpc::get_handler))
        .route("/:organization/rpc", post(rpc::post_handler))
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
        .route("/status", get(|| async { "hello" }))
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
