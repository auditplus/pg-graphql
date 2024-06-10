create table if not exists member_role
(
    id         int       not null generated always as identity primary key,
    name       text      not null
        constraint member_role_name_invalid check (char_length(trim(name)) > 0 ),
    perms      text[],
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
--##
create or replace function permissions(member_role)
    returns setof permission as
$$
begin
    return query
    select * from permission where id = any($1.perms);
end
$$ language plpgsql immutable;
--##
create function sync_member_role()
    returns trigger as
$$
declare
    count int := (select count(1)::int
                  from permission
                  where id = any (new.perms));
begin
    if array_length(new.perms, 1) <> count then
        raise exception 'Invalid permission';
    end if;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql;
--##
create trigger sync_member_role_at
    before insert or update
    on member_role
    for each row
execute procedure sync_member_role();
--##
create table if not exists member
(
    id            int       not null generated always as identity primary key,
    name          text      not null unique
        constraint member_name_invalid check (name ~ '^[a-zA-Z0-9_]*$' and char_length(name) > 0 ),
    pass          text      not null,
    remote_access boolean   not null default false,
    is_root       boolean   not null default false,
    settings      json      not null default '{"theme": "light"}'::json,
    user_id       text unique,
    role_id       int not null,
    nick_name     text,
    branches      text,
    voucher_types text,
    created_at    timestamp not null default current_timestamp,
    updated_at    timestamp not null default current_timestamp
);
--##
create trigger sync_member_updated_at
    before update
    on member
    for each row
execute procedure sync_updated_at();
--##
create or replace function member_profile()
    returns member as
$$
declare
    my_name text := current_setting('my.name');
    mem member;
begin
    select * into mem from member where name = my_name;
    mem.pass = null;
    return mem;
end;
$$ language plpgsql immutable security definer;