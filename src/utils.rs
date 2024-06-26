use serde::{Deserialize, Serialize};

#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub enum WordCase {
    SnakeCase,
    LowerCamelCase,
}

pub fn convert_case(json: &mut serde_json::Value, word_case: WordCase) {
    match json {
        serde_json::Value::Array(a) => a.iter_mut().for_each(|a| convert_case(a, word_case)),
        serde_json::Value::Object(o) => {
            let mut replace = serde_json::Map::with_capacity(o.len());
            o.retain(|k, v| {
                convert_case(v, word_case);
                let converted = match word_case {
                    WordCase::LowerCamelCase => {
                        heck::ToLowerCamelCase::to_lower_camel_case(k.as_str())
                    }
                    WordCase::SnakeCase => heck::ToSnakeCase::to_snake_case(k.as_str()),
                };
                replace.insert(converted, std::mem::replace(v, serde_json::Value::Null));
                true
            });
            *o = replace;
        }
        _ => (),
    }
}
