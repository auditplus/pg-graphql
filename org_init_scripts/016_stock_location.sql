create table if not exists stock_location
(
    id         int       not null generated always as identity primary key,
    name       text      not null
        constraint stock_location_name_min_length check (char_length(trim(name)) > 0),
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
--##
create trigger sync_stock_location_updated_at
    before update
    on stock_location
    for each row
execute procedure sync_updated_at();