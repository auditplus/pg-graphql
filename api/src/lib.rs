use crate::opt::{Param, WaitFor};
use crate::ws::{router, MAX_FRAME_SIZE, MAX_MESSAGE_SIZE, MAX_WRITE_BUFFER_SIZE, NAGLE_ALG};
use anyhow::Result;
use flume::Sender;
use futures::Stream;
use serde::de::DeserializeOwned;
use std::borrow::Cow;
use std::marker::PhantomData;
use std::pin::Pin;
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::{Arc, OnceLock};
use std::task::{Context, Poll};
use tokio::sync::watch;
use tokio::time::{Instant, Interval};
use tokio_tungstenite::tungstenite::protocol::WebSocketConfig;

mod method;
mod opt;
mod ws;

use crate::method::{Authenticate, Login, Query};
pub use method::Method;
use tenant::rpc::{DbResponse, QueryResult, Request, RequestData, Response};
use tenant::QueryParams;

type Waiter = (
    watch::Sender<Option<WaitFor>>,
    watch::Receiver<Option<WaitFor>>,
);

#[derive(Debug)]
pub(crate) struct Route {
    pub(crate) request: Request,
    pub(crate) param: Param,
    pub(crate) response: Sender<QueryResult>,
}

/// Message router
#[derive(Debug)]
pub struct Router {
    pub(crate) sender: Sender<Option<Route>>,
    pub(crate) last_id: AtomicI64,
}

impl Router {
    pub(crate) fn next_id(&self) -> i64 {
        self.last_id.fetch_add(1, Ordering::SeqCst)
    }
}

impl Drop for Router {
    fn drop(&mut self) {
        let _res = self.sender.send(None);
    }
}

#[derive(Debug, Clone)]
pub struct TenantDB {
    router: Arc<OnceLock<Router>>,
    waiter: Arc<Waiter>,
    address: String,
    capacity: usize,
}

impl TenantDB {
    pub async fn new(address: impl Into<String>) -> Result<Self> {
        let address = address.into();
        let maybe_connector = None;
        let capacity = 0;
        let waiter = Arc::new(watch::channel(None));
        let config = WebSocketConfig {
            max_message_size: Some(MAX_MESSAGE_SIZE),
            max_frame_size: Some(MAX_FRAME_SIZE),
            max_write_buffer_size: MAX_WRITE_BUFFER_SIZE,
            ..Default::default()
        };

        let (socket, _) =
            tokio_tungstenite::connect_async_with_config(&address, Some(config), NAGLE_ALG).await?;

        let (route_tx, route_rx) = match capacity {
            0 => flume::unbounded(),
            capacity => flume::bounded(capacity),
        };

        router(
            address.clone(),
            maybe_connector,
            capacity,
            config,
            socket,
            route_rx,
        );

        waiter.0.send(Some(WaitFor::Connection)).ok();

        let router = Arc::new(OnceLock::with_value(Router {
            sender: route_tx,
            last_id: AtomicI64::new(0),
        }));

        Ok(TenantDB {
            router,
            waiter,
            capacity,
            address,
        })
    }

    pub fn authenticate(&self, token: impl Into<String>) -> Authenticate {
        Authenticate {
            client: Cow::Borrowed(self),
            token: token.into(),
        }
    }

    pub fn login(&self, username: impl Into<String>, password: impl Into<String>) -> Login {
        Login {
            client: Cow::Borrowed(self),
            username: username.into(),
            password: password.into(),
        }
    }

    pub fn query<R>(&self, query: impl Into<String>) -> Query<R>
    where
        R: DeserializeOwned,
    {
        Query {
            client: Cow::Borrowed(self),
            params: QueryParams::new(query),
            data: PhantomData,
        }
    }
}

trait OnceLockExt {
    fn with_value(value: Router) -> OnceLock<Router> {
        let cell = OnceLock::new();
        match cell.set(value) {
            Ok(()) => cell,
            Err(_) => unreachable!("don't have exclusive access to `cell`"),
        }
    }

    fn extract(&self) -> Result<&Router>;
}

impl OnceLockExt for OnceLock<Router> {
    fn extract(&self) -> Result<&Router> {
        let router = self.get().unwrap();
        Ok(router)
    }
}

struct IntervalStream {
    inner: Interval,
}

impl IntervalStream {
    #[allow(unused)]
    fn new(interval: Interval) -> Self {
        Self { inner: interval }
    }
}

impl Stream for IntervalStream {
    type Item = Instant;

    fn poll_next(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Instant>> {
        self.inner.poll_tick(cx).map(Some)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use futures::StreamExt;
    use serde::Deserialize;
    use uuid::Uuid;

    #[derive(Debug, Deserialize)]
    struct Account {
        id: usize,
        name: String,
    }

    #[tokio::test]
    async fn test_connect() {
        let db = TenantDB::new("ws://localhost:8000/testorg/rpc")
            .await
            .unwrap();
        db.authenticate("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCIgOiAxLCAibmFtZSIgOiAiYWRtaW4iLCAiaXNfcm9vdCIgOiB0cnVlLCAicm9sZSIgOiAiYWRtaW4iLCAib3JnIiA6ICJ0ZXN0b3JnIiwgImlzdSIgOiAiMjAyNC0wNy0wNVQxMDozMDoxNC41NTAzMzIrMDA6MDAiLCAiZXhwIiA6ICIyMDI0LTA3LTA2VDEwOjMwOjE0LjU1MDMzMiswMDowMCJ9.Rf8yLVDlcbhoodb9yZpvKLsICV6N_tGDpu4Qv48MIZ0").await.unwrap();
        let res = db.login("admin", "1").await.unwrap();
        let mut s = db
            .query::<Account>("select id, name from inventory")
            .stream()
            .await
            .unwrap();
        while let Some(v) = s.next().await {
            println!("{:?}", &v);
        }
    }
}
