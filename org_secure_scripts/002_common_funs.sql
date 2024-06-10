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
    perform set_config('my.org', (claims->>'org'), true);
    --need to check claims->>'exp'
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
        payload = json_build_object('id', mem.id,'name', mem.name, 'is_root', mem.is_root,
        'org', current_database(), 'isu', current_timestamp, 'exp', current_timestamp+'1d'::interval);
        select addon.sign(payload, 'secret') into token;
    else
        raise exception 'invalid credential';
    end if;
    return token;
end;
$$ language plpgsql immutable security definer;
--##
create or replace function json_convert_case(input jsonb, word_case text) returns jsonb as
$$
declare
    input_type text := jsonb_typeof(input);
    out        jsonb;
    _key       text;
    _value     jsonb;
    _item      jsonb;
    _converted text;
begin
    if input_type = 'object' then
        out = '{}';
        for _key, _value in
            select * from jsonb_each($1)
            loop
                _value = json_convert_case(_value, word_case);
                if word_case = 'snake_case' then
                    _converted = heck.to_snake_case(_key);
                elseif word_case = 'lower_camel_case' then
                    _converted = heck.to_lower_camel_case(_key);
                end if;
                out = jsonb_insert(out, format('{%s}', _converted)::text[], _value, true);
            end loop;
    elseif input_type = 'array' then
         out = '[]'::jsonb;
        for _item in select jsonb_array_elements(input)
        loop
            out = jsonb_insert(out, '{0}', json_convert_case(_item::jsonb, word_case), true);
        end loop;
    else
        out = input;
    end if;
    return out;
end
$$ language plpgsql;