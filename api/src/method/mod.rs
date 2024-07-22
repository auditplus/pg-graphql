mod authenticate;
mod listen;
mod login;
mod query;

use serde::Serialize;

pub use authenticate::Authenticate;
pub use listen::Listen;
pub use login::Login;
pub use query::{Query, QueryStream};

#[derive(Debug, Clone, Copy, Serialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "lowercase")]
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
