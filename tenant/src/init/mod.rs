mod script;

use anyhow::Result;
use regex::Regex;
use sqlx_postgres::{PgPool, PgTypeInfo, Postgres};

use serde::{Deserialize, Serialize};
use sqlx::database::HasValueRef;
use sqlx::error::BoxDynError;
use sqlx::{Column, Decode, Row, Type};
use std::path::Path;

#[derive(sqlx::Type, Debug)]
#[sqlx(type_name = "color")]
#[sqlx(rename_all = "UPPERCASE")]
enum Color {
    Red,
    Green,
    Blue,
}

#[derive(sqlx::Type, Debug)]
#[sqlx(type_name = "sub_address")]
struct SubAddress {
    door: String,
}

#[derive(Debug)]
struct Address {
    street: String,
    sub: SubAddress,
}

impl<'r> Decode<'r, Postgres> for Address {
    fn decode(
        value: <Postgres as HasValueRef<'r>>::ValueRef,
    ) -> std::result::Result<Self, BoxDynError> {
        let mut decoder = sqlx::postgres::types::PgRecordDecoder::new(value)?;
        let street = decoder.try_decode::<String>()?;
        let sub = decoder.try_decode::<SubAddress>()?;
        Ok(Address { street, sub })
    }
}

impl Type<Postgres> for Address {
    fn type_info() -> <Postgres as sqlx::Database>::TypeInfo {
        PgTypeInfo::with_name("address")
    }
}

use script::Scripts;

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
    organization: Organization,
    init_script_path: P,
) -> Result<()>
where
    P: AsRef<Path>,
{
    // validate organization
    ALPHA_NUMERIC
        .is_match(&organization.name)
        .then_some(())
        .ok_or(anyhow::Error::msg("Invalid organization name"))?;

    // create database
    let pool = PgPool::connect(conn_uri).await?;
    let row = sqlx::query("select * from my_table LIMIT 1")
        .bind(organization.name)
        .fetch_one(&pool)
        .await?;
    let mut map = serde_json::Map::new();

    for (idx, col) in row.columns().iter().enumerate() {
        if let Ok(v) = row.try_get::<String, usize>(idx) {
            println!("Text: {:?}", &v);
            continue;
        }
        if let Ok(v) = row.try_get::<i32, usize>(idx) {
            println!("{:?}", &v);
            continue;
        }
        //if let Ok(v) = row.try_get::<Color, usize>(idx) {
        //    println!("{:?}", &v);
        //    continue;
        //}
        if let Ok(v) = row.try_get::<Address, usize>(idx) {
            println!("{:?}", &v);
            continue;
        }
    }

    //let db = if conn.query_one(stmt).await?.is_some() {
    //    // connect to existing database
    //    let db_url = format!("{}/{}", &conn_uri, &organization.name);
    //    Database::connect(db_url).await?
    //} else {
    //    // create database
    //    conn.execute_unprepared(&format!("CREATE DATABASE {}", &organization.name))
    //        .await?;
    //    conn.close().await?;
    //    println!("Database created");

    //    // connect to created database
    //    let db_url = format!("{}/{}", &conn_uri, &organization.name);
    //    let db = Database::connect(db_url).await?;

    //    let scripts = Scripts::from_dir(&init_script_path)?;
    //    for script in scripts {
    //        for stmt in script {
    //            db.execute_unprepared(&stmt).await?;
    //        }
    //    }

    //    // Execute create organization function
    //    let org_input_data = serde_json::to_value(organization).unwrap();
    //    let stm = Statement::from_sql_and_values(
    //        DbBackend::Postgres,
    //        "select * from create_organization($1)",
    //        [org_input_data.into()],
    //    );
    //    db.execute(stm).await?;
    //    db
    //};
    Ok(())
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

    let db = init_organization(
        "postgresql://postgres:postgres@localhost:5432",
        org,
        "../org_init_scripts/",
    )
    .await;
    //assert!(db.is_ok());
}
