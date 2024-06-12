use crate::connection::Database;
use crate::context::RequestContext;
use crate::db::DatabaseSessions;
use crate::switch_auth_context;
use axum::http::StatusCode;
use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, FromQueryResult, JsonValue, Statement, TransactionTrait};

async fn execute_query<C>(conn: &C, gql: &str, vars: serde_json::Value) -> serde_json::Value
where
    C: ConnectionTrait,
{
    let q = format!(
        "select graphql.resolve($${}$$, '{}'::jsonb) as out;",
        gql, vars
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
    db: Database,
    ctx: RequestContext,
    axum::Json(payload): axum::Json<serde_json::Value>,
) -> Result<axum::Json<serde_json::Value>, (StatusCode, String)> {
    let gql = payload.get("query").unwrap().as_str().unwrap();
    let vars = payload
        .get("variables")
        .cloned()
        .unwrap_or(serde_json::Value::Object(serde_json::Map::new()));

    let out = if let Some(db_session) = ctx.db_session {
        let txn = DatabaseSessions::instance().get(&db_session).await.unwrap();
        switch_auth_context(txn.as_ref(), ctx).await.unwrap();
        let out = execute_query(txn.as_ref(), gql, vars).await;
        out
    } else {
        let txn = db.begin().await.unwrap();
        switch_auth_context(&txn, ctx).await.unwrap();
        let out = execute_query(&txn, gql, vars).await;
        txn.commit().await.unwrap();
        out
    };
    Ok(axum::Json(out))
}
