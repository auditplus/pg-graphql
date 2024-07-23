use crate::conn::{Connection, Param, Route, Router};
use crate::engine::IntervalStream;
use crate::method::BoxFuture;
use crate::opt::endpoint::Endpoint;
use crate::opt::WaitFor;
use crate::{OnceLockExt, TenantDB};
use anyhow::Result;
use channel::Receiver;
use futures::stream::{SplitSink, SplitStream};
use futures::SinkExt;
use futures::StreamExt;
use serde::Deserialize;
use std::collections::hash_map::Entry;
use std::sync::atomic::AtomicI64;
use std::sync::{Arc, OnceLock};
use std::time::Duration;
use tenant::failure::Failure;
use tenant::rpc::DbResponse;
use tokio::net::TcpStream;
use tokio::sync::watch;
use tokio::time;
use tokio::time::MissedTickBehavior;
use tokio_tungstenite::tungstenite::client::IntoClientRequest;
use tokio_tungstenite::tungstenite::error::Error as WsError;
use tokio_tungstenite::tungstenite::protocol::WebSocketConfig;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::Connector;
use tokio_tungstenite::MaybeTlsStream;
use tokio_tungstenite::WebSocketStream;
use trice::Instant;

use super::{Client, HandleResult};

const PING_INTERVAL: Duration = Duration::from_secs(5);

pub(crate) const MAX_MESSAGE_SIZE: usize = 64 << 20; // 64 MiB
pub(crate) const MAX_FRAME_SIZE: usize = 16 << 20; // 16 MiB
pub(crate) const WRITE_BUFFER_SIZE: usize = 128000; // tungstenite default
pub(crate) const MAX_WRITE_BUFFER_SIZE: usize = WRITE_BUFFER_SIZE + MAX_MESSAGE_SIZE; // Recommended max according to tungstenite docs
pub(crate) const NAGLE_ALG: bool = false;

type MessageSink = SplitSink<WebSocketStream<MaybeTlsStream<TcpStream>>, Message>;
type MessageStream = SplitStream<WebSocketStream<MaybeTlsStream<TcpStream>>>;
type RouterState = super::RouterState<MessageSink, MessageStream>;

pub(crate) async fn connect(
    endpoint: &Endpoint,
    config: Option<WebSocketConfig>,
    #[allow(unused_variables)] maybe_connector: Option<Connector>,
) -> Result<WebSocketStream<MaybeTlsStream<TcpStream>>> {
    let request = (&endpoint.url).into_client_request()?;
    #[cfg(any(feature = "native-tls", feature = "rustls"))]
    let (socket, _) = tokio_tungstenite::connect_async_tls_with_config(
        request,
        config,
        NAGLE_ALG,
        maybe_connector,
    )
    .await?;

    #[cfg(not(any(feature = "native-tls", feature = "rustls")))]
    let (socket, _) =
        tokio_tungstenite::connect_async_with_config(request, config, NAGLE_ALG).await?;

    Ok(socket)
}

impl crate::Connection for Client {}

impl Connection for Client {
    fn connect(
        address: Endpoint,
        capacity: usize,
    ) -> BoxFuture<'static, Result<TenantDB<Self>, Failure>> {
        Box::pin(async move {
            //address.url = address.url.join(PATH)?;
            #[cfg(any(feature = "native-tls", feature = "rustls"))]
            let maybe_connector = address.config.tls_config.clone().map(Connector::from);
            #[cfg(not(any(feature = "native-tls", feature = "rustls")))]
            let maybe_connector = None;

            let config = WebSocketConfig {
                max_message_size: Some(MAX_MESSAGE_SIZE),
                max_frame_size: Some(MAX_FRAME_SIZE),
                max_write_buffer_size: MAX_WRITE_BUFFER_SIZE,
                ..Default::default()
            };

            let socket = connect(&address, Some(config), maybe_connector.clone())
                .await
                .map_err(|err| Failure::custom(err.to_string()))?;

            let (param_tx, param_rx) = channel::unbounded();

            let (route_tx, route_rx) = match capacity {
                0 => channel::unbounded(),
                capacity => channel::bounded(capacity),
            };

            tokio::spawn(run_router(
                address,
                maybe_connector,
                capacity,
                config,
                socket,
                param_rx,
                route_rx,
            ));

            Ok(TenantDB::new_from_router_waiter(
                Arc::new(OnceLock::with_value(Router {
                    sender: route_tx,
                    last_id: AtomicI64::new(0),
                })),
                param_tx,
                Arc::new(watch::channel(Some(WaitFor::Connection))),
            ))
        })
    }
}

