create table if not exists gst_tax
(
    id   text  not null primary key,
    name text  not null,
    cgst float not null default 0,
    sgst float not null default 0,
    igst float not null default 0
);