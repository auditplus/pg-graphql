create or replace function authenticate(token text)
returns json
as
$$
declare
    claims json := (select payload from addon.verify(token, 'secret'));
begin
    perform set_config('my.id', (claims->>'id'), true);
    perform set_config('my.name', (claims->>'name'), true);
    perform set_config('my.is_root', (claims->>'is_root'), true);
    return claims;
end;
$$ language plpgsql;
--##
create or replace function login(username text, password text)
    returns text as
$$
declare
    mem member;
    token text;
    payload json;
begin
    select * into mem from member where name=username;
    if (mem.pass = password) then
        payload = json_build_object('id', mem.id,'name', mem.name, 'is_root', mem.is_root);
        select addon.sign(payload, 'secret') into token;
    else
        raise exception 'invalid credential';
    end if;
    return token;
end;
$$ language plpgsql immutable security definer;
