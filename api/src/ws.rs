use crate::opt::{Param, WaitFor};
use crate::OnceLockExt;
use crate::{IntervalStream, RequestData, Route, Router};
use anyhow::Result;
use flume::Receiver;
use futures::stream::SplitSink;
use futures::SinkExt;
use futures::StreamExt;
use futures_concurrency::stream::Merge as _;
use indexmap::IndexMap;
use serde::de::DeserializeOwned;
use serde::Deserialize;
use std::collections::hash_map::Entry;
use std::collections::BTreeMap;
use std::collections::HashMap;
use std::collections::HashSet;
use std::future::Future;
use std::marker::PhantomData;
use std::mem;
use std::pin::Pin;
use std::sync::atomic::AtomicI64;
use std::sync::Arc;
use std::sync::OnceLock;
use std::time::Duration;
use tenant::rpc::{DbResponse, QueryResult, QueryStreamNotification, Request, Response};
use tokio::net::TcpStream;
use tokio::sync::watch;
use tokio::time;
use tokio::time::MissedTickBehavior;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::error::Error as WsError;
use tokio_tungstenite::tungstenite::http::header::SEC_WEBSOCKET_PROTOCOL;
use tokio_tungstenite::tungstenite::http::HeaderValue;
use tokio_tungstenite::tungstenite::protocol::WebSocketConfig;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::Connector;
use tokio_tungstenite::MaybeTlsStream;
use tokio_tungstenite::WebSocketStream;
use trice::Instant;

pub(crate) const PATH: &str = "rpc";
const PING_INTERVAL: Duration = Duration::from_secs(5);
const PING_METHOD: &str = "ping";

type WsResult<T> = std::result::Result<T, WsError>;

pub(crate) const MAX_MESSAGE_SIZE: usize = 64 << 20; // 64 MiB
pub(crate) const MAX_FRAME_SIZE: usize = 16 << 20; // 16 MiB
pub(crate) const WRITE_BUFFER_SIZE: usize = 128000; // tungstenite default
pub(crate) const MAX_WRITE_BUFFER_SIZE: usize = WRITE_BUFFER_SIZE + MAX_MESSAGE_SIZE; // Recommended max according to tungstenite docs
pub(crate) const NAGLE_ALG: bool = false;

pub(crate) enum Either {
    Request(Option<Route>),
    Response(WsResult<Message>),
    Ping,
}

#[cfg(any(feature = "native-tls", feature = "rustls"))]
impl From<Tls> for Connector {
    fn from(tls: Tls) -> Self {
        match tls {
            #[cfg(feature = "native-tls")]
            Tls::Native(config) => Self::NativeTls(config),
            #[cfg(feature = "rustls")]
            Tls::Rust(config) => Self::Rustls(Arc::new(config)),
        }
    }
}

#[derive(Debug, Clone)]
pub struct WsContext;

impl WsContext {
    /// Execute methods that return nothing
    pub(crate) fn execute_query<'r, R>(
        router: &'r Router,
        param: Param,
        data: RequestData,
    ) -> Pin<Box<dyn Future<Output = Result<R>> + Send + Sync + 'r>>
    where
        R: DeserializeOwned,
    {
        Box::pin(async move {
            let rx = WsContext::send(router, param, data).await?;
            let res = WsContext::recv_query(rx).await??;
            let out = serde_json::from_value(res)?;
            Ok(out)
        })
    }

    async fn send(
        router: &Router,
        param: Param,
        data: RequestData,
    ) -> Result<Receiver<QueryResult>> {
        let request = Request {
            id: router.next_id().to_string(),
            data,
        };
        let (sender, receiver) = flume::bounded(1);
        let route = Route {
            request,
            param,
            response: sender,
        };
        router.sender.send_async(Some(route)).await?;
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
        let response = receiver.into_recv_async().await?;
        Ok(response)
    }
}

