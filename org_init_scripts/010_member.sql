create table if not exists member
(
    id            int       not null generated always as identity primary key,
    name          text      not null unique,
    pass          text      not null,
    remote_access boolean   not null default false,
    is_root       boolean   not null default false,
    settings      json      not null default '{"theme": "light"}'::json,
    perms         text[],
    user_id       text unique,
    nick_name     text,
    created_at    timestamp not null default current_timestamp,
    updated_at    timestamp not null default current_timestamp
);
--##
create trigger sync_member_updated_at
    before update
    on member
    for each row
execute procedure sync_updated_at();