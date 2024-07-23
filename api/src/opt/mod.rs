use tenant::{cdc, rpc::QueryStreamNotification};
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
    pub(crate) listen_channel_sender: Option<(String, channel::Sender<cdc::Transaction>)>,
}

impl Param {
    pub(crate) fn query_stream_notification_sender(
        stream_id: Uuid,
        sender: channel::Sender<QueryStreamNotification>,
    ) -> Self {
        Self {
            query_stream_notification_sender: Some((stream_id, sender)),
            listen_channel_sender: None,
        }
    }

    pub(crate) fn listen_chnnel_sender(
        channel: String,
        sender: channel::Sender<cdc::Transaction>,
    ) -> Self {
        Self {
            query_stream_notification_sender: None,
            listen_channel_sender: Some((channel, sender)),
        }
    }
}
