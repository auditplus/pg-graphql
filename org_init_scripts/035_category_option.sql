create table if not exists category_option
(
    id          bigserial not null primary key,
    category_id text      not null,
    name        text      not null,
    active      boolean   not null default true,
    updated_at  timestamp not null default current_timestamp,
    unique (category_id, name),
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_category_option_updated_at
    before update
    on category_option
    for each row
execute procedure sync_updated_at();
