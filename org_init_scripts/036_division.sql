create table if not exists division
(
    id         bigserial not null primary key,
    name       text      not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_division_updated_at
    before update
    on division
    for each row
execute procedure sync_updated_at();