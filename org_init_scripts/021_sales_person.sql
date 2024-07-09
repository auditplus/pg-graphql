create table if not exists sales_person
(
    code       text      not null primary key,
    name       text      not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint code_min_length check (char_length(trim(code)) > 0),
    constraint code_invalid check ((code ~ '^[A-Z0-9_]*$') and (char_length(trim(code)) > 0))
);
--##
create trigger sync_sales_person_updated_at
    before update
    on sales_person
    for each row
execute procedure sync_updated_at();