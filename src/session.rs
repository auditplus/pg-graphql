use crate::auth::authenticate;
use crate::AppState;
use async_trait::async_trait;
use axum::extract::{FromRef, FromRequestParts, Path};
use axum::http::request::Parts;
use axum::http::HeaderMap;
use axum::response::{IntoResponse, Response};
use sea_orm::{DatabaseConnection, DatabaseTransaction};

pub struct Session {
    pub db: DatabaseConnection,
    pub txn: Option<DatabaseTransaction>,
    pub organization: String,
    pub claims: Option<serde_json::Value>,
}

impl Session {
    pub fn new(organization: String, db: DatabaseConnection) -> Session {
        Self {
            db,
            txn: None,
            organization,
            claims: None,
        }
    }
}

#[async_trait]
impl<S> FromRequestParts<S> for Session
where
    AppState: FromRef<S>,
    S: Send + Sync,
{
    type Rejection = Response;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let (org,) = Path::<(String,)>::from_request_parts(parts, state)
            .await
            .map_err(|err| err.into_response())?
            .0;

        let db = AppState::from_ref(state).db.get(&org).await;

        let mut session = Session::new(org.clone(), db.clone());

        let headers = HeaderMap::from_request_parts(parts, state)
            .await
            .map_err(|err| match err {})?;
        if let Some(token) = headers.get("x-auth").and_then(|x| x.to_str().ok()) {
            session.claims = Some(authenticate(&db, &org, token).await.unwrap());
        }
        Ok(session)
    }
}
