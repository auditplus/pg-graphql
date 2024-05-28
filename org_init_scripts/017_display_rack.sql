create table if not exists display_rack
(
    id         int       not null generated always as identity primary key,
    name       text      not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
--##
create trigger sync_display_rack_updated_at
    before update
    on display_rack
    for each row
execute procedure sync_updated_at();