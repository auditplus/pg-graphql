mod session;

use crate::connection::Database;
use crate::context::RequestContext;
use axum::http::StatusCode;
use std::sync::Arc;

pub use session::DatabaseSessions;

pub async fn start_transaction(
    db: Database,
    ctx: RequestContext,
) -> Result<String, (StatusCode, String)> {
    let (x, txn) = DatabaseSessions::instance().add(&db).await;
    println!("{}", Arc::strong_count(&txn));
    Ok(x.to_string())
}

pub async fn commit_transaction(
    db: Database,
    ctx: RequestContext,
) -> Result<String, (StatusCode, String)> {
    if let Some(db_session) = ctx.db_session {
        if let Some(x) = DatabaseSessions::instance().take(&db_session).await {
            if let Some(x) = Arc::into_inner(x) {
                x.commit().await.unwrap();
                println!("Commited");
            }
        }
    }
    Ok("Commit".to_string())
}
