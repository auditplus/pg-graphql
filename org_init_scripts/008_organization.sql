create domain org_status as text
check (value in ('ACTIVE', 'SUSPENDED', 'DEACTIVATED'));
--##
create table if not exists organization
(
    name       text           not null primary key,
    full_name  text           not null,
    country    text           not null,
    book_begin date           not null,
    fp_code    int            not null,
    status     org_status     not null,
    owned_by   text           not null,
    gst_no     text,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint full_name_min_length check (char_length(trim(full_name)) > 0)
);