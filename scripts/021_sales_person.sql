create table if not exists sales_person
(
    id         int       not null generated always as identity primary key,
    name       text      not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger tg_sync_sales_person_updated_at
    before update
    on sales_person
    for each row
execute procedure tgf_sync_updated_at();