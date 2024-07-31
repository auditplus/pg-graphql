create table if not exists approval_tag
(
    id         int       not null generated always as identity primary key,
    name       text      not null,
    members    int[]     not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger tg_sync_approval_tag_updated_at
    before update
    on approval_tag
    for each row
execute procedure tgf_sync_updated_at();