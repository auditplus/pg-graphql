mod value;

use crate::connection::Database;
use crate::context::RequestContext;
use crate::db::DatabaseSessions;
use crate::server::switch_auth_context;
use crate::sql::value::SQLValue;
use crate::AppState;
use axum::{extract::State, http::StatusCode};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, FromQueryResult, JsonValue, Statement, TransactionTrait};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueryParams {
    pub query: String,
    #[serde(default)]
    pub variables: Vec<SQLValue>,
}

pub async fn execute_query_all<C>(conn: &C, q: QueryParams) -> Vec<serde_json::Value>
where
    C: ConnectionTrait,
{
    let vals: Vec<sea_orm::Value> = q.variables.into_iter().map(sea_orm::Value::from).collect();
    let stm = Statement::from_sql_and_values(Postgres, q.query, vals);
    let out = conn.query_all(stm.clone()).await.unwrap();
    let rows = out
        .iter()
        .map(|r| JsonValue::from_query_result(r, "").unwrap())
        .collect::<Vec<_>>();
    rows
}

pub async fn execute_query_one<C>(conn: &C, q: QueryParams) -> Option<serde_json::Value>
where
    C: ConnectionTrait,
{
    let vals: Vec<sea_orm::Value> = q.variables.into_iter().map(sea_orm::Value::from).collect();
    let stm = Statement::from_sql_and_values(Postgres, q.query, vals);
    let out = conn.query_one(stm.clone()).await.unwrap();
    let row = out
        .as_ref()
        .map(|r| JsonValue::from_query_result(r, "").unwrap());
    row
}

pub async fn query_all(
    State(state): State<AppState>,
    db: Database,
    ctx: RequestContext,
    axum::Json(query_params): axum::Json<QueryParams>,
) -> Result<axum::Json<Vec<serde_json::Value>>, (StatusCode, String)> {
    let rows = if let Some(db_session) = ctx.db_session {
        let txn = DatabaseSessions::instance().get(&db_session).await.unwrap();
        switch_auth_context(txn.as_ref(), ctx, &state.env_vars)
            .await
            .unwrap();
        execute_query_all(txn.as_ref(), query_params).await
    } else {
        let txn = db.begin().await.unwrap();
        switch_auth_context(&txn, ctx, &state.env_vars)
            .await
            .unwrap();
        let rows = execute_query_all(&txn, query_params).await;
        txn.commit().await.unwrap();
        rows
    };
    Ok(axum::Json(rows))
}

pub async fn query_one(
    State(state): State<AppState>,
    db: Database,
    ctx: RequestContext,
    axum::Json(query_params): axum::Json<QueryParams>,
) -> Result<axum::Json<Option<serde_json::Value>>, (StatusCode, String)> {
    let rows = if let Some(db_session) = ctx.db_session {
        let txn = DatabaseSessions::instance().get(&db_session).await.unwrap();
        switch_auth_context(txn.as_ref(), ctx, &state.env_vars)
            .await
            .unwrap();
        execute_query_one(txn.as_ref(), query_params).await
    } else {
        let txn = db.begin().await.unwrap();
        switch_auth_context(&txn, ctx, &state.env_vars)
            .await
            .unwrap();
        let rows = execute_query_one(&txn, query_params).await;
        txn.commit().await.unwrap();
        rows
    };
    Ok(axum::Json(rows))
}