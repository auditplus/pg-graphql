use crate::connection::Database;
use crate::context::RequestContext;
use crate::db::DatabaseSessions;
use crate::switch_auth_context;
use crate::AppState;
use axum::{extract::State, http::StatusCode};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, FromQueryResult, JsonValue, Statement, TransactionTrait};

async fn execute_query<C>(conn: &C, q: String) -> Vec<serde_json::Value>
where
    C: ConnectionTrait,
{
    let stm = Statement::from_string(Postgres, &q);
    let out = conn.query_all(stm.clone()).await.unwrap();
    let rows = out
        .iter()
        .map(|r| JsonValue::from_query_result(r, "").unwrap())
        .collect::<Vec<_>>();
    rows
}

pub async fn execute(
    State(state): State<AppState>,
    db: Database,
    ctx: RequestContext,
    body: String,
) -> Result<axum::Json<Vec<serde_json::Value>>, (StatusCode, String)> {
    let q = body;
    let rows = if let Some(db_session) = ctx.db_session {
        let txn = DatabaseSessions::instance().get(&db_session).await.unwrap();
        switch_auth_context(txn.as_ref(), ctx, &state.env_vars)
            .await
            .unwrap();
        execute_query(txn.as_ref(), q).await
    } else {
        let txn = db.begin().await.unwrap();
        switch_auth_context(&txn, ctx, &state.env_vars)
            .await
            .unwrap();
        let rows = execute_query(&txn, q).await;
        txn.commit().await.unwrap();
        rows
    };
    Ok(axum::Json(rows))
}
