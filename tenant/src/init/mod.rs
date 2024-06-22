mod script;

use anyhow::Result;
use regex::Regex;
use sea_orm::{ConnectionTrait, Database, DatabaseConnection, DbBackend, Statement};
use serde::{Deserialize, Serialize};
use std::time::Instant;

use script::Scripts;

lazy_static::lazy_static! {
    pub static ref ALPHA_NUMERIC: Regex = Regex::new("[^a-zA-Z\\d]").unwrap();
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

pub async fn init_organization(
    conn_uri: &str,
    organization: Organization,
) -> Result<DatabaseConnection> {
    // validate organization
    ALPHA_NUMERIC
        .is_match(&organization.name)
        .then_some(())
        .ok_or(anyhow::Error::msg("Invalid organization name"))?;

    // create database
    let conn = Database::connect(conn_uri).await?;
    conn.execute_unprepared(&format!("CREATE DATABASE {}", &organization.name))
        .await?;
    conn.close().await?;
    println!("Database created");

    // connect to created database
    let db_url = format!("{}/{}", &conn_uri, &organization.name);
    let db = Database::connect(db_url).await?;

    // Execute init scripts
    let s0 = Instant::now();

    let base_path = "../org_init_scripts/";
    let scripts = Scripts::from_dir(&base_path)?;
    for script in scripts {
        for stmt in script {
            db.execute_unprepared(&stmt).await?;
        }
    }

    // Execute create organization function
    let org_input_data = serde_json::to_value(organization).unwrap();
    let stm = Statement::from_sql_and_values(
        DbBackend::Postgres,
        "select * from create_organization($1)",
        [org_input_data.into()],
    );
    db.execute(stm).await?;

    println!("Elasped time: {} secs", s0.elapsed().as_secs());
    Ok(db)
}

#[tokio::test]
async fn test_init() {
    let org = Organization {
        name: "testorg4".to_string(),
        full_name: "testorg4".to_string(),
        country: "INDIA".to_string(),
        book_begin: "2024-04-01".to_string(),
        fp_code: 4,
        gst_no: Some("33TTORG0001AAZ0".to_string()),
        owned_by: 1,
    };

    let db = init_organization("postgresql://postgres:postgres@localhost:5432", org).await;
    assert_eq!(db.is_ok(), true);
}