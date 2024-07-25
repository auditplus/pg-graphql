use crate::conn::{Connection, Param, Route, Router};
use crate::engine::IntervalStream;
use crate::method::BoxFuture;
use crate::opt::endpoint::Endpoint;
use crate::opt::WaitFor;
use crate::{ConnectOptions, OnceLockExt, TenantDB};
use anyhow::Result;
use channel::{Receiver, Sender};
use futures::stream::{SplitSink, SplitStream};
use futures::StreamExt;
use futures::{FutureExt, SinkExt};
use pharos::{Channel, Events, Observable, ObserveConfig};
use serde::Deserialize;
use std::collections::hash_map::Entry;
use std::sync::atomic::AtomicI64;
use std::sync::{Arc, OnceLock};
use std::time::Duration;
use tenant::failure::Failure;
use tenant::rpc::DbResponse;
use tokio::sync::watch;
use trice::Instant;
use wasm_bindgen_futures::spawn_local;
use wasmtimer::tokio as time;
use wasmtimer::tokio::MissedTickBehavior;
use ws_stream_wasm::WsMessage as Message;
use ws_stream_wasm::WsMeta;
use ws_stream_wasm::{WsEvent, WsStream};

use super::{Client, HandleResult};

const PING_INTERVAL: Duration = Duration::from_secs(5);

pub(crate) const MAX_MESSAGE_SIZE: usize = 64 << 20; // 64 MiB
pub(crate) const MAX_FRAME_SIZE: usize = 16 << 20; // 16 MiB
pub(crate) const WRITE_BUFFER_SIZE: usize = 128000; // tungstenite default
pub(crate) const MAX_WRITE_BUFFER_SIZE: usize = WRITE_BUFFER_SIZE + MAX_MESSAGE_SIZE; // Recommended max according to tungstenite docs
pub(crate) const NAGLE_ALG: bool = false;

type MessageStream = SplitStream<WsStream>;
type MessageSink = SplitSink<WsStream, Message>;
type RouterState = super::RouterState<MessageSink, MessageStream>;

impl crate::Connection for Client {}

