use axum::{extract::State, http::StatusCode};

use crate::app_settings::AppSettings;
use crate::AppState;
use tenant::init::{init_organization, Organization};

pub async fn organization_init(
    State(state): State<AppState>,
    axum::Json(input): axum::Json<Organization>,
) -> Result<axum::Json<serde_json::Value>, (StatusCode, String)> {
    let org_name = input.name.clone();
    let env_vars = &state.env_vars.clone();
    let app_settings = env_vars.app_settings.to_string().unwrap();
    let db = init_organization(&env_vars.db_url, &app_settings, input, "./scripts")
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    state.db.add(&org_name, db).await;
    println!("\nConnection added to pool\n");
    let res = serde_json::json!({
        "msg": "Organization init successful.",
    });
    Ok(res.into())
}
