create table if not exists member_role
(
    name       text      not null primary key,
    perms  int[],
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_invalid check (char_length(trim(name)) > 0 )
);
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
    name          text      not null unique,
    pass          text      not null,
    remote_access boolean   not null default false,
    is_root       boolean   not null default false,
    settings      json      not null default '{"theme": "light"}'::json,
    user_id       text unique,
    role          text      not null,
    -- perms      text[], -use it for resolver function
    nick_name     text,
    branches      text,
    voucher_types text,
    created_at    timestamp not null default current_timestamp,
    updated_at    timestamp not null default current_timestamp,
    constraint name_invalid check (name ~ '^[a-zA-Z0-9_]*$' and char_length(name) > 0 )
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
    my_name text := (select x::json->>'name' from current_setting('my.claims') x);
    mem member;
begin
    select * into mem from member where name = my_name;
    mem.pass = null;
    return mem;
end;
$$ language plpgsql immutable security definer;
--##
create function authenticate(token text) returns json
    security definer
    language plpgsql
as
$$
declare
    claims json := (select payload from addon.verify(token, current_setting('app.env.jwt_secret_key')));
begin
    return claims;
end;
$$;
--##
create function login(username text, password text) returns json
    immutable
    security definer
    language plpgsql
as
$$
declare
    mem member;
    token text;
    payload json;
    jwt_secret_key text := current_setting('app.env.jwt_secret_key');
begin
    select * into mem from member where name=username;
    if (mem.pass = password) then
        payload = json_build_object('id', mem.id,'name', mem.name, 'is_root', mem.is_root, 'role', mem.role,
        'org', current_database(), 'isu', current_timestamp, 'exp', current_timestamp+'1d'::interval);
        select addon.sign(payload, jwt_secret_key) into token;
    else
        raise exception 'invalid credential';
    end if;
    return json_build_object('claims', payload, 'token', token);
end;
$$;
