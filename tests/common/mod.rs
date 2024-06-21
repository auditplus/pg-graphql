use sea_orm::DatabaseBackend::Postgres;
use sea_orm::{ConnectionTrait, Database, DatabaseConnection, JsonValue, Statement};
use std::sync::Arc;
use tokio::sync::RwLock;

pub async fn setup() {
    //let conn = Database::connect("postgresql://postgres:postgres@localhost:5432/postgres")
    //    .await
    //    .expect("Database connection failed");
    //let db = conn
    //    .execute_unprepared("drop if exists database")
    //    .await
    //    .unwrap();
}

//async fn login(db: &DatabaseConnection) -> anyhow::Result<Data, Failure> {
//    let txn = rpc.read().await.session.db.begin().await?;
//    let stm = format!(
//        "select set_config('app.env.jwt_secret_key', '{}', true);",
//        &rpc.read().await.env_vars.jwt_private_key
//    );
//    let stm = Statement::from_string(Postgres, stm);
//    txn.execute(stm).await?;
//    let stm = format!("select login('{}', '{}')", params.username, params.password);
//    let stm = Statement::from_string(Postgres, stm);
//    let out = JsonValue::find_by_statement(stm)
//        .one(&txn)
//        .await?
//        .ok_or(Failure::INTERNAL_ERROR)?
//        .get("login")
//        .cloned()
//        .ok_or(Failure::INTERNAL_ERROR)?;
//    let claims = out.get("claims").cloned().ok_or(Failure::INTERNAL_ERROR)?;
//    let _ = rpc.write().await.session.claims.insert(claims);
//    txn.commit().await.unwrap();
//    Ok(Data::One(Some(out)))
//}
