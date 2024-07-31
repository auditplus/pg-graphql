create table if not exists stock_location
(
    name       text      not null primary key,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger tg_sync_stock_location_updated_at
    before update
    on stock_location
    for each row
execute procedure tgf_sync_updated_at();