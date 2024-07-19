use sea_orm::JsonValue;

pub fn parse_float_int(mut val: JsonValue) -> JsonValue {
    match val {
        JsonValue::Object(ref mut o) => {
            for (_, v) in o {
                if let Some(fl) = v.as_f64() {
                    if fl.fract() == 0.0 {
                        *v = serde_json::json!(fl as i64);
                    }
                }
            }
            val
        }
        _ => val,
    }
}
