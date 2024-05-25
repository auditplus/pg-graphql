use crate::connection::Database;
use crate::AppState;
use async_trait::async_trait;
use axum::extract::{FromRef, FromRequestParts};
use axum::http::request::Parts;
use axum::http::HeaderMap;
use axum::response::Response;

pub struct MemberContext {
    id: usize,
}

pub struct RequestContext {
    pub org: String,
    pub token: Option<String>,
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
        let org = headers.get("x-org").unwrap().to_str().unwrap();
        let token = headers.get("x-auth").and_then(|x| x.to_str().ok());

        let ctx = RequestContext {
            org: org.to_string(),
            token: token.map(|x| x.to_string()),
        };
        Ok(ctx)
    }
}
