create table if not exists tag
(
    id         bigserial not null primary key,
    name       text      not null unique,
    updated_at timestamp not null default current_timestamp,
    constraint name_invalid check (name ~ '^[a-zA-Z0-9]*$' and char_length(name) > 0)
);
--##
create trigger sync_tag_updated_at
    before update
    on tag
    for each row
execute procedure sync_updated_at();