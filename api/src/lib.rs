use crate::opt::WaitFor;
use anyhow::Result;
use channel::Sender;
use conn::{Param, Router};
use core::fmt;
use method::BoxFuture;
use opt::endpoint::Endpoint;
use std::fmt::Debug;
use std::future::IntoFuture;
use std::marker::PhantomData;
use std::sync::{Arc, OnceLock};
use tenant::failure::Failure;
use tokio::sync::watch;

mod conn;
pub mod engine;
mod method;
mod opt;

type Waiter = (
    watch::Sender<Option<WaitFor>>,
    watch::Receiver<Option<WaitFor>>,
);

pub trait Connection: conn::Connection {}

#[derive(Debug, Clone, Default)]
pub struct ConnectOptions {
    pub token: Option<String>,
    pub capacity: usize,
}

#[derive(Debug)]
#[must_use = "futures do nothing unless you `.await` or poll them"]
pub struct Connect<C: Connection, Response> {
    router: Arc<OnceLock<Router>>,
    engine: PhantomData<C>,
    address: Result<Endpoint, Failure>,
    waiter: Arc<Waiter>,
    response_type: PhantomData<Response>,
    opts: ConnectOptions,
}

impl<C, R> Connect<C, R>
where
    C: Connection,
{
    pub fn with_token(mut self, token: impl Into<String>) -> Self {
        self.opts.token = Some(token.into());
        self
    }

    pub const fn with_capacity(mut self, capacity: usize) -> Self {
        self.opts.capacity = capacity;
        self
    }
}

impl<Client> IntoFuture for Connect<Client, TenantDB<Client>>
where
    Client: Connection,
{
    type Output = Result<TenantDB<Client>, Failure>;
    type IntoFuture = BoxFuture<'static, Self::Output>;

    fn into_future(self) -> Self::IntoFuture {
        Box::pin(async move {
            let endpoint = self.address?;
            // Extract token if any
            let token = self.opts.token.clone();
            let client = Client::connect(endpoint, self.opts).await?;

            if let Some(token) = token {
                client
                    .param_tx
                    .as_ref()
                    .unwrap()
                    .try_send(Param::token(token))
                    .unwrap();
            }
            // Both ends of the channel are still alive at this point
            client.waiter.0.send(Some(WaitFor::Connection)).ok();
            Ok(client)
        })
    }
}

impl<Client> IntoFuture for Connect<Client, ()>
where
    Client: Connection,
{
    type Output = Result<(), Failure>;
    type IntoFuture = BoxFuture<'static, Self::Output>;

    fn into_future(self) -> Self::IntoFuture {
        Box::pin(async move {
            // Avoid establishing another connection if already connected
            if self.router.get().is_some() {
                return Err(Failure::custom("Already connected"));
            }
            let endpoint = self.address?;
            let client = Client::connect(endpoint, self.opts).await?;
            let cell =
                Arc::into_inner(client.router).expect("new connection to have no references");
            let router = cell.into_inner().expect("router to be set");
            self.router
                .set(router)
                .map_err(|_| Failure::custom("Already connected"))?;
            // Both ends of the channel are still alive at this point
            self.waiter.0.send(Some(WaitFor::Connection)).ok();
            Ok(())
        })
    }
}

pub struct TenantDB<C: Connection> {
    router: Arc<OnceLock<Router>>,
    param_tx: Option<Sender<Param>>,
    waiter: Arc<Waiter>,
    engine: PhantomData<C>,
}

impl<C> TenantDB<C>
where
    C: Connection,
{
    pub fn new_from_router_waiter(
        router: Arc<OnceLock<Router>>,
        param_tx: Sender<Param>,
        waiter: Arc<Waiter>,
    ) -> Self {
        Self {
            router,
            waiter,
            param_tx: Some(param_tx),
            engine: PhantomData,
        }
    }
}

impl<C> Clone for TenantDB<C>
where
    C: Connection,
{
    fn clone(&self) -> Self {
        Self {
            router: self.router.clone(),
            waiter: self.waiter.clone(),
            param_tx: self.param_tx.clone(),
            engine: self.engine,
        }
    }
}

impl<C> fmt::Debug for TenantDB<C>
where
    C: Connection,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("Tenant")
            .field("router", &self.router)
            .field("engine", &self.engine)
            .finish()
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

#[cfg(test)]
mod tests {
    use super::*;
    use engine::ws::Ws;
    use futures::StreamExt;
    use serde::Deserialize;
    use std::time::Duration;

    #[derive(Debug, Deserialize)]
    pub struct Account {
        pub id: usize,
        pub name: String,
    }

    #[tokio::test]
    async fn test_connect() {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCIgOiAxLCAibmFtZSIgOiAiYWRtaW4iLCAiaXNfcm9vdCIgOiB0cnVlLCAicm9sZSIgOiAiYWRtaW4iLCAib3JnIiA6ICJ0ZXN0b3JnIiwgImlzdSIgOiAiMjAyNC0wNy0yNFQxNDoxMzo0Ni42NzkxNTcrMDA6MDAiLCAiZXhwIiA6ICIyMDI0LTA3LTI1VDE0OjEzOjQ2LjY3OTE1NyswMDowMCJ9.Vlt3oJNqn4fSkQ-E6lx8HywRvRve35Eo8n59bN5Mk9E";
        let db = TenantDB::new::<Ws>("localhost:8000/testorg/rpc")
            .await
            .unwrap();
        println!("connected");
        //db.authenticate(token).await.unwrap();
        let out = db.login("admin", "1").await.unwrap();
        //println!("{}", out.token);
        println!("logged in");
        let accs = db
            .query::<Vec<Account>>("select id, name from account")
            .await
            .unwrap();

        println!("{}", accs.len());

        tokio::time::sleep(Duration::from_secs(10)).await;

        let accs = db
            .query::<Vec<Account>>("select id, name from account")
            .await
            .unwrap();

        println!("{}", accs.len());

        //while let Some(acc) = item_stream.next().await {
        //    println!("{:?}", &acc);
        //}

        while let Some(out) = db.listen("db_changes").next().await {
            println!("Out: {}", &serde_json::to_string(&out).unwrap());
        }
    }
}
