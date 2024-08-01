use sea_orm::{ConnectionTrait, JsonValue, Statement};
use sea_orm::{DatabaseBackend::Postgres, FromQueryResult};
use tenant::failure::Failure;

pub async fn authenticate<C>(
    conn: &C,
    org: &str,
    token: &str,
) -> anyhow::Result<serde_json::Value, Failure>
where
    C: ConnectionTrait,
{
    let stm = Statement::from_string(Postgres, format!("select authenticate('{}')", token));
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
    let stm = Statement::from_string(Postgres, stm);
    let out = JsonValue::find_by_statement(stm)
        .one(conn)
        .await?
        .ok_or(Failure::INTERNAL_ERROR)?
        .get("login")
        .cloned()
        .ok_or(Failure::INTERNAL_ERROR)?;
    Ok(out)
}
