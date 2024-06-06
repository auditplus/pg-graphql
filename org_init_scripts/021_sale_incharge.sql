create table if not exists sale_incharge
(
    id         int       not null generated always as identity primary key,
    name       text      not null
        constraint sale_incharge_name_min_length check (char_length(trim(name)) > 0),
    code       text      not null unique
        constraint sale_incharge_code_min_length check (char_length(trim(code)) > 0),
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
--##
create trigger sync_sale_incharge_updated_at
    before update
    on sale_incharge
    for each row
execute procedure sync_updated_at();