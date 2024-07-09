create table if not exists member_role
(
    name       text      not null primary key,
    perms      text[],
    ui_perms   json,
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
create trigger sync_member_updated_at
    before update
    on member
    for each row
execute procedure sync_updated_at();
--##
create view member_profile as
select id,
       name,
       remote_access,
       is_root,
       (select ui_perms from member_role b where name = member.role_id)                                    as ui_perms,
       (select json_agg(json_build_object('id', branch.id, 'name', branch.name, 'mobile', branch.mobile,
                                          'alternate_mobile', branch.alternate_mobile, 'email', branch.email,
                                          'telephone', branch.telephone, 'contact_person', branch.contact_person))
        from branch
        where (case when member.is_root then true else member.id = any (members) end))                     as branches,
       (select json_agg(json_build_object('id', voucher_type.id, 'name', voucher_type.name, 'base_type',
                                          voucher_type.base_type))
        from voucher_type
        where (case
                   when member.is_root then true
                   else members is null or members @>
                                           jsonb_build_array(json_build_object('member', member.id)) end)) as voucher_types,
       settings
from member
where id = (current_setting('my.claims')::json->>'id')::int;
--##
comment on view member_profile is e'@graphql({"primary_key_columns": ["id"]})';
--##
create function authenticate(token text) returns json
    security definer
    language plpgsql
as
$$
declare
    claims json := (select payload
                    from addon.verify(token, (current_setting('app.env')::json) ->> 'jwt_private_key'));
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
    mem            member;
    token          text;
    payload        json;
    jwt_secret_key text := (select (x::json) ->> 'jwt_private_key'
                            from current_setting('app.env') x);
begin
    select * into mem from member where lower(name) = lower(username);
    if (mem.pass = password) then
        payload = json_build_object('id', mem.id, 'name', mem.name, 'is_root', mem.is_root, 'role', mem.role_id,
                                    'org', current_database(), 'isu', current_timestamp, 'exp',
                                    current_timestamp + '1d'::interval);
        select addon.sign(payload, jwt_secret_key) into token;
    else
        raise exception 'invalid credential';
    end if;
    return json_build_object('claims', payload, 'token', token);
end;
$$;
