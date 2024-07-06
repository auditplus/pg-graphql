use tenant::rpc::QueryStreamNotification;
use uuid::Uuid;

/// Makes the client wait for a certain event or call to happen before continuing
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
#[non_exhaustive]
pub enum WaitFor {
    /// Waits for the connection to succeed
    Connection,
    /// Waits for the desired database to be selected
    Database,
}

#[derive(Debug, Default)]
pub struct Param {
    pub(crate) query_stream_notification_sender:
        Option<(Uuid, channel::Sender<QueryStreamNotification>)>,
}

impl Param {
    pub(crate) fn query_stream_notification_sender(
        stream_id: Uuid,
        sender: channel::Sender<QueryStreamNotification>,
    ) -> Self {
        Self {
            query_stream_notification_sender: Some((stream_id, sender)),
        }
    }
}
