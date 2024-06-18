use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "t", content = "v")]
pub enum SQLValue {
    //Bool(Option<bool>),
    //TinyInt(Option<i8>),
    //SmallInt(Option<i16>),
    Int(Option<i32>),
    //BigInt(Option<i64>),
    //TinyUnsigned(Option<u8>),
    //SmallUnsigned(Option<u16>),
    //Unsigned(Option<u32>),
    //BigUnsigned(Option<u64>),
    //Float(Option<f32>),
    Double(Option<f64>),
    String(Option<Box<String>>),
    //Char(Option<char>),
    //Bytes(Option<Box<Vec<u8>>>),
    Json(Option<Box<sea_orm::query::JsonValue>>),
    //ChronoDate(Option<Box<NaiveDate>>),
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
    //Array(ArrayType, Option<Box<Vec<Value>>>),
}

impl From<SQLValue> for sea_orm::Value {
    fn from(value: SQLValue) -> Self {
        match value {
            SQLValue::Double(v) => sea_orm::Value::Double(v),
            SQLValue::String(v) => sea_orm::Value::String(v),
            SQLValue::Json(v) => sea_orm::Value::Json(v),
            SQLValue::Int(v) => sea_orm::Value::Int(v),
            SQLValue::Uuid(v) => sea_orm::Value::Uuid(v),
        }
    }
}
