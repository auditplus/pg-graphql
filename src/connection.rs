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
