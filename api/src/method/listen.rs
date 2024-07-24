use crate::{Connection, TenantDB};
use channel::Receiver;
use futures::StreamExt;
use std::borrow::Cow;
use std::pin::Pin;
use std::task::{Context, Poll};
use tenant::cdc;

/// An listen stream
#[derive(Debug)]
pub struct Listen<'r, C: Connection> {
    pub client: Cow<'r, TenantDB<C>>,
    pub rx: Receiver<cdc::Transaction>,
}

impl<'r, C> futures::Stream for Listen<'r, C>
where
    C: Connection + Unpin,
{
    type Item = cdc::Transaction;

    fn poll_next(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Self::Item>> {
        match self.as_mut().rx.poll_next_unpin(cx) {
            Poll::Ready(Some(n)) => Poll::Ready(Some(n)),
            Poll::Ready(None) => Poll::Ready(None),
            Poll::Pending => Poll::Pending,
        }
    }
}