#[allow(clippy::too_many_lines)]
pub(crate) fn router(
    endpoint: String,
    maybe_connector: Option<Connector>,
    capacity: usize,
    config: WebSocketConfig,
    mut socket: WebSocketStream<MaybeTlsStream<TcpStream>>,
    route_rx: Receiver<Option<Route>>,
) {
    tokio::spawn(async move {
        let ping = { Message::Ping(Vec::new()) };

        //let mut var_stash = IndexMap::new();
        //let mut vars = IndexMap::new();
        //let mut replay = IndexMap::new();

        'router: loop {
            let (socket_sink, socket_stream) = socket.split();
            let mut socket_sink = Socket(Some(socket_sink));

            if let Socket(Some(socket_sink)) = &mut socket_sink {
                let mut routes = match capacity {
                    0 => HashMap::new(),
                    capacity => HashMap::with_capacity(capacity),
                };
                let mut live_queries = HashMap::new();

                let mut interval = time::interval(PING_INTERVAL);
                // don't bombard the server with pings if we miss some ticks
                interval.set_missed_tick_behavior(MissedTickBehavior::Delay);

                let pinger = IntervalStream::new(interval);

                let streams = (
                    socket_stream.map(Either::Response),
                    route_rx.stream().map(Either::Request),
                    pinger.map(|_| Either::Ping),
                );

                let mut merged = streams.merge();
                let mut last_activity = Instant::now();

                while let Some(either) = merged.next().await {
                    match either {
                        Either::Request(Some(Route {
                            request,
                            param,
                            response,
                        })) => {
                            if let Some((stream_id, stream_sender)) =
                                param.query_stream_notification_sender
                            {
                                live_queries.insert(stream_id, stream_sender);
                            }

                            let message = {
                                let payload = serde_json::to_string(&request).unwrap();
                                //println!("Request {payload}");
                                Message::text(payload)
                            };
                            //if let Method::Authenticate | Method::Invalidate = data.method {
                            //    replay.insert(data.method, message.clone());
                            //}
                            match socket_sink.send(message).await {
                                Ok(..) => {
                                    last_activity = Instant::now();
                                    match routes.entry(request.id) {
                                        Entry::Vacant(entry) => {
                                            // Register query route
                                            entry.insert(response);
                                        }
                                        Entry::Occupied(..) => {
                                            //let error = Error::DuplicateRequestId(id);
                                            //if response
                                            //    .into_send_async(Err("Duplicate request id".into()))
                                            //    .await
                                            //    .is_err()
                                            //{
                                            //    println!("Receiver dropped");
                                            //}
                                        }
                                    }
                                }
                                Err(error) => {
                                    println!("{}", error.to_string());
                                    //let error = Error::Ws(error.to_string());
                                    //if response.into_send_async(Err(error.into())).await.is_err() {
                                    //    println!("Receiver dropped");
                                    //}
                                    break;
                                }
                            }
                        }
                        Either::Response(result) => {
                            last_activity = Instant::now();
                            match result {
                                Ok(message) => {
                                    match DbResponse::try_from_message(&message) {
                                        Ok(option) => {
                                            // We are only interested in responses that are not empty
                                            if let Some(response) = option {
                                                match response {
                                                    DbResponse::QueryResponse(response) => {
                                                        // We can only route responses with IDs
                                                        if let Some(sender) =
                                                            routes.remove(&response.id)
                                                        {
                                                            // Send the response back to the caller
                                                            let response = response.result;
                                                            let _res = sender
                                                                .into_send_async(response)
                                                                .await;
                                                        }
                                                    }
                                                    DbResponse::QueryStreamNotification(
                                                        response,
                                                    ) => {
                                                        let stream_id = response.stream_id;
                                                        if let Some(sender) =
                                                            live_queries.get(&stream_id)
                                                        {
                                                            // Send the notification back to the caller or kill live query if the receiver is already dropped
                                                            if sender.send(response).await.is_err()
                                                            {
                                                                live_queries.remove(&stream_id);
                                                                //let kill = {
                                                                //    let mut request =
                                                                //        BTreeMap::new();
                                                                //    request.insert(
                                                                //        "method".to_owned(),
                                                                //        Method::Kill
                                                                //            .as_str()
                                                                //            .into(),
                                                                //    );
                                                                //    request.insert(
                                                                //        "params".to_owned(),
                                                                //        vec![Value::from(
                                                                //            live_query_id,
                                                                //        )]
                                                                //        .into(),
                                                                //    );
                                                                //    let value =
                                                                //        Value::from(request);
                                                                //    let value = serialize(
                                                                //        &value,
                                                                //        endpoint.supports_revision,
                                                                //    )
                                                                //    .unwrap();
                                                                //    Message::Binary(value)
                                                                //};
                                                                //if let Err(error) =
                                                                //    socket_sink.send(kill).await
                                                                //{
                                                                //    trace!("failed to send kill query to the server; {error:?}");
                                                                //    break;
                                                                //}
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        Err(error) => {
                                            #[derive(Deserialize)]
                                            struct Response {
                                                id: Option<serde_json::Value>,
                                            }

                                            // Let's try to find out the ID of the response that failed to deserialise
                                            if let Message::Text(text) = message {
                                                if let Ok(Response { id }) =
                                                    serde_json::from_str(&text)
                                                {
                                                    // Return an error if an ID was returned

                                                    //if let Some(Ok(id)) =
                                                    //    id.map(Value::coerce_to_i64)
                                                    //{
                                                    //    if let Some((_method, sender)) =
                                                    //        routes.remove(&id)
                                                    //    {
                                                    //        let _res = sender
                                                    //            .into_send_async(Err(error))
                                                    //            .await;
                                                    //    }
                                                    //}
                                                } else {
                                                    // Unfortunately, we don't know which response failed to deserialize
                                                    println!(
                                                        "Failed to deserialise message; {error:?}"
                                                    );
                                                }
                                            }
                                        }
                                    }
                                }
                                Err(error) => {
                                    match error {
                                        WsError::ConnectionClosed => {
                                            println!(
                                                "Connection successfully closed on the server"
                                            );
                                        }
                                        error => {
                                            println!("{error}");
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                        Either::Ping => {
                            // only ping if we haven't talked to the server recently
                            if last_activity.elapsed() >= PING_INTERVAL {
                                println!("Pinging the server");
                                if let Err(error) = socket_sink.send(ping.clone()).await {
                                    println!("failed to ping the server; {error:?}");
                                    break;
                                }
                            }
                        }
                        // Close connection request received
                        Either::Request(None) => {
                            match socket_sink.send(Message::Close(None)).await {
                                Ok(..) => println!("Connection closed successfully"),
                                Err(error) => {
                                    println!("Failed to close database connection; {error}")
                                }
                            }
                            break 'router;
                        }
                    }
                }
            }

            'reconnect: loop {
                println!("Reconnecting...");
                match tokio_tungstenite::connect_async_with_config(
                    &*endpoint,
                    Some(config),
                    NAGLE_ALG,
                )
                .await
                {
                    Ok((s, _)) => {
                        socket = s;
                        //for (_, message) in &replay {
                        //    if let Err(error) = socket.send(message.clone()).await {
                        //        println!("{error}");
                        //        time::sleep(time::Duration::from_secs(1)).await;
                        //        continue 'reconnect;
                        //    }
                        //}
                        //for (key, value) in &vars {
                        //    let mut request = BTreeMap::new();
                        //    request.insert("method".to_owned(), Method::Set.as_str().into());
                        //    request.insert(
                        //        "params".to_owned(),
                        //        vec![key.as_str().into(), value.clone()].into(),
                        //    );
                        //    let payload = Value::from(request);
                        //    trace!("Request {payload}");
                        //    if let Err(error) = socket.send(Message::Binary(payload.into())).await {
                        //        trace!("{error}");
                        //        time::sleep(time::Duration::from_secs(1)).await;
                        //        continue 'reconnect;
                        //    }
                        //}
                        //trace!("Reconnected successfully");
                        //break;
                    }
                    Err(error) => {
                        println!("Failed to reconnect; {error}");
                        time::sleep(time::Duration::from_secs(1)).await;
                    }
                }
            }
        }
    });
}

pub struct Socket(Option<SplitSink<WebSocketStream<MaybeTlsStream<TcpStream>>, Message>>);
