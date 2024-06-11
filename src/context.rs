use crate::AppState;
use async_trait::async_trait;
use axum::extract::{FromRef, FromRequestParts};
use axum::http::request::Parts;
use axum::http::HeaderMap;
use axum::response::{IntoResponse, Response};

#[derive(Debug, Clone)]
pub struct RequestContext {
    pub org: String,
    pub token: Option<String>,
    pub db_session: Option<uuid::Uuid>,
}

#[async_trait]
impl<S> FromRequestParts<S> for RequestContext
where
    AppState: FromRef<S>,
    S: Send + Sync,
{
    type Rejection = Response;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let headers = HeaderMap::from_request_parts(parts, state)
            .await
            .map_err(|err| match err {})?;
        let org = headers.get("x-organization").unwrap().to_str().unwrap();
        let state = AppState::from_ref(state);
        let orgs = state.db.list();
        if !orgs.contains(&org.to_string()) {
            return Err("Invalid organization".into_response());
        }
        let token = headers.get("x-auth").and_then(|x| x.to_str().ok());
        let db_session = headers.get("x-db-session").and_then(|x| x.to_str().ok());

        let ctx = RequestContext {
            org: org.to_string(),
            token: token.map(|x| x.to_string()),
            db_session: db_session.map(|x| uuid::Uuid::try_parse(x).ok()).flatten(),
        };
        Ok(ctx)
    }
}
