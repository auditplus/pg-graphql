use crate::ConnectOptions;
use crate::{method::BoxFuture, opt::endpoint::Endpoint, TenantDB};
use anyhow::Result;
use channel::{Receiver, Sender};
use futures::Future;
use serde::{de::DeserializeOwned, Serialize};
use std::pin::Pin;
use std::sync::atomic::{AtomicI64, Ordering};
use tenant::{
    cdc,
    failure::Failure,
    rpc::{QueryResult, QueryStreamNotification, Request, RequestData},
};
use uuid::Uuid;

#[derive(Debug)]
pub(crate) struct Route {
    pub(crate) request: Request,
    pub(crate) response: Sender<QueryResult>,
}

/// Message router
#[derive(Debug)]
pub struct Router {
    pub(crate) sender: Sender<Route>,
    pub(crate) last_id: AtomicI64,
}

impl Router {
    pub(crate) fn next_id(&self) -> i64 {
        self.last_id.fetch_add(1, Ordering::SeqCst)
    }

    /// Execute methods that return nothing
    pub(crate) fn execute_query<'r, R>(
        router: &'r Router,
        data: RequestData,
    ) -> Pin<Box<dyn Future<Output = Result<R>> + Send + Sync + 'r>>
    where
        R: DeserializeOwned,
    {
        Box::pin(async move {
            let rx = Router::send(router, data).await?;
            let res = Router::recv_query(rx).await??;
            let out = serde_json::from_value(res)?;
            Ok(out)
        })
    }

    pub async fn send(router: &Router, data: RequestData) -> Result<Receiver<QueryResult>> {
        let request = Request {
            id: router.next_id().to_string(),
            data,
        };
        let (sender, receiver) = channel::bounded(1);
        let route = Route {
            request,
            response: sender,
        };
        router.sender.send(route).await?;
        Ok(receiver)
    }

    //fn recv(
    //    receiver: Receiver<DbResponse>,
    //) -> Pin<Box<dyn Future<Output = Result<serde_json::Value>> + Send + Sync>> {
    //    Box::pin(async move {
    //        let response = receiver.into_recv_async().await?;
    //        Ok(serde_json::Value::Null)
    //        //match response? {
    //        //    DbResponse::Other(value) => Ok(value),
    //        //    DbResponse::Query(..) => unreachable!(),
    //        //}
    //    })
    //}

    /// Receive the response of the `query` method
    async fn recv_query(receiver: Receiver<QueryResult>) -> Result<QueryResult> {
        let response = receiver.recv().await?;
        Ok(response)
    }
}

#[derive(Debug, Clone, Copy, Serialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
#[allow(dead_code)]
pub enum Method {
    /// Sends an authentication token to the server
    Authenticate,
    /// Invalidate user session
    Invalidate,
    /// Kills a live query
    Kill,
    /// Starts a live query
    Live,
    /// Sends a raw query to the database
    Query,
    /// Signs into the server
    Login,
    /// Removes a parameter from a connection
    Version,
}

#[derive(Debug, Default)]
pub struct Param {
    pub(crate) query_stream_notification_sender:
        Option<(Uuid, channel::Sender<QueryStreamNotification>)>,
    pub(crate) listen_channel_sender: Option<(String, channel::Sender<cdc::Transaction>)>,
    pub(crate) token: Option<String>,
}

impl Param {
    pub(crate) fn query_stream_notification_sender(
        stream_id: Uuid,
        sender: channel::Sender<QueryStreamNotification>,
    ) -> Self {
        Self {
            query_stream_notification_sender: Some((stream_id, sender)),
            listen_channel_sender: None,
            token: None,
        }
    }

    pub(crate) fn listen_chnnel_sender(
        channel: String,
        sender: channel::Sender<cdc::Transaction>,
    ) -> Self {
        Self {
            query_stream_notification_sender: None,
            listen_channel_sender: Some((channel, sender)),
            token: None,
        }
    }

    pub(crate) fn token(s: String) -> Self {
        Self {
            query_stream_notification_sender: None,
            listen_channel_sender: None,
            token: Some(s),
        }
    }
}

/// Connection trait implemented by supported protocols
pub trait Connection: Sized + Send + Sync + 'static {
    /// Connect to the server
    fn connect(
        address: Endpoint,
        opts: ConnectOptions,
    ) -> BoxFuture<'static, Result<TenantDB<Self>, Failure>>
    where
        Self: crate::Connection;
}
