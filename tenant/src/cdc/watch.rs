use crate::cdc::action::Action;
use crate::cdc::Transaction;
use bytes::BufMut;
use futures::{future, ready, Sink, StreamExt};
use std::task::Poll;
use std::time::{SystemTime, UNIX_EPOCH};
use tokio_postgres::{NoTls, SimpleQueryMessage};
use tokio_util::bytes;
use tokio_util::bytes::BytesMut;

static MICROSECONDS_FROM_UNIX_EPOCH_TO_2000: u128 = 946_684_800_000_000;

pub async fn watch(org_name: String, tx: channel::Sender<Transaction>) {
    let db_url = std::env::var("DB_URL").unwrap();
    let conn_uri = format!("{}/{}?replication=database", db_url, org_name);

    // connect to the database
    let (client, connection) = tokio_postgres::connect(&conn_uri, NoTls).await.unwrap();

    tokio::spawn(connection);

    let slot_name = "slot_".to_owned()
        + &SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis()
            .to_string();
    let slot_query = format!(
        "CREATE_REPLICATION_SLOT {} TEMPORARY LOGICAL \"wal2json\"",
        slot_name
    );

    let lsn = client
        .simple_query(&slot_query)
        .await
        .unwrap()
        .into_iter()
        .filter_map(|msg| match msg {
            SimpleQueryMessage::Row(row) => Some(row),
            _ => None,
        })
        .collect::<Vec<_>>()
        .first()
        .unwrap()
        .get("consistent_point")
        .unwrap()
        .to_owned();

    let query = format!(
        "START_REPLICATION SLOT {} LOGICAL {} (\"format-version\" '2')",
        slot_name, lsn
    );
    let duplex_stream = client
        .copy_both_simple::<bytes::Bytes>(&query)
        .await
        .unwrap();
    let mut duplex_stream_pin = Box::pin(duplex_stream);

    // see here for format details: https://www.postgresql.org/docs/current/protocol-replication.html
    let mut keepalive = BytesMut::with_capacity(34);
    keepalive.put_u8(b'r');
    // the last 8 bytes of these are overwritten with a timestamp to meet the protocol spec
    keepalive.put_bytes(0, 32);
    keepalive.put_u8(1);

    // set the timestamp of the keepalive message
    keepalive[26..34].swap_with_slice(
        &mut ((SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_micros()
            - MICROSECONDS_FROM_UNIX_EPOCH_TO_2000) as u64)
            .to_be_bytes(),
    );

    // send the keepalive to ensure connection is functioning
    future::poll_fn(|cx| {
        ready!(duplex_stream_pin.as_mut().poll_ready(cx)).unwrap();
        duplex_stream_pin
            .as_mut()
            .start_send(keepalive.clone().into())
            .unwrap();
        ready!(duplex_stream_pin.as_mut().poll_flush(cx)).unwrap();
        Poll::Ready(())
    })
    .await;

    let mut transaction: Option<Transaction> = None;
    loop {
        match duplex_stream_pin.as_mut().next().await {
            None => break,
            Some(Err(_)) => continue,
            // type: XLogData (WAL data, ie. change of data in db)
            Some(Ok(event)) if event[0] == b'w' => {
                //println!("Got XLogData/data-change event");
                //let v: serde_json::Value = serde_json::from_slice(&event[25..]).unwrap();
                //println!("{}", serde_json::to_string(&v).unwrap());

                let action: Action = serde_json::from_slice(&event[25..]).unwrap();
                match action {
                    Action::Begin => {
                        transaction = Some(Transaction {
                            xid: None,
                            commit_time: None,
                            events: vec![],
                        })
                    }
                    Action::Commit => {
                        if let Some(txn) = transaction.take() {
                            tx.send(txn).await.unwrap();
                        }
                    }
                    _ => {
                        transaction.as_mut().unwrap().events.push(action);
                    }
                }
            }
            // type: keepalive message
            Some(Ok(event)) if event[0] == b'k' => {
                let last_byte = event.last().unwrap();
                let timeout_imminent = last_byte == &1;
                // println!(
                //     "Got keepalive message:{:x?} @timeoutImminent:{}",
                //     event,
                //     timeout_imminent
                // );
                if timeout_imminent {
                    keepalive[26..34].swap_with_slice(
                        &mut ((SystemTime::now()
                            .duration_since(UNIX_EPOCH)
                            .unwrap()
                            .as_micros()
                            - MICROSECONDS_FROM_UNIX_EPOCH_TO_2000)
                            as u64)
                            .to_be_bytes(),
                    );

                    //println!(
                    //    "Trying to send response to keepalive message/warning!:{:x?}",
                    //    keepalive
                    //);
                    future::poll_fn(|cx| {
                        ready!(duplex_stream_pin.as_mut().poll_ready(cx)).unwrap();
                        duplex_stream_pin
                            .as_mut()
                            .start_send(keepalive.clone().into())
                            .unwrap();
                        ready!(duplex_stream_pin.as_mut().poll_flush(cx)).unwrap();
                        Poll::Ready(())
                    })
                    .await;

                    //println!(
                    //    "Sent response to keepalive message/warning!:{:x?}",
                    //    keepalive
                    //);
                }
            }
            _ => (),
        }
    }
}
