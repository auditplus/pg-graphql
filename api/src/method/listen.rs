use crate::TenantDB;
use channel::Receiver;
use futures::StreamExt;
use serde::de::DeserializeOwned;
use std::borrow::Cow;
use std::marker::PhantomData;
use std::pin::Pin;
use std::task::{Context, Poll};

/// An listen stream
#[derive(Debug)]
pub struct Listen<'r, R> {
    pub client: Cow<'r, TenantDB>,
    pub rx: Receiver<serde_json::Value>,
    pub data: PhantomData<R>,
}

impl<'r, R> futures::Stream for Listen<'r, R>
where
    R: DeserializeOwned + Unpin,
{
    type Item = R;

    fn poll_next(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Self::Item>> {
        match self.as_mut().rx.poll_next_unpin(cx) {
            Poll::Ready(Some(n)) => {
                let out = serde_json::from_value::<R>(n).ok();
                Poll::Ready(out)
            }
            Poll::Ready(None) => Poll::Ready(None),
            Poll::Pending => Poll::Pending,
        }
    }
}
