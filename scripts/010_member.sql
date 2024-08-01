create table if not exists member_role
(
    name       text      not null primary key,
    perms      text[],
    ui_perms   json,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_invalid check (name ~ '^[a-zA-Z0-9_]*$' and char_length(name) > 0 )
);
--##
create function tgf_sync_member_role()
    returns trigger as
$$
declare
    count int := (select count(1)::int
                  from permission
                  where id = any (new.perms));
begin
    if array_length(new.perms, 1) <> count then
        raise exception 'Some of the given permissions are invalid';
    end if;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql;
--##
create trigger tg_sync_member_role_at
    before insert or update
    on member_role
    for each row
execute procedure tgf_sync_member_role();
--##
create table if not exists member
(
    id            int       not null generated always as identity primary key,
    name          text      not null unique,
    pass          text      not null,
    remote_access boolean   not null default false,
    is_root       boolean   not null default false,
    settings      json      not null default '{
      "theme": "light"
    }'::json,
    user_id       text unique,
    role_id       text      not null,
    nick_name     text,
    created_at    timestamp not null default current_timestamp,
    updated_at    timestamp not null default current_timestamp,
    constraint name_invalid check (name ~ '^[a-zA-Z0-9_]*$' and char_length(name) > 0 )
);
--##
create trigger tg_sync_member_updated_at
    before update
    on member
    for each row
execute procedure tgf_sync_updated_at();
--##
create function tgf_enc_member_pass()
    returns trigger as
$$
declare
    jwt_private_key text := ((current_setting('app.env')::json) ->> 'jwt_private_key')::text;
begin
    if new.pass<>old.pass or old.pass is null then
        new.pass = addon.encrypt(concat(new.pass,'#$#',current_timestamp)::bytea, jwt_private_key::bytea, 'aes')::text;
    end if;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger tg_enc_member_pass
    before insert or update
    on member
    for each row
execute procedure tgf_enc_member_pass();
--##
create view vw_member_condensed
as
select id, name, remote_access, is_root, updated_at
from member;
--##
create function authenticate(token text) returns json
    security definer
    language plpgsql
as
$$
declare
    claims json := (select payload
                    from addon.verify(token, (current_setting('app.env')::json) ->> 'jwt_private_key'));
    org text := current_database();
begin
    if org!=(claims->>'org')::text then
        raise exception 'Invalid organization';
    end if;
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
    mem            member;
    mem_pass       text;
    token          text;
    payload        json;
    jwt_secret_key text := (select (x::json) ->> 'jwt_private_key'
                            from current_setting('app.env') x);
begin
    select * into mem from member where lower(name) = lower(username);
    mem_pass = split_part((select convert_from(addon.decrypt(mem.pass::bytea, jwt_secret_key::bytea, 'aes'), 'SQL_ASCII')),'#$#',1)::text;
    if (mem_pass = password) then
        payload = json_build_object('id', mem.id, 'name', mem.name, 'is_root', mem.is_root, 'role', mem.role_id,
                                    'org', current_database(), 'claim_type', 'Member',
                                    'isu', current_timestamp, 'exp', current_timestamp + '1d'::interval);
        select addon.sign(payload, jwt_secret_key) into token;
    else
        raise exception 'invalid credential';
    end if;
    return json_build_object('claims', payload, 'token', token);
end;
$$;
