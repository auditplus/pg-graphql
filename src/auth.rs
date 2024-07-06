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
        panic!("Incorrect organization");
    }
    Ok(out)
}
