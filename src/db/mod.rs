mod session;
use crate::connection::Database;
use crate::context::RequestContext;
use axum::http::StatusCode;
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, FromQueryResult, JsonValue, Statement, TransactionTrait};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

pub use session::DatabaseSessions;

async fn transaction_auth(db: &Database, ctx: RequestContext) -> bool {
    let token = &ctx.token.unwrap();
    let conn = db.begin().await.unwrap();
    let role = format!("{}_anon", ctx.org);
    let stm = Statement::from_string(Postgres, format!("set local role to {}", role));
    conn.execute(stm).await.unwrap();
    let stm = Statement::from_string(Postgres, format!("select authenticate('{}')", token));
    let out = JsonValue::find_by_statement(stm)
        .one(&conn)
        .await
        .unwrap()
        .unwrap();
    let out = out.get("authenticate").cloned().unwrap();
    if ctx.org != out["org"].as_str().unwrap_or_default() {
        return false;
    }
    true
}

pub async fn start_transaction(
    db: Database,
    ctx: RequestContext,
) -> Result<String, (StatusCode, String)> {
    transaction_auth(&db, ctx)
        .await
        .then_some(())
        .ok_or((StatusCode::BAD_REQUEST, "Invalid organization token".into()))?;
    let (x, _) = DatabaseSessions::instance().add(&db).await;
    Ok(x.to_string())
}

pub async fn commit_transaction(
    db: Database,
    ctx: RequestContext,
) -> Result<String, (StatusCode, String)> {
    transaction_auth(&db, ctx.clone())
        .await
        .then_some(())
        .ok_or((StatusCode::BAD_REQUEST, "Invalid organization token".into()))?;

    if let Some(db_session) = ctx.db_session {
        if let Some(x) = DatabaseSessions::instance()
            .take(&db_session)
            .await
            .and_then(Arc::into_inner)
        {
            x.commit().await.unwrap();
        }
    }
    Ok("Commited".to_string())
}
