use crate::connection::Database;
use sea_orm::{DatabaseTransaction, TransactionTrait};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::{OnceCell, RwLock};
use tokio::{task, time};

static DB_SESSIONS: OnceCell<DatabaseSessions> = OnceCell::const_new();

#[derive(Debug)]
pub struct DatabaseSessions {
    inner: Arc<RwLock<HashMap<uuid::Uuid, Arc<DatabaseTransaction>>>>,
    keys: Arc<RwLock<HashMap<uuid::Uuid, Instant>>>,
}

impl Default for DatabaseSessions {
    fn default() -> Self {
        Self {
            inner: Arc::new(RwLock::new(HashMap::new())),
            keys: Arc::new(RwLock::new(HashMap::new())),
        }
    }
}

impl DatabaseSessions {
    pub fn initialize() {
        DB_SESSIONS.set(DatabaseSessions::default()).unwrap();
        task::spawn(async {
            let mut interval = time::interval(Duration::from_secs(10));
            let sess = DatabaseSessions::instance();
            loop {
                interval.tick().await;
                let keys = sess
                    .keys
                    .read()
                    .await
                    .iter()
                    .filter_map(|(id, t)| (t.elapsed().as_secs() >= 30).then_some(*id))
                    .collect::<Vec<uuid::Uuid>>();
                for key in keys {
                    if let Some(x) = sess.take(&key).await.and_then(Arc::into_inner) {
                        x.rollback().await.unwrap();
                    }
                }
            }
        });
    }

    pub fn instance() -> &'static DatabaseSessions {
        DB_SESSIONS.get().unwrap()
    }

    pub async fn add(&self, db: &Database) -> (uuid::Uuid, Arc<DatabaseTransaction>) {
        let id = uuid::Uuid::new_v4();
        let txn = Arc::new(db.begin().await.unwrap());
        self.inner.write().await.insert(id, txn.clone());
        self.keys.write().await.insert(id, Instant::now());
        (id, txn)
    }

    pub async fn get(&self, key: &uuid::Uuid) -> Option<Arc<DatabaseTransaction>> {
        self.keys.write().await.insert(*key, Instant::now());
        self.inner.read().await.get(key).cloned()
    }

    pub async fn take(&self, key: &uuid::Uuid) -> Option<Arc<DatabaseTransaction>> {
        self.keys.write().await.remove(key);
        self.inner.write().await.remove(key)
    }
}
