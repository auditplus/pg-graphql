use crate::connection::Database;
use crate::context::RequestContext;

pub struct Session {
    pub db: Database,
    pub organization: String,
    pub role: String,
}

impl Session {
    pub fn new(organization: String, db: Database) -> Session {
        Self {
            db,
            role: format!("{}_anon", organization),
            organization,
        }
    }
}
