create type typ_cat_type as enum ('ACCOUNT', 'INVENTORY');
--##
create table if not exists category
(
    id            text         not null primary key,
    name          text         not null
        constraint category_name_min_length check (char_length(trim(name)) > 0),
    category_type typ_cat_type not null,
    active        boolean      not null default false,
    sort_order    smallint     not null,
    sno           smallint     not null,
    category      text,
    updated_at    timestamp    not null default current_timestamp,
    unique (id, category)
);
--##
create trigger sync_category_updated_at
    before update
    on category
    for each row
execute procedure sync_updated_at();