impl Connection for Client {
    fn connect(
        address: Endpoint,
        opts: ConnectOptions,
    ) -> BoxFuture<'static, Result<TenantDB<Self>, Failure>> {
        Box::pin(async move {
            //address.url = address.url.join(PATH)?;

            let (param_tx, param_rx) = channel::unbounded();

            let (route_tx, route_rx) = match opts.capacity {
                0 => channel::unbounded(),
                capacity => channel::bounded(capacity),
            };

            let (conn_tx, conn_rx) = channel::bounded(1);

            spawn_local(run_router(address, opts, conn_tx, param_rx, route_rx));

            conn_rx.recv().await.unwrap()?;

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

async fn router_handle_request(
    Route { request, response }: Route,
    state: &mut RouterState,
) -> HandleResult {
    let message = {
        let payload = serde_json::to_string(&request).unwrap();
        Message::Text(payload)
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

async fn router_handle_response(
    response: Message,
    state: &mut RouterState,
    _endpoint: &Endpoint,
) -> HandleResult {
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
    state: &mut RouterState,
    events: &mut Events<WsEvent>,
    endpoint: &Endpoint,
    capacity: usize,
) {
    loop {
        println!("Reconnecting...");
        let mut endpoint = endpoint.clone();
        if let Some(token) = &state.token {
            endpoint
                .url
                .set_query(Some(&format!("auth-token={}", token)));
        }
        match WsMeta::connect(&endpoint.url, None).await {
            Ok((mut meta, stream)) => {
                let (new_sink, new_stream) = stream.split();
                state.sink = new_sink;
                state.stream = new_stream;
                *events = {
                    let result = match capacity {
                        0 => meta.observe(ObserveConfig::default()).await,
                        capacity => meta.observe(Channel::Bounded(capacity).into()).await,
                    };
                    match result {
                        Ok(events) => events,
                        Err(error) => {
                            println!("{error}");
                            time::sleep(Duration::from_secs(1)).await;
                            continue;
                        }
                    }
                };
                println!("Reconnected successfully");
                break;
            }
            Err(error) => {
                println!("Failed to reconnect; {error}");
                time::sleep(Duration::from_secs(1)).await;
            }
        }
    }
}

pub(crate) async fn run_router(
    mut endpoint: Endpoint,
    opts: ConnectOptions,
    conn_tx: Sender<Result<(), Failure>>,
    param_rx: Receiver<Param>,
    route_rx: Receiver<Route>,
) {
    // Set auth-token on the url if found
    if let Some(token) = &opts.token {
        endpoint
            .url
            .set_query(Some(&format!("auth-token={}", token)));
    }

    let (mut ws, socket) = match WsMeta::connect(&endpoint.url, None).await {
        Ok(pair) => pair,
        Err(error) => {
            let _ = conn_tx.send(Err(Failure::custom(error.to_string()))).await;
            return;
        }
    };

    let mut events = {
        let result = match opts.capacity {
            0 => ws.observe(ObserveConfig::default()).await,
            capacity => ws.observe(Channel::Bounded(capacity).into()).await,
        };
        match result {
            Ok(events) => events,
            Err(error) => {
                let _ = conn_tx.send(Err(Failure::custom(error.to_string()))).await;
                return;
            }
        }
    };

    let _ = conn_tx.send(Ok(())).await;

    let ping = { Message::Text("PING".to_string()) };

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
        state.token.take();

        loop {
            futures::select! {
                param = param_rx.recv().fuse() => {
                    if let Ok(p) = param {
                        if let Some((channel, sender)) = p.listen_channel_sender {
                            state.channels.insert(channel, sender);
                        }
                        if let Some((stream_id, sender)) = p.query_stream_notification_sender {
                            state.live_queries.insert(stream_id, sender);
                        }
                        if let Some(token) = p.token {
                            let _ = state.token.insert(token);
                        }
                    }

                }
                route = route_rx.recv().fuse() => {
                    let Ok(route) = route else {
                        match ws.close().await {
                            Ok(..) => println!("Connection closed successfully"),
                            Err(error) => {
                                println!("Failed to close database connection; {error}")
                            }
                        }
                        break 'router;
                    };

                    match router_handle_request(route, &mut state).await {
                        HandleResult::Ok => {},
                        HandleResult::Disconnected => {
                            router_reconnect(&mut state, &mut events, &endpoint, opts.capacity).await;
                            break
                        }
                    }
                }
                message = state.stream.next().fuse() => {
                    let Some(message) = message else {
                        // socket disconnected,
                            router_reconnect(&mut state, &mut events, &endpoint, opts.capacity).await;
                            break
                    };

                    state.last_activity = Instant::now();
                    match router_handle_response(message, &mut state, &endpoint).await {
                        HandleResult::Ok => {},
                        HandleResult::Disconnected => {
                            router_reconnect(&mut state, &mut events, &endpoint, opts.capacity).await;
                            break
                        }
                    }
                }
                event = events.next().fuse() => {
                    let Some(event) = event else {
                        continue;
                    };
                    match event {
                        WsEvent::Error => {
                            println!("connection errored");
                            break;
                        }
                        WsEvent::WsErr(error) => {
                            println!("{error}");
                        }
                        WsEvent::Closed(..) => {
                            println!("connection closed");
                            router_reconnect(&mut state, &mut events, &endpoint, opts.capacity).await;
                            break;
                        }
                        _ => {}
                    }
                }
                _ = pinger.next().fuse() => {
                    if state.last_activity.elapsed() >= PING_INTERVAL {
                        println!("Pinging the server");
                        if let Err(error) = state.sink.send(ping.clone()).await {
                            println!("failed to ping the server; {error:?}");
                            router_reconnect(&mut state, &mut events, &endpoint, opts.capacity).await;
                            break;
                        }
                    }
                }
            }
        }
    }
}
