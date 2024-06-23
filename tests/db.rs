use crate::common::{execute_stmt, perform_queries, sql_prepared};
use sea_orm::{ConnectionTrait, DbErr, FromQueryResult, JsonValue, TransactionTrait};
use serde_json::json;

mod common;

#[tokio::test]
async fn test_account_default() -> Result<(), DbErr> {
    let db = common::setup().await;
    let txn = db.begin().await?;
    common::login(&txn, "admin".to_string(), "1".to_string()).await;
    let sql = "select count(*) as count from account";
    let out = execute_stmt(&txn, sql).await?;
    let exp = vec![json!({
        "count": 17
    })];
    assert_eq!(exp, out);
    Ok(())
}

#[tokio::test]
async fn test_insert_division() -> Result<(), DbErr> {
    let txn = common::setup().await.begin().await?;
    common::login(&txn, "admin".to_string(), "1".to_string()).await;
    let sql = "insert into division (name) values ('supermarket') returning name";
    let out = execute_stmt(&txn, sql).await?;
    let exp = vec![json!({
        "name":  "supermarket"
    })];
    assert_eq!(exp, out);
    Ok(())
}
