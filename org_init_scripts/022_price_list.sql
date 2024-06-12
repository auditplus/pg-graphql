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
create type typ_price_apply_on as enum ('ALL_INVENTORY', 'INVENTORY', 'CATEGORY', 'TAG', 'BATCH');
--##
create type typ_price_computation as enum ('FIXED_PRICE', 'DISCOUNT', 'LANDING_COST', 'NLC');
--##
create table if not exists price_list_condition
(
    id             int                   not null generated always as identity primary key,
    apply_on       typ_price_apply_on    not null,
    computation    typ_price_computation not null,
    priority       int                   not null default 999,
    price_list_id  int                   not null,
    min_qty        float                 not null default 0,
    min_value      float                 not null default 0,
    value          float                 not null,
    include_rate   bool                  not null default true,
    branch_id      int,
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
    batches        int[]
);
--##
create function inventory_tags(price_list_condition)
    returns setof tag as
$$
begin
    return query
        select * from tag where id = any ($1.inventory_tags);
end
$$ language plpgsql immutable;