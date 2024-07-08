use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SQLArrayType {
    Bool,
    Float,
    Int,
    String,
}

impl From<SQLArrayType> for sea_orm::sea_query::ArrayType {
    fn from(value: SQLArrayType) -> Self {
        match value {
            SQLArrayType::Bool => sea_orm::sea_query::ArrayType::Bool,
            SQLArrayType::Float => sea_orm::sea_query::ArrayType::Float,
            SQLArrayType::Int => sea_orm::sea_query::ArrayType::Int,
            SQLArrayType::String => sea_orm::sea_query::ArrayType::String,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "t", content = "v")]
pub enum SQLValue {
    Bool(Option<bool>),
    //TinyInt(Option<i8>),
    // SmallInt(Option<i16>),
    Int(Option<i32>),
    // BigInt(Option<i64>),
    //TinyUnsigned(Option<u8>),
    //SmallUnsigned(Option<u16>),
    //Unsigned(Option<u32>),
    //BigUnsigned(Option<u64>),
    Float(Option<f32>),
    Double(Option<f64>),
    String(Option<Box<String>>),
    //Char(Option<char>),
    //Bytes(Option<Box<Vec<u8>>>),
    Json(Option<Box<sea_orm::query::JsonValue>>),
    ChronoDate(Option<Box<NaiveDate>>),
    //ChronoTime(Option<Box<NaiveTime>>),
    //ChronoDateTime(Option<Box<NaiveDateTime>>),
    //ChronoDateTimeUtc(Option<Box<DateTime<Utc>>>),
    //ChronoDateTimeLocal(Option<Box<DateTime<Local>>>),
    //ChronoDateTimeWithTimeZone(Option<Box<DateTime<FixedOffset>>>),
    //TimeDate(Option<Box<Date>>),
    //TimeTime(Option<Box<Time>>),
    //TimeDateTime(Option<Box<PrimitiveDateTime>>),
    //TimeDateTimeWithTimeZone(Option<Box<OffsetDateTime>>),
    Uuid(Option<Box<uuid::Uuid>>),
    //Decimal(Option<Box<Decimal>>),
    //BigDecimal(Option<Box<BigDecimal>>),
    Array(SQLArrayType, Option<Box<Vec<SQLValue>>>),
}

impl From<SQLValue> for sea_orm::Value {
    fn from(value: SQLValue) -> Self {
        match value {
            SQLValue::Bool(v) => sea_orm::Value::Bool(v),
            SQLValue::Float(v) => sea_orm::Value::Float(v),
            SQLValue::Double(v) => sea_orm::Value::Double(v),
            SQLValue::String(v) => sea_orm::Value::String(v),
            SQLValue::Json(v) => sea_orm::Value::Json(v),
            SQLValue::Int(v) => sea_orm::Value::Int(v),
            SQLValue::Uuid(v) => sea_orm::Value::Uuid(v),
            SQLValue::ChronoDate(v) => sea_orm::Value::ChronoDate(v),
            SQLValue::Array(t, v) => {
                let o = v.map(|x| Box::new(x.into_iter().map(|y| y.into()).collect()));
                sea_orm::Value::Array(t.into(), o)
            }
        }
    }
}

impl From<i32> for SQLValue {
    fn from(value: i32) -> Self {
        Self::Int(Some(value))
    }
}

impl From<Option<i32>> for SQLValue {
    fn from(value: Option<i32>) -> Self {
        Self::Int(value)
    }
}

impl From<&str> for SQLValue {
    fn from(value: &str) -> Self {
        Self::String(Some(Box::new(value.to_string())))
    }
}

impl From<Option<&str>> for SQLValue {
    fn from(value: Option<&str>) -> Self {
        Self::String(value.map(|x| Box::new(x.to_string())))
    }
}
