create table if not exists manufacturer
(
    id         int       not null generated always as identity primary key,
    name       text      not null,
    mobile     text,
    email      text,
    telephone  text,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
--##
create trigger sync_manufacturer_updated_at
    before update
    on manufacturer
    for each row
execute procedure sync_updated_at();