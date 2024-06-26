use sea_orm::{DbErr, FromQueryResult, QueryResult, TryGetableFromJson};
use serde::{Deserialize, Serialize};
use serde_json::Map;

#[derive(Serialize, Deserialize)]
pub struct TestType {
    name: String,
}

pub struct MyJsonValue(pub serde_json::Value);

impl TryGetableFromJson for TestType {}

impl FromQueryResult for MyJsonValue {
    #[allow(unused_variables, unused_mut)]
    fn from_query_result(res: &QueryResult, pre: &str) -> Result<Self, DbErr> {
        let mut map = Map::new();
        #[allow(unused_macros)]
        macro_rules! try_get_type {
            ( $type: ty, $col: ident, $store: ident ) => {
                if let Ok(v) = res.try_get::<Option<$type>>(pre, &$col) {
                    $store.insert($col.to_owned(), json!(v));
                    continue;
                }
            };
        }
        match res.try_as_pg_row() {
            Some(row) => {
                use sea_orm::sqlx::{postgres::types::Oid, Column, Postgres, Row, Type};
                use serde_json::json;

                for column in row.columns() {
                    let col = if !column.name().starts_with(pre) {
                        continue;
                    } else {
                        column.name().replacen(pre, "", 1)
                    };
                    let col_type = column.type_info();

                    macro_rules! match_postgres_type {
                        ( $type: ty, $store: ident) => {
                            match col_type.kind() {
                                #[cfg(feature = "postgres-array")]
                                sqlx::postgres::PgTypeKind::Array(_) => {
                                    if <Vec<$type> as Type<Postgres>>::type_info().eq(col_type) {
                                        try_get_type!(Vec<$type>, col, $store);
                                    }
                                }
                                sea_orm::sqlx::postgres::PgTypeKind::Enum(variants) => {
                                    map.insert(col.to_owned(), json!(variants.as_ref()));
                                }
                                _ => {
                                    if <$type as Type<Postgres>>::type_info().eq(col_type) {
                                        try_get_type!($type, col, $store);
                                    }
                                }
                            }
                        };
                    }

                    match_postgres_type!(bool,map);
                    match_postgres_type!(i8, map);
                    match_postgres_type!(i16, map);
                    match_postgres_type!(i32);
                    match_postgres_type!(i64);
                    // match_postgres_type!(u8); // unsupported by SQLx Postgres
                    // match_postgres_type!(u16); // unsupported by SQLx Postgres
                    // Since 0.6.0, SQLx has dropped direct mapping from PostgreSQL's OID to Rust's `u32`;
                    // Instead, `u32` was wrapped by a `sqlx::Oid`.
                    if <Oid as Type<Postgres>>::type_info().eq(col_type) {
                        try_get_type!(u32, col, map)
                    }
                    // match_postgres_type!(u64); // unsupported by SQLx Postgres
                    match_postgres_type!(f32);
                    match_postgres_type!(f64);
                    #[cfg(feature = "with-chrono")]
                    match_postgres_type!(chrono::NaiveDate);
                    #[cfg(feature = "with-chrono")]
                    match_postgres_type!(chrono::NaiveTime);
                    #[cfg(feature = "with-chrono")]
                    match_postgres_type!(chrono::NaiveDateTime);
                    #[cfg(feature = "with-chrono")]
                    match_postgres_type!(chrono::DateTime<chrono::FixedOffset>);
                    #[cfg(feature = "with-time")]
                    match_postgres_type!(time::Date);
                    #[cfg(feature = "with-time")]
                    match_postgres_type!(time::Time);
                    #[cfg(feature = "with-time")]
                    match_postgres_type!(time::PrimitiveDateTime);
                    #[cfg(feature = "with-time")]
                    match_postgres_type!(time::OffsetDateTime);
                    #[cfg(feature = "with-rust_decimal")]
                    match_postgres_type!(rust_decimal::Decimal);
                    #[cfg(feature = "with-json")]
                    try_get_type!(serde_json::Value, col);
                    #[cfg(all(feature = "with-json", feature = "postgres-array"))]
                    try_get_type!(Vec<serde_json::Value>, col);
                    try_get_type!(String, col, map);
                    #[cfg(feature = "postgres-array")]
                    try_get_type!(Vec<String>, col);
                    #[cfg(feature = "with-uuid")]
                    try_get_type!(uuid::Uuid, col);
                    #[cfg(all(feature = "with-uuid", feature = "postgres-array"))]
                    try_get_type!(Vec<uuid::Uuid>, col);
                    try_get_type!(Vec<u8>, col, map);

                    match col_type.kind() {
                        sea_orm::sqlx::postgres::PgTypeKind::Composite(t) => {
                            println!("{:?}", &t);
                            //map.insert(col.to_owned(), json!(variants.as_ref()));
                        }
                        _ => {}
                    }
                }
                Ok(MyJsonValue(serde_json::Value::Object(map)))
            }
            #[allow(unreachable_patterns)]
            _ => unreachable!(),
        }
    }
}
