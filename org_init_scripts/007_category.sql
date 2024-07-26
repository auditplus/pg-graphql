create table if not exists category
(
    id            text      not null primary key,
    name          text      not null,
    category_type text      not null,
    active        boolean   not null default false,
    sort_order    smallint  not null,
    sno           smallint  not null,
    category      text,
    updated_at    timestamp not null default current_timestamp,
    unique (id, category),
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint category_type_invalid check (check_category_type(category_type))
);
--##
create trigger sync_category_updated_at
    before update
    on category
    for each row
execute procedure sync_updated_at();