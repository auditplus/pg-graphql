use crate::ws::WsContext;
use crate::OnceLockExt;
use crate::TenantDB;
use anyhow::Result;
use serde::Deserialize;
use std::borrow::Cow;
use std::future::Future;
use std::future::IntoFuture;
use std::pin::Pin;
use tenant::rpc::{LoginParams, RequestData};

#[derive(Debug, Deserialize)]
pub struct LoginClaims {
    pub id: usize,
    pub is_root: bool,
    pub name: String,
    pub org: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginResponse {
    pub claims: LoginClaims,
    token: String,
}

/// An login future
#[derive(Debug)]
#[must_use = "futures do nothing unless you `.await` or poll them"]
pub struct Login<'r> {
    pub client: Cow<'r, TenantDB>,
    pub username: String,
    pub password: String,
}

impl<'r> IntoFuture for Login<'r> {
    type Output = Result<LoginResponse>;
    type IntoFuture = Pin<Box<dyn Future<Output = Self::Output> + Send + Sync + 'r>>;

    fn into_future(self) -> Self::IntoFuture {
        Box::pin(async move {
            let router = self.client.router.extract()?;
            let params = LoginParams {
                username: self.username,
                password: self.password,
            };
            let res = WsContext::execute_query(router, RequestData::Login(params)).await?;
            Ok(res)
        })
    }
}
