create or replace procedure pre_setup() as
$$
begin
    create schema graphql;
    create schema addon;
    create schema heck;

    create extension pgcrypto with schema addon;
    create extension pgjwt with schema addon;
    create extension http with schema addon;

    create extension pg_heck with schema heck;

    create extension pg_graphql with schema graphql;
    comment on schema public is e'@graphql({"max_rows": 100, "inflect_names": true})';

end
$$ language plpgsql security definer;
--##
call pre_setup();
--##
create function sync_updated_at()
    returns trigger as
$$
begin
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql;
--##
create function sync_inv_item_delete()
    returns trigger as
$$
begin
    delete from inv_txn where id = old.id;
    return old;
end;
$$ language plpgsql;
--##
create domain voucher_mode as text
check (value in ('ACCOUNT', 'GST', 'INVENTORY'));
--##
--utils
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
