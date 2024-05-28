create table if not exists offer_management
(
    id         int       not null generated always as identity primary key,
    name       text      not null,
    conditions jsonb     not null,
    rewards    jsonb     not null,
    branch     int,
    price_list int,
    start_date date,
    end_date   date,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
--##
create trigger sync_offer_management_updated_at
    before update
    on offer_management
    for each row
execute procedure sync_updated_at();