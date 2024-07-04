create table if not exists sale_incharge
(
    id         bigserial not null primary key,
    name       text      not null,
    code       text      not null unique,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint code_min_length check (char_length(trim(code)) > 0)
);
--##
create trigger sync_sale_incharge_updated_at
    before update
    on sale_incharge
    for each row
execute procedure sync_updated_at();