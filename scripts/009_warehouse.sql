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
    state_id   text,
    country_id text,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger tg_sync_warehouse_updated_at
    before update
    on warehouse
    for each row
execute procedure tgf_sync_updated_at();