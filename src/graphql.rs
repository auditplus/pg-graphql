use crate::context::RequestContext;
use crate::server::switch_auth_context;
use crate::AppState;
use axum::extract::Path;
use axum::{extract::State, http::StatusCode};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{FromQueryResult, JsonValue, Statement, TransactionTrait};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct QueryParams {
    query: String,
    variables: Option<serde_json::Value>,
}

pub async fn execute(
    State(state): State<AppState>,
    ctx: RequestContext,
    Path((organization,)): Path<(String,)>,
    axum::Json(payload): axum::Json<QueryParams>,
) -> Result<axum::Json<serde_json::Value>, (StatusCode, String)> {
    let db = state.db.get(&organization).await;
    let txn = db.begin().await.unwrap();
    let vars = payload
        .variables
        .unwrap_or(serde_json::Value::Object(serde_json::Map::new()));
    switch_auth_context(&txn, ctx, &organization, &state.env_vars)
        .await
        .unwrap();

    let q = format!(
        "select graphql.resolve($${}$$, '{}'::jsonb) as out;",
        payload.query, vars
    );
    let stm = Statement::from_string(Postgres, &q);
    let out = JsonValue::find_by_statement(stm)
        .one(&txn)
        .await
        .unwrap()
        .unwrap()
        .get("out")
        .cloned()
        .unwrap();
    txn.commit().await.unwrap();
    Ok(axum::Json(out))
}
