use crate::context::RequestContext;
use crate::server::switch_auth_context;
use crate::AppState;
use axum::extract::Path;
use axum::{extract::State, http::StatusCode};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, DbErr, FromQueryResult, JsonValue, Statement, TransactionTrait};
use serde::{Deserialize, Serialize};
use tenant::SQLValue;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueryParams {
    pub query: String,
    #[serde(default)]
    pub variables: Vec<SQLValue>,
}

pub async fn execute(
    State(state): State<AppState>,
    ctx: RequestContext,
    Path((organization, output_type)): Path<(String, String)>,
    axum::Json(q): axum::Json<QueryParams>,
) -> Result<axum::Json<Option<serde_json::Value>>, (StatusCode, String)> {
    let db = state
        .db
        .get(&organization)
        .await
        .ok_or((StatusCode::NOT_FOUND, "Organization not found".to_string()))?;

    let out = db
        .transaction::<_, Option<serde_json::Value>, DbErr>(|txn| {
            let env_vars = state.env_vars;
            let fut = async move {
                switch_auth_context(txn, ctx, &organization, &env_vars)
                    .await
                    .unwrap();
                let vals: Vec<sea_orm::Value> =
                    q.variables.into_iter().map(sea_orm::Value::from).collect();
                let stm = Statement::from_sql_and_values(Postgres, q.query, vals);
                let out = match output_type.as_str() {
                    "one" => txn
                        .query_one(stm)
                        .await?
                        .and_then(|r| JsonValue::from_query_result(&r, "").ok()),
                    _ => Some(serde_json::Value::Array(
                        txn.query_all(stm)
                            .await?
                            .into_iter()
                            .filter_map(|r| JsonValue::from_query_result(&r, "").ok())
                            .collect::<Vec<serde_json::Value>>(),
                    )),
                };
                Ok(out)
            };
            Box::pin(fut)
        })
        .await
        .unwrap();
    Ok(axum::Json(out))
}