async fn router_handle_route(
    Route { request, response }: Route,
    state: &mut RouterState,
) -> HandleResult {
    let message = {
        let payload = serde_json::to_string(&request).unwrap();
        Message::text(payload)
    };

    match state.sink.send(message).await {
        Ok(_) => {
            state.last_activity = Instant::now();
            match state.routes.entry(request.id) {
                Entry::Vacant(entry) => {
                    // Register query route
                    entry.insert(response);
                }
                Entry::Occupied(..) => {
                    // Do something where request is Occupied
                }
            }
        }
        Err(error) => {
            println!("{}", error);
            return HandleResult::Disconnected;
        }
    }
    HandleResult::Ok
}

async fn router_handle_response(response: Message, state: &mut RouterState) -> HandleResult {
    match DbResponse::try_from_message(&response) {
        Ok(option) => {
            // We are only interested in responses that are not empty
            if let Some(response) = option {
                match response {
                    DbResponse::QueryResponse(response) => {
                        // We can only route responses with IDs
                        if let Some(sender) = state.routes.remove(&response.id) {
                            // Send the response back to the caller
                            let response = response.result;
                            let _res = sender.send(response).await;
                        }
                    }
                    DbResponse::QueryStreamNotification(response) => {
                        let stream_id = response.stream_id;
                        if let Some(sender) = state.live_queries.get(&stream_id) {
                            // Send the notification back to the caller or kill live query if the receiver is already dropped
                            if sender.send(response).await.is_err() {
                                state.live_queries.remove(&stream_id);
                            }
                        }
                    }
                    DbResponse::ListenChanel(response) => {
                        let channel = response.channel;
                        if let Some(sender) = state.channels.get(&channel) {
                            // Send the notification back to the caller or kill live query if the receiver is already dropped
                            if sender.send(response.data).await.is_err() {
                                state.channels.remove(&channel);
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
            if let Message::Text(text) = response {
                if let Ok(Response { id }) = serde_json::from_str(&text) {
                    println!("Got some error value; {id:?}");
                } else {
                    // Unfortunately, we don't know which response failed to deserialize
                    println!("Failed to deserialise message; {error:?}");
                }
            }
        }
    }
    HandleResult::Ok
}

async fn router_reconnect(
    _maybe_connector: &Option<Connector>,
    _config: &WebSocketConfig,
    _state: &mut RouterState,
    _endpoint: &Endpoint,
) {
    //loop {
    //    trace!("Reconnecting...");
    //    match connect(endpoint, Some(*config), maybe_connector.clone()).await {
    //        Ok(s) => {
    //            let (new_sink, new_stream) = s.split();
    //            state.sink = new_sink;
    //            state.stream = new_stream;
    //            for (_, message) in &state.replay {
    //                if let Err(error) = state.sink.send(message.clone()).await {
    //                    trace!("{error}");
    //                    time::sleep(time::Duration::from_secs(1)).await;
    //                    continue;
    //                }
    //            }
    //            for (key, value) in &state.vars {
    //                let request = RouterRequest {
    //                    id: None,
    //                    method: Method::Set.as_str().into(),
    //                    params: Some(vec![key.as_str().into(), value.clone()].into()),
    //                };
    //                trace!("Request {:?}", request);
    //                let payload = serialize(&request, endpoint.supports_revision).unwrap();
    //                if let Err(error) = state.sink.send(Message::Binary(payload)).await {
    //                    trace!("{error}");
    //                    time::sleep(time::Duration::from_secs(1)).await;
    //                    continue;
    //                }
    //            }
    //            trace!("Reconnected successfully");
    //            break;
    //        }
    //        Err(error) => {
    //            trace!("Failed to reconnect; {error}");
    //            time::sleep(time::Duration::from_secs(1)).await;
    //        }
    //    }
    //}
}

pub(crate) async fn run_router(
    endpoint: Endpoint,
    maybe_connector: Option<Connector>,
    _capacity: usize,
    config: WebSocketConfig,
    socket: WebSocketStream<MaybeTlsStream<TcpStream>>,
    param_rx: Receiver<Param>,
    route_rx: Receiver<Route>,
) {
    let ping = { Message::Ping(Vec::new()) };

    let (socket_sink, socket_stream) = socket.split();
    let mut state = RouterState::new(socket_sink, socket_stream);

    'router: loop {
        let mut interval = time::interval(PING_INTERVAL);
        // don't bombard the server with pings if we miss some ticks
        interval.set_missed_tick_behavior(MissedTickBehavior::Delay);

        let mut pinger = IntervalStream::new(interval);
        // Turn into a stream instead of calling recv_async
        // The stream seems to be able to keep some state which would otherwise need to be
        // recreated with each next.

        state.last_activity = Instant::now();
        state.live_queries.clear();
        state.routes.clear();

        loop {
            tokio::select! {
                param = param_rx.recv() => {
                    if let Ok(p) = param {
                        if let Some((channel, sender)) = p.listen_channel_sender {
                            state.channels.insert(channel, sender);
                        }
                    if let Some((stream_id, sender)) = p.query_stream_notification_sender {
                            state.live_queries.insert(stream_id, sender);
                        }
                    }
                }
                route = route_rx.recv() => {
                    // handle incoming route

                    let Ok(response) = route else {
                        // route returned Err, frontend dropped the channel, meaning the router
                        match state.sink.send(Message::Close(None)).await {
                        // should quit.
                            Ok(..) => println!("Connection closed successfully"),
                            Err(error) => {
                                println!("Failed to close database connection; {error}")
                            }
                        }
                        break 'router;
                    };

                    match router_handle_route(response, &mut state).await {
                        HandleResult::Ok => {},
                        HandleResult::Disconnected => {
                            router_reconnect(
                                &maybe_connector,
                                &config,
                                &mut state,
                                &endpoint,
                            )
                            .await;
                            continue 'router;
                        }
                    }
                }
                result = state.stream.next() => {
                    // Handle result from database.

                    let Some(result) = result else {
                        // stream returned none meaning the connection dropped, try to reconnect.
                        router_reconnect(
                            &maybe_connector,
                            &config,
                            &mut state,
                            &endpoint,
                        )
                        .await;
                        continue 'router;
                    };

                    state.last_activity = Instant::now();
                    match result {
                        Ok(message) => {
                            match router_handle_response(message, &mut state).await {
                                HandleResult::Ok => continue,
                                HandleResult::Disconnected => {
                                    router_reconnect(
                                        &maybe_connector,
                                        &config,
                                        &mut state,
                                        &endpoint,
                                    )
                                    .await;
                                    continue 'router;
                                }
                            }
                        }
                        Err(error) => {
                            match error {
                                WsError::ConnectionClosed => {
                                    println!("Connection successfully closed on the server");
                                }
                                error => {
                                    println!("{error}");
                                }
                            }
                            router_reconnect(
                                &maybe_connector,
                                &config,
                                &mut state,
                                &endpoint,
                            )
                            .await;
                            continue 'router;
                        }
                    }
                }
                _ = pinger.next() => {
                    // only ping if we haven't talked to the server recently
                    if state.last_activity.elapsed() >= PING_INTERVAL {
                        println!("Pinging the server");
                        if let Err(error) = state.sink.send(ping.clone()).await {
                            println!("failed to ping the server; {error:?}");
                            router_reconnect(
                                &maybe_connector,
                                &config,
                                &mut state,
                               &endpoint,
                            )
                            .await;
                            continue 'router;
                        }
                    }

                }
            }
        }
    }
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
