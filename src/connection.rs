use crate::cdc;
use channel::Receiver;
use sea_orm::DatabaseConnection;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;

#[derive(Clone)]
pub struct DbConnection {
    pools: Arc<RwLock<HashMap<String, (DatabaseConnection, Receiver<cdc::Transaction>)>>>,
}

impl Default for DbConnection {
    fn default() -> Self {
        DbConnection {
            pools: Arc::new(RwLock::new(HashMap::new())),
        }
    }
}

impl DbConnection {
    pub async fn add(&self, name: &str, pool: DatabaseConnection) {
        let (tx, rx) = channel::bounded::<cdc::Transaction>(100);
        let org_name = name.to_string();
        tokio::spawn(async move { cdc::watch(org_name, tx).await });
        self.pools
            .write()
            .await
            .insert(name.to_string(), (pool, rx));
    }
    pub async fn get(&self, db_name: &str) -> (DatabaseConnection, Receiver<cdc::Transaction>) {
        self.pools.read().await.get(db_name).unwrap().clone()
    }

    pub async fn list(&self) -> Vec<String> {
        self.pools
            .read()
            .await
            .clone()
            .into_keys()
            .collect::<Vec<String>>()
    }
}
