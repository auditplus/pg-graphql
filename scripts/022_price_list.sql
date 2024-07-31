create table if not exists price_list
(
    id              int       not null generated always as identity primary key,
    name            text      not null,
    customer_tag_id int,
    created_at      timestamp not null default current_timestamp,
    updated_at      timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_price_list_updated_at
    before update
    on price_list
    for each row
execute procedure sync_updated_at();
--##
create table if not exists price_list_condition
(
    id             int       not null generated always as identity primary key,
    apply_on       text      not null,
    computation    text      not null,
    priority       int               not null default 999,
    price_list_id  int            not null,
    min_qty        float             not null default 0,
    min_value      float             not null default 0,
    value          float             not null,
    include_rate   bool              not null default false,
    branches       int[],
    inventory_id   int,
    category1_id   int,
    category2_id   int,
    category3_id   int,
    category4_id   int,
    category5_id   int,
    category6_id   int,
    category7_id   int,
    category8_id   int,
    category9_id   int,
    category10_id  int,
    inventory_tags int[],
    batches        int[],
    updated_at     timestamp not null default current_timestamp,
    constraint apply_on_invalid check (check_price_apply_on(apply_on)),
    constraint computation_invalid check (check_price_computation(computation))
);
--##
create trigger sync_price_list_condition_updated_at
    before update
    on price_list_condition
    for each row
execute procedure sync_updated_at();