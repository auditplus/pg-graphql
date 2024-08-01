use regex::Regex;
use sea_orm::{
    ConnectionTrait, Database, DatabaseBackend, DatabaseConnection, DbBackend, FromQueryResult,
    JsonValue, Statement, TransactionTrait,
};
use serde::{Deserialize, Serialize};
use std::path::Path;

use tenant::{failure::Failure, sql::script::Scripts};

pub async fn authenticate<C>(
    conn: &C,
    org: &str,
    token: &str,
) -> anyhow::Result<serde_json::Value, Failure>
where
    C: ConnectionTrait,
{
    let stm = Statement::from_string(
        DbBackend::Postgres,
        format!("select authenticate('{}')", token),
    );
    let out = JsonValue::find_by_statement(stm).one(conn).await?.unwrap();
    let out = out.get("authenticate").cloned().unwrap();
    if org != out["org"].as_str().unwrap_or_default() {
        return Err(Failure::custom("Incorrect organization".to_string()));
    }
    Ok(out)
}

pub async fn login<C>(
    conn: &C,
    username: &str,
    password: &str,
) -> anyhow::Result<serde_json::Value, Failure>
where
    C: ConnectionTrait,
{
    let stm = format!("select login('{}', '{}')", username, password);
    let stm = Statement::from_string(DbBackend::Postgres, stm);
    let out = JsonValue::find_by_statement(stm)
        .one(conn)
        .await?
        .ok_or(Failure::INTERNAL_ERROR)?
        .get("login")
        .cloned()
        .ok_or(Failure::INTERNAL_ERROR)?;
    Ok(out)
}

lazy_static::lazy_static! {
    pub static ref ALPHA_NUMERIC: Regex = Regex::new("[a-zA-Z\\d]").unwrap();
}

#[derive(Serialize, Deserialize)]
pub struct Organization {
    // validate name for lowercase & chars
    pub name: String,
    pub full_name: String,
    pub country: String,
    pub book_begin: String,
    pub fp_code: u32,
    pub gst_no: Option<String>,
    pub owned_by: u32,
}

pub async fn init_organization<P>(
    conn_uri: &str,
    db_config: &str,
    organization: Organization,
    init_script_path: P,
) -> anyhow::Result<DatabaseConnection>
where
    P: AsRef<Path>,
{
    // validate organization
    ALPHA_NUMERIC
        .is_match(&organization.name)
        .then_some(())
        .ok_or(anyhow::Error::msg("Invalid organization name"))?;

    // create database
    let conn = Database::connect(conn_uri).await?;
    let stmt = Statement::from_sql_and_values(
        DatabaseBackend::Postgres,
        "select datname from pg_database where datname = $1 LIMIT 1",
        [organization.name.clone().into()],
    );
    let db = if conn.query_one(stmt).await?.is_some() {
        // connect to existing database
        let db_url = format!("{}/{}", &conn_uri, &organization.name);
        Database::connect(db_url).await?
    } else {
        // create database
        conn.execute_unprepared(&format!("CREATE DATABASE {}", &organization.name))
            .await?;
        conn.close().await?;
        println!("Database created");

        // connect to created database
        let db_url = format!("{}/{}", &conn_uri, &organization.name);
        let db = Database::connect(db_url).await?;

        let txn = db.begin().await?;

        let scripts = Scripts::from_dir(&init_script_path)?;
        for script in scripts {
            for stmt in script {
                // println!("Running: \n{:?}\n", &stmt);
                txn.execute_unprepared(&stmt).await?;
            }
        }

        // Setting application settings from environment variables
        let sql = "select set_config('app.env', $1, true);";
        let stm = Statement::from_sql_and_values(DbBackend::Postgres, sql, [db_config.into()]);
        txn.execute(stm).await.unwrap();

        // Execute create organization function
        let org_input_data = serde_json::to_value(organization).unwrap();
        let stm = Statement::from_sql_and_values(
            DbBackend::Postgres,
            "select * from create_organization($1)",
            [org_input_data.into()],
        );
        txn.execute(stm).await?;
        txn.commit().await?;
        db
    };
    Ok(db)
}
