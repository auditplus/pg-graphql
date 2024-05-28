create table if not exists warehouse
(
    id         int       not null generated always as identity primary key,
    name       text      not null,
    mobile     text,
    email      text,
    telephone  text,
    address    text,
    city       text,
    pincode    text,
    state      text,
    country    text,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
--##
create trigger sync_warehouse_updated_at
    before update
    on warehouse
    for each row
execute procedure sync_updated_at();