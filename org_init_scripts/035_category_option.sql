create table if not exists category_option
(
    id          int       not null generated always as identity primary key,
    category_id text      not null,
    name        text      not null
        constraint category_option_name_min_length check (char_length(trim(name)) > 0),
    active      boolean   not null default true,
    updated_at  timestamp not null default current_timestamp,
    unique (category_id, name)
);
--##
create trigger sync_category_option_updated_at
    before update
    on category_option
    for each row
execute procedure sync_updated_at();