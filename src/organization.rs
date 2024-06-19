use std::fs;

use axum::{extract::State, http::StatusCode, Json};
use sea_orm::{ConnectionTrait, DatabaseConnection, DbBackend, Statement};
use serde::{Deserialize, Serialize};

use crate::{utils::ValString, AppState};

#[derive(Serialize, Deserialize)]
pub struct OrgInitInput {
    pub name: String,
    pub full_name: String,
    pub country: String,
    pub book_begin: String,
    pub fp_code: u32,
    pub gst_no: Option<String>,
    pub owned_by: u32,
}

pub async fn organization_init(
    State(state): State<AppState>,
    Json(input): Json<OrgInitInput>,
) -> Result<axum::Json<serde_json::Value>, (StatusCode, String)> {
    let mut files: Vec<String> = Vec::new();
    let mut file_order: Vec<u16> = Vec::new();
    let mut file_paths: Vec<String> = Vec::new();
    match fs::read_dir("./org_init_scripts/") {
        Ok(dirs) => {
            for dir in dirs.flatten() {
                let path = dir.path().to_string_lossy().to_string();
                file_paths.push(path.clone());
                let order = (path.replace("./org_init_scripts/", "")[0..3].to_string())
                    .parse::<u16>()
                    .map_err(|_| {
                        (
                            StatusCode::INTERNAL_SERVER_ERROR,
                            "Couldnot get file order".to_owned(),
                        )
                    })?;

                file_order.push(order);
            }
        }
        Err(_) => {
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                "could not read scripts migration folder".into(),
            ));
        }
    }
    file_order.sort();
    for ord in file_order {
        let filepath = file_paths
            .iter()
            .find_map(|x| x.contains(&format!("/{:03}_", ord)).then_some(x.clone()))
            .unwrap_or_default()
            .to_string();
        if !filepath.is_empty() {
            match fs::read_to_string(&filepath) {
                Ok(file) => {
                    files.push(file);
                }
                Err(_) => {
                    return Err((
                        StatusCode::INTERNAL_SERVER_ERROR,
                        format!("could not read file {}", &filepath),
                    ));
                }
            }
        }
    }

    let conn = sea_orm::Database::connect(&state.env_vars.db_url)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Couldnot connect db".to_owned(),
            )
        })?;
    let org_name = input.name.clone().validate();
    println!("\nDatabase connected\n");

    let stmt = Statement::from_sql_and_values(
        DbBackend::Postgres,
        r#"select datname FROM pg_database WHERE datname = $1"#,
        [org_name.clone().into()],
    );
    if let Some(dup) = conn.query_one(stmt).await.unwrap() {
        let dup_org: String = dup.try_get("", "datname").unwrap();
        return Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Organization {} already exists.", dup_org),
        ));
    }
    println!("\nOrganization not found\n");

    let _ = conn
        .execute(Statement {
            sql: format!("CREATE DATABASE {}", &org_name),
            values: None,
            db_backend: DbBackend::Postgres,
        })
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Couldnot create db".to_owned(),
            )
        })?;

    println!("\nDatabase created for Organization {org_name}\n");
    conn.close().await.map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Error on disconnect main connection".to_owned(),
        )
    })?;
    let db_url = format!("{}/{org_name}", &state.env_vars.db_url);
    let db = sea_orm::Database::connect(db_url).await.map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Couldnot connect {org_name} db",),
        )
    })?;

    println!("\nDatabase {org_name} connected\n");
    let s0 = std::time::Instant::now();
    println!("\nDatabase preparation started.\n");
    for f in files {
        let stmts = f.split("--##").collect::<Vec<&str>>();
        println!("statements: {:?}", &stmts);
        for stmt in stmts {
            println!("\nRunning:\n{}\n", &stmt);
            let _ = db
                .execute(Statement {
                    sql: stmt.to_string(),
                    values: None,
                    db_backend: DbBackend::Postgres,
                })
                .await
                .map_err(|_| {
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        format!("Couldnot run script: {}", &stmt),
                    )
                })?;
            println!("\nCompleted\n");
        }
    }
    println!("\nDatabase preparation completed.\n");

    let s0 = s0.elapsed();

    let s1 = std::time::Instant::now();
    let org_input_data = serde_json::to_value(input).unwrap();
    let stmt = format!(
        "select * from create_organization('{}'::jsonb);",
        org_input_data
    );
    println!("Create Organization: {}", &stmt);
    let _ = db
        .execute(Statement {
            sql: stmt.to_string(),
            values: None,
            db_backend: DbBackend::Postgres,
        })
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Could not create organization".to_owned(),
            )
        })?;

    println!("\n Organization Created\n");
    let s1 = s1.elapsed();

    // let s2 = std::time::Instant::now();
    // restore_data(&db, &org_name).await?;
    // let s2 = s2.elapsed();

    state.db.add(&org_name, db).await;
    println!("\nConnection added to pool\n");

    let res = serde_json::json!({
        "msg": "Organization init successful.",
        "duration": {
            "init": s0,
            "org_create": s1
            // "restore_data": s3
        }
    });

    Ok(res.into())
}

async fn _restore_data(
    db: &DatabaseConnection,
    org_name: &String,
) -> Result<bool, (StatusCode, String)> {
    let mut files: Vec<String> = Vec::new();
    let mut file_order: Vec<u16> = Vec::new();
    let mut file_paths: Vec<String> = Vec::new();
    println!("Restore Data For Organization {org_name}");
    match fs::read_dir("./org_data/") {
        Ok(dirs) => {
            for dir in dirs.flatten() {
                let path = dir.path().to_string_lossy().to_string();
                file_paths.push(path.clone());
                let order = (path.replace("./org_data/", "")[0..3].to_string())
                    .parse::<u16>()
                    .map_err(|_| {
                        (
                            StatusCode::INTERNAL_SERVER_ERROR,
                            "Couldnot get file order".to_owned(),
                        )
                    })?;

                file_order.push(order);
            }
        }
        Err(_) => {
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                "could not read backup data folder".into(),
            ));
        }
    }
    file_order.sort();
    for ord in file_order {
        let filepath = file_paths
            .iter()
            .find_map(|x| x.contains(&format!("/{:03}_", ord)).then_some(x.clone()))
            .unwrap_or_default()
            .to_string();
        if !filepath.is_empty() {
            match fs::read_to_string(&filepath) {
                Ok(file) => {
                    files.push(file);
                }
                Err(_) => {
                    return Err((
                        StatusCode::INTERNAL_SERVER_ERROR,
                        format!("could not read file {}", &filepath),
                    ));
                }
            }
        }
    }

    println!("\nSecuring db started.\n");
    for f in files {
        let stmts = f.split("--##").collect::<Vec<&str>>();
        println!("statements: {:?}", &stmts);
        for stmt in stmts {
            println!("\nRunning:\n{}\n", &stmt);
            let _ = db
                .execute(Statement {
                    sql: stmt.to_string(),
                    values: None,
                    db_backend: DbBackend::Postgres,
                })
                .await
                .map_err(|_| {
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        format!("Couldnot run script: {}", &stmt),
                    )
                })?;
            println!("\nCompleted\n");
        }
    }
    println!("\ndata restore completed.\n");

    Ok(true)
}
