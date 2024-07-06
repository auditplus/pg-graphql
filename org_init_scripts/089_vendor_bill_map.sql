create table if not exists vendor_bill_map
(
    vendor_id     int    not null primary key,
    start_row     int    not null,
    name          text   not null,
    unit          text   not null,
    qty           text   not null,
    mrp           text   not null,
    rate          text   not null,
    free          text,
    batch_no      text,
    expiry        text,
    expiry_format text,
    discount      text
);