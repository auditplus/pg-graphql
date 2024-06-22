use crate::common::sql_prepared;
use sea_orm::{ConnectionTrait, TransactionTrait};

mod common;

#[tokio::test]
async fn test_connect() {
    let db = common::setup().await;
    let txn = db.begin().await.unwrap();
    common::login(&txn, "admin".to_string(), "1".to_string()).await;
    let stmt = sql_prepared("select * from account", []);
    let res = txn.query_all(stmt).await.unwrap();
    assert_eq!(17, res.len());
}
