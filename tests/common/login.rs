use crate::common::sql_prepared;
use sea_orm::ConnectionTrait;

pub const TEST_JWT_KEY: &str = "testsecret";

pub async fn login<C>(conn: &C, username: String, password: String)
where
    C: ConnectionTrait,
{
    let stmt = sql_prepared(
        "select set_config('app.env.jwt_secret_key', $1, true)",
        ["testsecret".into()],
    );
    conn.execute(stmt).await.unwrap();
    let stmt = sql_prepared(
        "select (out->>'claims')::json as claims from login($1, $2) as out",
        [username.into(), password.into()],
    );
    let res = conn
        .query_one(stmt)
        .await
        .unwrap()
        .unwrap()
        .try_get::<serde_json::Value>("", "claims")
        .unwrap();
    let stmt = sql_prepared(
        "select set_config('my.claims', $1, true)",
        [serde_json::to_string(&res).unwrap().into()],
    );
    conn.execute(stmt).await.unwrap();
    let org = res.get("org").unwrap().as_str().unwrap();
    let role = res.get("role").unwrap().as_str().unwrap();
    let stmt = sql_prepared(format!("set local role {}_{}", org, role), []);
    conn.execute(stmt).await.unwrap();
}
