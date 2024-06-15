use once_cell::sync::Lazy;
use std::time::Duration;
#[macro_export]
macro_rules! lazy_env_parse {
    ($key:expr, $t:ty, $default:expr) => {
        once_cell::sync::Lazy::new(|| {
            std::env::var($key)
                .and_then(|s| Ok(s.parse::<$t>().unwrap_or($default)))
                .unwrap_or($default)
        })
    };
}

pub static WEBSOCKET_MAX_CONCURRENT_REQUESTS: Lazy<usize> =
    lazy_env_parse!("SURREAL_WEBSOCKET_MAX_CONCURRENT_REQUESTS", usize, 24);

pub const WEBSOCKET_PING_FREQUENCY: Duration = Duration::from_secs(5);

pub static WEBSOCKET_MAX_FRAME_SIZE: Lazy<usize> =
    lazy_env_parse!("SURREAL_WEBSOCKET_MAX_FRAME_SIZE", usize, 16 << 20);

/// What is the maximum WebSocket message size (defaults to 128 MiB)
pub static WEBSOCKET_MAX_MESSAGE_SIZE: Lazy<usize> =
    lazy_env_parse!("SURREAL_WEBSOCKET_MAX_MESSAGE_SIZE", usize, 128 << 20);

pub const PROTOCOLS: [&str; 5] = [
    "json",     // For basic JSON serialisation
    "cbor",     // For basic CBOR serialisation
    "msgpack",  // For basic Msgpack serialisation
    "bincode",  // For full internal serialisation
    "revision", // For full versioned serialisation
];
