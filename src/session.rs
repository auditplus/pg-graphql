use crate::sql::authenticate;
use crate::AppState;
use async_trait::async_trait;
use axum::extract::{FromRef, FromRequestParts, Path, Query};
use axum::http::request::Parts;
use axum::http::{HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use sea_orm::{DatabaseConnection, DatabaseTransaction};
use serde::Deserialize;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
pub enum SessionType {
    Member,
    PosServer,
}

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
    pub fn claim_type(&self) -> Option<SessionType> {
        self.claims.as_ref().and_then(|x| {
            x.get("claim_type")
                .and_then(|y| serde_json::from_value(y.clone()).ok())
        })
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

        let Some(db) = db else {
            return Err((StatusCode::NOT_FOUND, "Invalid organization".to_string()).into_response());
        };
        let mut session = Session::new(org.clone(), db.clone());

        let headers = HeaderMap::from_request_parts(parts, state)
            .await
            .map_err(|err| match err {})?;
        #[derive(Deserialize)]
        struct QueryData {
            #[serde(rename = "auth-token")]
            auth_token: Option<String>,
        }
        let query: Query<QueryData> = Query::from_request_parts(parts, state)
            .await
            .map_err(|err| (StatusCode::BAD_REQUEST, err.to_string()).into_response())?;
        let auth_token = query.auth_token.clone();
        let token = if let Some(token) = headers.get("x-auth").and_then(|x| x.to_str().ok()) {
            Some(token.to_string())
        } else {
            auth_token
        };
        if let Some(token) = token {
            if let Ok(res) = authenticate(&db, &org, &token).await {
                session.claims = Some(res);
            }
        }
        Ok(session)
    }
}
