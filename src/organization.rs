use std::{fs, str::FromStr};

use axum::{extract::State, http::StatusCode, Json};
use chrono::{Datelike, Duration, NaiveDate};
use sea_orm::{ConnectionTrait, DatabaseConnection, DbBackend, Statement, Values};
use serde::Deserialize;

use crate::{utils::ValString, AppState};

#[derive(Deserialize)]
pub struct OrgInitInput {
    pub name: String,
    pub full_name: String,
    pub country: String,
    pub book_begin: String,
    pub fp_code: u32,
    pub gst_no: Option<String>,
    pub owned_by: String,
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

    let db_url = "postgresql://postgres:1@localhost:5432";
    let conn = sea_orm::Database::connect(db_url).await.map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Couldnot connect database".to_owned(),
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
                "Couldnot create database".to_owned(),
            )
        })?;

    println!("\nDatabase created for Organization {org_name}\n");
    conn.close().await.map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Error on disconnect main connection".to_owned(),
        )
    })?;
    let db_url = format!("postgresql://postgres:1@localhost:5432/{org_name}");
    let db = sea_orm::Database::connect(db_url).await.map_err(|_| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Couldnot connect {org_name} database",),
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

    // Add FinancialYear
    println!("\nAdd FinancialYear Start\n");
    let fy_start = NaiveDate::from_str(&input.book_begin).unwrap();
    let fp_code = input.fp_code;
    let year: u32 = fy_start.year() as u32;
    let mon: u32 = fy_start.month();
    let year = if mon < fp_code - 1 { year - 1 } else { year };
    let end_date = NaiveDate::from_ymd_opt(year as i32 + 1, fp_code, 1)
        .unwrap()
        .and_hms_opt(0, 0, 0)
        .unwrap()
        .date();
    let fy_end = end_date + Duration::days(-1);
    let stmt = format!(
        "INSERT INTO financial_year(fy_start, fy_end) values('{}','{}');",
        fy_start, fy_end
    );
    println!("Fyear: {}", &stmt);
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
                "Couldnot add financial year".to_owned(),
            )
        })?;

    println!("\nFinancialYear Added\n");

    let stmt = 
        "INSERT INTO organization(name, full_name, country, book_begin,gst_no,fp_code, status, owned_by)
        values($1,$2,$3,$4,$5,$6,'ACTIVE',$7);";
    println!("Organization: {}", &stmt);
    let _ = db
        .execute(Statement {
            sql: stmt.to_string(),
            values: Values(vec![input.name.into(), input.full_name.into(), input.country.into(), fy_start.to_owned().into(),
            input.gst_no.to_owned().unwrap_or_default().into(), input.fp_code.into(), input.owned_by.clone().into()]).into(),
            db_backend: DbBackend::Postgres,
        })
        .await
        .unwrap();
    println!("\nOrganization info added\n");

    let stmt = format!(
        "INSERT INTO member(name, pass, remote_access, is_root, role_id, user_id, nick_name)
        values('admin','1',true,true,1,'{}','Administrator');",
        &input.owned_by
    );
    println!("Member: {}", &stmt);
    let _ = db
        .execute(Statement {
            sql: stmt.to_string(),
            values: None,
            db_backend: DbBackend::Postgres,
        })
        .await
        .unwrap();
    println!("\nAdmin added\n");
    let s0 = s0.elapsed();
    let s1 = std::time::Instant::now();
    make_secure(&db, &org_name).await?;
    let s1 = s1.elapsed();
    // let s2 = std::time::Instant::now();
    // restore_data(&db, &org_name).await?;
    // let s2 = s2.elapsed();

    state.db.add(&org_name, db);
    println!("\nConnection added to pool\n");

    let res = serde_json::json!({
        "msg": "Organization init successful.",
        "duration": {
            "init": s0,
            "make_secure": s1
            // "restore_data": s2
        }
    });

    Ok(res.into())
}

async fn make_secure(
    db: &DatabaseConnection,
    org_name: &String,
) -> Result<bool, (StatusCode, String)> {
    let mut files: Vec<String> = Vec::new();
    let mut file_order: Vec<u16> = Vec::new();
    let mut file_paths: Vec<String> = Vec::new();
    println!("Make Secure Organization {org_name}");
    match fs::read_dir("./org_secure_scripts/") {
        Ok(dirs) => {
            for dir in dirs.flatten() {
                let path = dir.path().to_string_lossy().to_string();
                file_paths.push(path.clone());
                let order = (path.replace("./org_secure_scripts/", "")[0..3].to_string())
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

    println!("\nSecuring database started.\n");
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
    println!("\nSecuring database completed.\n");

    Ok(true)
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

    println!("\nSecuring database started.\n");
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
