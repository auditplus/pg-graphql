mod authenticate;
mod listen;
mod login;
mod query;

use crate::conn::Param;
use crate::opt::endpoint::IntoEndpoint;
use crate::Connect;
use crate::Connection;
use crate::TenantDB;
use futures::Future;
use serde::de::DeserializeOwned;

pub use authenticate::Authenticate;
pub use listen::Listen;
pub use login::Login;
pub use query::Query;
use std::borrow::Cow;
use std::marker::PhantomData;
use std::pin::Pin;
use std::sync::Arc;
use std::sync::OnceLock;
use tenant::cdc;
use tenant::QueryParams;
use tokio::sync::watch;

pub(crate) type BoxFuture<'a, T> = Pin<Box<dyn Future<Output = T> + Send + Sync + 'a>>;

impl<C> TenantDB<C>
where
    C: Connection + Unpin,
{
    pub fn init() -> Self {
        Self {
            router: Arc::new(OnceLock::new()),
            param_tx: None,
            waiter: Arc::new(watch::channel(None)),
            engine: PhantomData,
        }
    }

    pub fn new<P>(address: impl IntoEndpoint<P, Client = C>) -> Connect<C, Self> {
        Connect {
            router: Arc::new(OnceLock::new()),
            engine: PhantomData,
            address: address.into_endpoint(),
            capacity: 0,
            waiter: Arc::new(watch::channel(None)),
            response_type: PhantomData,
        }
    }

    pub fn authenticate(&self, token: impl Into<String>) -> Authenticate<C> {
        Authenticate {
            client: Cow::Borrowed(self),
            token: token.into(),
        }
    }

    pub fn login(&self, username: impl Into<String>, password: impl Into<String>) -> Login<C> {
        Login {
            client: Cow::Borrowed(self),
            username: username.into(),
            password: password.into(),
        }
    }

    pub fn query<R>(&self, query: impl Into<String>) -> Query<C, R>
    where
        R: DeserializeOwned,
    {
        Query {
            client: Cow::Borrowed(self),
            params: QueryParams::new(query),
            data: PhantomData,
        }
    }

    pub fn listen(&self, channel: impl Into<String>) -> Listen<C> {
        let channel: String = channel.into();
        let (tx, rx) = channel::unbounded::<cdc::Transaction>();
        let param = Param::listen_chnnel_sender(channel, tx);
        self.param_tx.as_ref().unwrap().try_send(param).unwrap();
        Listen {
            client: Cow::Borrowed(self),
            rx,
        }
    }
}
