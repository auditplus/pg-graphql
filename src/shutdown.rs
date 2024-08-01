use crate::handler::rpc::WEBSOCKETS;
use axum_server::Handle;
use std::time::Duration;
use tokio::task::JoinHandle;
use tokio_util::sync::CancellationToken;

pub(crate) async fn rpc_graceful_shutdown() {
    // Close WebSocket connections, ensuring queued messages are processed
    for (_, rpc) in WEBSOCKETS.read().await.iter() {
        rpc.read().await.canceller.cancel();
    }
    // Wait for all existing WebSocket connections to finish sending
    while WEBSOCKETS.read().await.len() > 0 {
        tokio::time::sleep(Duration::from_millis(100)).await;
    }
}

/// Forces a fast shutdown of all WebSocket connections
pub(crate) fn rpc_shutdown() {
    // Close all WebSocket connections immediately
    if let Ok(mut writer) = WEBSOCKETS.try_write() {
        writer.drain();
    }
}

/// Start a graceful shutdown:
/// * Signal the Axum Handle when a shutdown signal is received.
/// * Stop all WebSocket connections.
/// * Flush all telemetry data.
///
/// A second signal will force an immediate shutdown.
pub fn graceful_shutdown(ct: CancellationToken, http_handle: Handle) -> JoinHandle<()> {
    tokio::spawn(async move {
        //let result = listen().await.expect("Failed to listen to shutdown signal");
        let result = listen().await;
        println!("{} received. Waiting for graceful shutdown... A second signal will force an immediate shutdown", result);

        let shutdown = {
            let http_handle = http_handle.clone();
            let ct = ct.clone();

            tokio::spawn(async move {
                // Stop accepting new HTTP requests and wait until all connections are closed
                http_handle.graceful_shutdown(None);
                while http_handle.connection_count() > 0 {
                    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
                }

                rpc_graceful_shutdown().await;

                ct.cancel();

                // Flush all telemetry data
                //if let Err(err) = telemetry::shutdown() {
                //    error!("Failed to flush telemetry data: {}", err);
                //}
            })
        };

        tokio::select! {
            // Start a normal graceful shutdown
            _ = shutdown => (),
            // Force an immediate shutdown if a second signal is received
            _ = async {
                //if let Ok(signal) = listen().await {
                //    println!("{} received during graceful shutdown. Terminate immediately...", signal);
                //} else {
                //    println!("Failed to listen to shutdown signal. Terminate immediately...");
                //}
                let _signal = listen().await;

                // Force an immediate shutdown
                http_handle.shutdown();

                // Close all WebSocket connections immediately
                rpc_shutdown();

                // Cancel cancellation token
                ct.cancel();
            } => (),
        }
    })
}

#[cfg(unix)]
pub async fn listen() -> String {
    // Import the OS signals
    use tokio::signal::unix::{signal, SignalKind};
    // Get the operating system signal types
    let mut sighup = signal(SignalKind::hangup()).unwrap();
    let mut sigint = signal(SignalKind::interrupt()).unwrap();
    let mut sigquit = signal(SignalKind::quit()).unwrap();
    let mut sigterm = signal(SignalKind::terminate()).unwrap();
    // Listen and wait for the system signals
    tokio::select! {
        // Wait for a SIGHUP signal
        _ = sighup.recv() => {
            String::from("SIGHUP")
        }
        // Wait for a SIGINT signal
        _ = sigint.recv() => {
            String::from("SIGINT")
        }
        // Wait for a SIGQUIT signal
        _ = sigquit.recv() => {
            String::from("SIGQUIT")
        }
        // Wait for a SIGTERM signal
        _ = sigterm.recv() => {
            String::from("SIGTERM")
        }
    }
}

#[cfg(windows)]
pub async fn listen() -> String {
    // Import the OS signals
    use tokio::signal::windows;
    // Get the operating system signal types
    let mut exit = windows::ctrl_c().unwrap();
    let mut leave = windows::ctrl_break().unwrap();
    let mut close = windows::ctrl_close().unwrap();
    let mut shutdown = windows::ctrl_shutdown().unwrap();
    // Listen and wait for the system signals
    tokio::select! {
        // Wait for a CTRL-C signal
        _ = exit.recv() => {
            String::from("CTRL-C")
        }
        // Wait for a CTRL-BREAK signal
        _ = leave.recv() => {
            String::from("CTRL-BREAK")
        }
        // Wait for a CTRL-CLOSE signal
        _ = close.recv() => {
            String::from("CTRL-CLOSE")
        }
        // Wait for a CTRL-SHUTDOWN signal
        _ = shutdown.recv() => {
            String::from("CTRL-SHUTDOWN")
        }
    }
}
