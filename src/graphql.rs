use crate::connection::Database;
use crate::context::RequestContext;
use crate::db::DatabaseSessions;
use crate::server::switch_auth_context;
use crate::AppState;
use axum::{extract::State, http::StatusCode};
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, FromQueryResult, JsonValue, Statement, TransactionTrait};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct QueryParams {
    query: String,
    #[serde(default)]
    variables: serde_json::Value,
}

pub async fn execute_query<C>(conn: &C, params: QueryParams) -> serde_json::Value
where
    C: ConnectionTrait,
{
    let q = format!(
        "select graphql.resolve($${}$$, '{}'::jsonb) as out;",
        params.query, params.variables
    );
    let stm = Statement::from_string(Postgres, &q);
    let out = JsonValue::find_by_statement(stm)
        .one(conn)
        .await
        .unwrap()
        .unwrap();
    out.get("out").cloned().unwrap()
}

pub async fn execute(
    State(state): State<AppState>,
    db: Database,
    ctx: RequestContext,
    axum::Json(payload): axum::Json<QueryParams>,
) -> Result<axum::Json<serde_json::Value>, (StatusCode, String)> {
    let out = if let Some(db_session) = ctx.db_session {
        let txn = DatabaseSessions::instance().get(&db_session).await.unwrap();
        let stm = Statement::from_string(Postgres, "set local search_path to public");
        txn.execute(stm).await.unwrap();
        switch_auth_context(txn.as_ref(), ctx, &state.env_vars)
            .await
            .unwrap();
        execute_query(txn.as_ref(), payload).await
    } else {
        let txn = db.begin().await.unwrap();
        let stm = Statement::from_string(Postgres, "set local search_path to public");
        txn.execute(stm).await.unwrap();
        switch_auth_context(&txn, ctx, &state.env_vars)
            .await
            .unwrap();
        let out = execute_query(&txn, payload).await;
        txn.commit().await.unwrap();
        out
    };
    Ok(axum::Json(out))
}
