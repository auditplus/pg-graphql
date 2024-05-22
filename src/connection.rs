use crate::AppState;
use async_trait::async_trait;
use axum::extract::{FromRef, FromRequestParts};
use axum::http::request::Parts;
use axum::http::HeaderMap;
use axum::response::Response;
use sea_orm::DatabaseConnection;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

pub struct Database(pub DatabaseConnection);

impl Database {
    pub fn new(conn: DatabaseConnection) -> Self {
        Self(conn)
    }
}

impl std::ops::Deref for Database {
    type Target = DatabaseConnection;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[derive(Clone)]
pub struct DbConnection {
    pools: Arc<Mutex<HashMap<String, DatabaseConnection>>>,
}

impl DbConnection {
    pub fn new() -> Self {
        DbConnection {
            pools: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn add(&self, name: &str, pool: DatabaseConnection) {
        self.pools.lock().unwrap().insert(name.to_string(), pool);
    }

    pub fn get(&self, db_name: &str) -> DatabaseConnection {
        self.pools.lock().unwrap().get(db_name).unwrap().clone()
    }
}

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
        //let org = headers.get("x-org").unwrap().to_str().unwrap();
        let org = "testorg2";
        let conn = state.db.get(org);
        Ok(Database::new(conn))
    }
}
