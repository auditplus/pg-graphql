create table if not exists tag
(
    id         int       not null generated always as identity primary key,
    name       text      not null unique
        constraint tag_name_invalid check (name ~ '^[a-zA-Z0-9]*$' and char_length(name) > 0),
    updated_at timestamp not null default current_timestamp
);
--##
create trigger sync_tag_updated_at
    before update
    on tag
    for each row
execute procedure sync_updated_at();