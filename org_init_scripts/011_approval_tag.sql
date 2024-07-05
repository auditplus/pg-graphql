create table if not exists approval_tag
(
    id         bigserial not null primary key,
    name       text      not null,
    members    bigint[]     not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_approval_tag_updated_at
    before update
    on approval_tag
    for each row
execute procedure sync_updated_at();