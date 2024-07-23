use futures::Stream;
use std::pin::Pin;
use std::task::Context;
use std::task::Poll;

use tokio::time::Instant;
use tokio::time::Interval;

pub mod ws;

pub(crate) struct IntervalStream {
    inner: Interval,
}

impl IntervalStream {
    #[allow(unused)]
    fn new(interval: Interval) -> Self {
        Self { inner: interval }
    }
}

impl Stream for IntervalStream {
    type Item = Instant;

    fn poll_next(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Instant>> {
        self.inner.poll_tick(cx).map(Some)
    }
}
