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
create trigger tg_sync_offer_management_updated_at
    before update
    on offer_management
    for each row
execute procedure tgf_sync_updated_at();