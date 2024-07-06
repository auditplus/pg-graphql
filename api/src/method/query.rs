use crate::ws::WsContext;
use crate::OnceLockExt;
use crate::TenantDB;
use anyhow::Result;
use serde::de::DeserializeOwned;
use std::borrow::Cow;
use std::future::Future;
use std::future::IntoFuture;
use std::marker::PhantomData;
use std::pin::Pin;
use tenant::rpc::RequestData;
use tenant::{QueryParams, SQLValue};

/// An query future
#[derive(Debug)]
#[must_use = "futures do nothing unless you `.await` or poll them"]
pub struct Query<'r, R> {
    pub client: Cow<'r, TenantDB>,
    pub params: QueryParams,
    pub data: PhantomData<R>,
}

impl<'r, R> Query<'r, R> {
    pub fn bind(mut self, param: impl Into<SQLValue>) -> Self {
        self.params.variables.push(param.into());
        self
    }
}

impl<'r, R> IntoFuture for Query<'r, R>
where
    R: DeserializeOwned,
{
    type Output = Result<R>;
    type IntoFuture = Pin<Box<dyn Future<Output = Self::Output> + Send + Sync + 'r>>;

    fn into_future(self) -> Self::IntoFuture {
        Box::pin(async move {
            let router = self.client.router.extract()?;
            let res = WsContext::execute_query(router, RequestData::Query(self.params)).await?;
            Ok(res)
        })
    }
}
