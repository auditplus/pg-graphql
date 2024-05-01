use crate::connection::Database;
use crate::AppState;
use async_trait::async_trait;
use axum::extract::{FromRef, FromRequestParts};
use axum::http::request::Parts;
use axum::http::HeaderMap;
use axum::response::Response;

#[async_trait]
impl<S> FromRequestParts<S> for Database
where
    AppState: FromRef<S>,
    S: Send + Sync,
{
    type Rejection = Response;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let headers = HeaderMap::from_request_parts(parts, state)
            .await
            .map_err(|err| match err {})?;
        let state = AppState::from_ref(state);
        let conn = state.db.get("testorg");
        //let conn = db.get().await.unwrap();
        //let q = format!("SET ROLE {}", "anon");
        //conn.execute(&q, &[]).await.unwrap();
        Ok(Database::new(conn))
    }
}
