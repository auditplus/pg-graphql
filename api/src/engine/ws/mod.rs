use channel::Sender;
use std::{collections::HashMap, marker::PhantomData};
use tenant::{
    cdc,
    rpc::{QueryResult, QueryStreamNotification},
};
use trice::Instant;
use uuid::Uuid;

use crate::{opt::endpoint::IntoEndpoint, Connect, TenantDB};

mod native;

/// The WS scheme used to connect to `ws://` endpoints
#[derive(Debug)]
pub struct Ws;

/// The WSS scheme used to connect to `wss://` endpoints
#[derive(Debug)]
pub struct Wss;

pub struct RouterState<Sink, Stream> {
    live_queries: HashMap<Uuid, Sender<QueryStreamNotification>>,
    routes: HashMap<String, Sender<QueryResult>>,
    channels: HashMap<String, Sender<cdc::Transaction>>,
    last_activity: Instant,
    sink: Sink,
    stream: Stream,
}

impl<Sink, Stream> RouterState<Sink, Stream> {
    pub fn new(sink: Sink, stream: Stream) -> Self {
        RouterState {
            live_queries: HashMap::new(),
            routes: HashMap::new(),
            channels: HashMap::new(),
            last_activity: Instant::now(),
            sink,
            stream,
        }
    }
}

enum HandleResult {
    /// Socket disconnected, should continue to reconnect
    Disconnected,
    /// Nothing wrong continue as normal.
    Ok,
}

#[derive(Debug, Clone)]
pub struct Client(());

impl TenantDB<Client> {
    pub fn connect<P>(
        &self,
        address: impl IntoEndpoint<P, Client = Client>,
    ) -> Connect<Client, ()> {
        Connect {
            router: self.router.clone(),
            engine: PhantomData,
            address: address.into_endpoint(),
            capacity: 0,
            waiter: self.waiter.clone(),
            response_type: PhantomData,
        }
    }
}
