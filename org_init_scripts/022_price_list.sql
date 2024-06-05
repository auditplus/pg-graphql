create table if not exists price_list
(
    id              int       not null generated always as identity primary key,
    name            text      not null
        constraint price_list_name_min_length check (char_length(trim(name)) > 0),
    customer_tag_id int,
    list            jsonb,
    created_at      timestamp not null default current_timestamp,
    updated_at      timestamp not null default current_timestamp
);
--##
create trigger sync_price_list_updated_at
    before update
    on price_list
    for each row
execute procedure sync_updated_at();