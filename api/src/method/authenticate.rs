use crate::conn::Router;
use crate::Connection;
use crate::OnceLockExt;
use crate::TenantDB;
use anyhow::Result;
use std::borrow::Cow;
use std::future::Future;
use std::future::IntoFuture;
use std::pin::Pin;
use tenant::rpc::RequestData;

/// An authentication future
#[derive(Debug)]
#[must_use = "futures do nothing unless you `.await` or poll them"]
pub struct Authenticate<'r, C: Connection> {
    pub client: Cow<'r, TenantDB<C>>,
    pub token: String,
}

impl<'r, C> IntoFuture for Authenticate<'r, C>
where
    C: Connection,
{
    type Output = Result<()>;
    type IntoFuture = Pin<Box<dyn Future<Output = Self::Output> + Send + Sync + 'r>>;

    fn into_future(self) -> Self::IntoFuture {
        Box::pin(async move {
            let router = self.client.router.extract()?;
            let _ = Router::execute_query::<serde_json::Value>(
                router,
                RequestData::Authenticate(self.token),
            )
            .await;
            Ok(())
        })
    }
}
