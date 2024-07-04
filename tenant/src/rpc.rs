use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct ListenChannelResponse<T>
where
    T: Serialize + std::fmt::Debug,
{
    pub channel: &'static str,
    pub data: T,
}
