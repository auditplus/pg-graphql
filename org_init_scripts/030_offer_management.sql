create table if not exists offer_management
(
    id            bigserial not null primary key,
    name          text      not null,
    conditions    jsonb     not null,
    rewards       jsonb     not null,
    branch_id     bigint,
    price_list_id bigint,
    start_date    date,
    end_date      date,
    created_at    timestamp not null default current_timestamp,
    updated_at    timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_offer_management_updated_at
    before update
    on offer_management
    for each row
execute procedure sync_updated_at();
--##
create table if not exists offer_management_condition
(
    id             bigserial      not null primary key,
    apply_on       price_apply_on not null,
    min_qty        float,
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
--##
create domain offer_reward_type as text
    check (value in ('FREE', 'DISCOUNT'));
--##
create table if not exists offer_management_reward
(
    id             bigserial         not null primary key,
    apply_on       price_apply_on    not null,
    reward_type    offer_reward_type not null,
    reward_qty     float,
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