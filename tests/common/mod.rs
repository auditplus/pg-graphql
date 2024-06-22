mod login;

use sea_orm::{
    sea_query, ConnectionTrait, Database, DatabaseConnection, DbBackend, JsonValue, Statement,
};
use tenant::init::{init_organization, Organization};

pub use login::login;

pub fn sql_prepared<I, T>(sql: T, values: I) -> Statement
where
    I: IntoIterator<Item = sea_query::Value>,
    T: Into<String>,
{
    Statement::from_sql_and_values(DbBackend::Postgres, sql, values)
}

pub async fn setup() -> DatabaseConnection {
    let org = Organization {
        name: "testingorg".to_string(),
        full_name: "testingorg".to_string(),
        country: "INDIA".to_string(),
        book_begin: "2024-04-01".to_string(),
        fp_code: 4,
        gst_no: Some("33TTORG0001AAZ0".to_string()),
        owned_by: 1,
    };

    let db = init_organization(
        "postgresql://postgres:postgres@localhost:5432",
        org,
        "./org_init_scripts",
    )
    .await
    .unwrap();
    db
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
