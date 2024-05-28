use regex::Regex;

lazy_static::lazy_static! {
    pub static ref ALPHA_NUMERIC: Regex = Regex::new("[^a-zA-Z\\d]").unwrap();
}

pub trait ValString {
    fn validate(&self) -> Self;
}

impl ValString for String {
    fn validate(&self) -> String {
        ALPHA_NUMERIC.replace_all(self, "").to_lowercase()
    }
}
