use crate::connection::Database;
use crate::context::RequestContext;
use crate::server::switch_auth_context;
use crate::AppState;
use axum::{extract::State, http::StatusCode};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{FromQueryResult, JsonValue, Statement, TransactionTrait};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct QueryParams {
    query: String,
    #[serde(default)]
    variables: serde_json::Value,
}

pub async fn execute(
    State(state): State<AppState>,
    db: Database,
    ctx: RequestContext,
    axum::Json(payload): axum::Json<QueryParams>,
) -> Result<axum::Json<serde_json::Value>, (StatusCode, String)> {
    let txn = db.begin().await.unwrap();
    switch_auth_context(&txn, ctx, &state.env_vars)
        .await
        .unwrap();
    let q = format!(
        "select graphql.resolve($${}$$, '{}'::jsonb) as out;",
        payload.query, payload.variables
    );
    let stm = Statement::from_string(Postgres, &q);
    let out = JsonValue::find_by_statement(stm)
        .one(&txn)
        .await
        .unwrap()
        .unwrap();
    out.get("out").cloned().unwrap();
    txn.commit().await.unwrap();
    Ok(axum::Json(out))
}
