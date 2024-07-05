create table if not exists offer_management
(
    id            int       not null generated always as identity primary key,
    name          text      not null,
    conditions    jsonb     not null,
    rewards       jsonb     not null,
    branch_id     int,
    price_list_id int,
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
    id             int       not null generated always as identity primary key,
    apply_on       price_apply_on not null,
    min_qty        float,
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
create domain offer_reward_type as text
    check (value in ('FREE', 'DISCOUNT'));
--##
create table if not exists offer_management_reward
(
    id             int       not null generated always as identity primary key,
    apply_on       price_apply_on    not null,
    reward_type    offer_reward_type not null,
    reward_qty     float,
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