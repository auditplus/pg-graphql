create type typ_org_status as enum ('ACTIVE', 'SUSPENDED', 'DEACTIVATED');
--##
create table if not exists organization
(
    name       text           not null primary key,
    full_name  text           not null,
    country    text           not null,
    book_begin date           not null,
    fp_code    int            not null,
    status     typ_org_status not null,
    owned_by   text           not null,
    gst_no     text
);