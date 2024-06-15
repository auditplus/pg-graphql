use sea_orm::{DatabaseConnection, DatabaseTransaction};

pub struct Session {
    pub db: DatabaseConnection,
    pub txn: Option<DatabaseTransaction>,
    pub organization: String,
    pub role: String,
}

impl Session {
    pub fn new(organization: String, db: DatabaseConnection) -> Session {
        Self {
            db,
            role: format!("{}_anon", organization),
            txn: None,
            organization,
        }
    }
}
