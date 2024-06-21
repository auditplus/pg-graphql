use std::fs;

use axum::{extract::State, http::StatusCode};
use sea_orm::{ConnectionTrait, DatabaseConnection, DbBackend, Statement};
use tenant::init::{init_organization, Organization};

use crate::AppState;

pub async fn organization_init(
    State(state): State<AppState>,
    axum::Json(input): axum::Json<Organization>,
) -> Result<axum::Json<serde_json::Value>, (StatusCode, String)> {
    let org_name = input.name.clone();
    let db = init_organization(&state.env_vars.db_url, input)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    state.db.add(&org_name, db).await;
    println!("\nConnection added to pool\n");
    let res = serde_json::json!({
        "msg": "Organization init successful.",
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
