use crate::engine::ws::Client;
use crate::engine::ws::Ws;
use crate::engine::ws::Wss;
use crate::Connection;
use anyhow::Result;
use std::net::SocketAddr;
use tenant::failure::Failure;
use url::Url;

#[derive(Debug)]
pub enum EndpointKind {
    Ws,
    Wss,
    Unsupported(String),
}

impl From<&str> for EndpointKind {
    fn from(s: &str) -> Self {
        match s {
            "ws" => Self::Ws,
            "wss" => Self::Wss,
            _ => Self::Unsupported(s.to_owned()),
        }
    }
}

/// A server address used to connect to the server
#[derive(Debug, Clone)]
pub struct Endpoint {
    pub url: Url,
    pub path: String,
}

impl Endpoint {
    pub(crate) fn new(url: Url) -> Self {
        Self {
            url,
            path: String::new(),
        }
    }

    #[doc(hidden)]
    pub fn parse_kind(&self) -> Result<EndpointKind, Failure> {
        match EndpointKind::from(self.url.scheme()) {
            EndpointKind::Unsupported(s) => Err(Failure::custom(s)),
            kind => Ok(kind),
        }
    }
}

/// A trait for converting inputs to a server address object
pub trait IntoEndpoint<Scheme> {
    /// The client implied by this scheme and address combination
    type Client: Connection;
    /// Converts an input into a server address object
    fn into_endpoint(self) -> Result<Endpoint, Failure>;
}

macro_rules! endpoints {
	($($name:ty),*) => {
		$(
			impl IntoEndpoint<Ws> for $name {
				type Client = Client;

				fn into_endpoint(self) -> Result<Endpoint, Failure> {
					let url = format!("ws://{self}");
					Ok(Endpoint::new(Url::parse(&url).map_err(|_| Failure::custom("Invalid URL"))?))
				}
			}


			impl IntoEndpoint<Wss> for $name {
				type Client = Client;

				fn into_endpoint(self) -> Result<Endpoint, Failure> {
					let url = format!("wss://{self}");
					Ok(Endpoint::new(Url::parse(&url).map_err(|_| Failure::custom("Invalid URL"))?))
				}
			}

		)*
	}
}

endpoints!(&str, &String, String, SocketAddr);
