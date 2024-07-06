/// Makes the client wait for a certain event or call to happen before continuing
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
#[non_exhaustive]
pub enum WaitFor {
    /// Waits for the connection to succeed
    Connection,
    /// Waits for the desired database to be selected
    Database,
}
