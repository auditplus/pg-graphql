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
