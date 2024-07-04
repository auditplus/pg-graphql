create table if not exists price_list
(
    id              bigserial not null primary key,
    name            text      not null,
    customer_tag_id bigint,
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
create domain price_apply_on as text
    check (value in ('ALL_INVENTORY', 'INVENTORY', 'CATEGORY', 'TAG', 'BATCH'));
--##
create domain price_computation as text
    check (value in ('FIXED_PRICE', 'DISCOUNT', 'LANDING_COST', 'NLC'));
--##
create table if not exists price_list_condition
(
    id             bigserial         not null primary key,
    apply_on       price_apply_on    not null,
    computation    price_computation not null,
    priority       int               not null default 999,
    price_list_id  bigint            not null,
    min_qty        float             not null default 0,
    min_value      float             not null default 0,
    value          float             not null,
    include_rate   bool              not null default true,
    branch_id      bigint,
    inventory_id   bigint,
    category1_id   bigint,
    category2_id   bigint,
    category3_id   bigint,
    category4_id   bigint,
    category5_id   bigint,
    category6_id   bigint,
    category7_id   bigint,
    category8_id   bigint,
    category9_id   bigint,
    category10_id  bigint,
    inventory_tags bigint[],
    batches        bigint[]
);
