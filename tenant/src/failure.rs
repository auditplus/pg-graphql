use serde::{Deserialize, Serialize};
use std::borrow::Cow;
use std::fmt;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Failure {
    code: i64,
    message: Cow<'static, str>,
}

impl fmt::Display for Failure {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Failure")
    }
}

impl std::error::Error for Failure {}

#[cfg(not(target_arch = "wasm32"))]

impl From<sea_orm::DbErr> for Failure {
    fn from(err: sea_orm::DbErr) -> Self {
        Failure::custom(err.to_string())
    }
}

#[allow(dead_code)]
impl Failure {
    pub const METHOD_NOT_FOUND: Failure = Failure {
        code: -32601,
        message: Cow::Borrowed("Method not found"),
    };

    pub const INVALID_PARAMS: Failure = Failure {
        code: -32602,
        message: Cow::Borrowed("Invalid params"),
    };

    pub const INTERNAL_ERROR: Failure = Failure {
        code: -32603,
        message: Cow::Borrowed("Internal error"),
    };

    pub fn custom<S>(message: S) -> Failure
    where
        Cow<'static, str>: From<S>,
    {
        Failure {
            code: -32000,
            message: message.into(),
        }
    }
}
