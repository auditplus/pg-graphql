create table if not exists offer_management
(
    id            int       not null generated always as identity primary key,
    name          text      not null
        constraint offer_management_name_min_length check (char_length(trim(name)) > 0),
    conditions    jsonb     not null,
    rewards       jsonb     not null,
    branch_id     int,
    price_list_id int,
    start_date    date,
    end_date      date,
    created_at    timestamp not null default current_timestamp,
    updated_at    timestamp not null default current_timestamp
);
--##
create trigger sync_offer_management_updated_at
    before update
    on offer_management
    for each row
execute procedure sync_updated_at();