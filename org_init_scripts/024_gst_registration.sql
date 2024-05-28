create type typ_gst_reg_type as enum ('REGULAR', 'COMPOSITE', 'UNREGISTERED', 'IMPORT_EXPORT', 'SPECIAL_ECONOMIC_ZONE');
--##
create table if not exists gst_registration
(
    id                 int              not null generated always as identity primary key,
    reg_type           typ_gst_reg_type not null default 'REGULAR',
    gst_no             text             not null unique,
    state              text             not null,
    username           text,
    email              text,
    e_invoice_username text,
    e_password         text,
    created_at         timestamp        not null default current_timestamp,
    updated_at         timestamp        not null default current_timestamp
);
--##
create trigger sync_gst_registration_updated_at
    before update
    on gst_registration
    for each row
execute procedure sync_updated_at();