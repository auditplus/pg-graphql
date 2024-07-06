use crate::opt::Param;
use crate::ws::WsContext;
use crate::OnceLockExt;
use crate::TenantDB;
use anyhow::Result;
use channel::Receiver;
use futures::StreamExt;
use serde::de::DeserializeOwned;
use std::borrow::Cow;
use std::future::Future;
use std::future::IntoFuture;
use std::marker::PhantomData;
use std::pin::Pin;
use std::task::{Context, Poll};
use tenant::rpc::{QueryStreamNotification, QueryStreamParams, RequestData};
use tenant::{QueryParams, SQLValue};
use uuid::Uuid;

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

    pub async fn stream(self) -> Result<QueryStream<R>> {
        let id = Uuid::new_v4();
        let router = self.client.router.extract()?;
        let params = QueryStreamParams {
            id,
            params: self.params,
        };
        let (tx, rx) = channel::unbounded::<QueryStreamNotification>();
        let param = Param::query_stream_notification_sender(id, tx);
        WsContext::execute_query::<Uuid>(router, param, RequestData::QueryStream(params)).await?;
        Ok(QueryStream {
            id,
            rx,
            phantom_data: PhantomData,
        })
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
            let param = Param::default();
            let res =
                WsContext::execute_query(router, param, RequestData::Query(self.params)).await?;
            Ok(res)
        })
    }
}

/// An query stream
#[derive(Debug)]
pub struct QueryStream<R> {
    pub id: Uuid,
    rx: Receiver<QueryStreamNotification>,
    phantom_data: PhantomData<R>,
}

impl<R> futures::Stream for QueryStream<R>
where
    R: DeserializeOwned + Unpin,
{
    type Item = R;

    fn poll_next(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Self::Item>> {
        match self.as_mut().rx.poll_next_unpin(cx) {
            Poll::Ready(Some(n)) => {
                let out = n.result.and_then(|x| serde_json::from_value::<R>(x).ok());
                Poll::Ready(out)
            }
            Poll::Ready(None) => Poll::Ready(None),
            Poll::Pending => Poll::Pending,
        }
    }
}
