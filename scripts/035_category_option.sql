create table if not exists category_option
(
    id            int       not null generated always as identity primary key,
    category_id   text      not null,
    category_name text      not null,
    name          text      not null,
    active        boolean   not null default true,
    updated_at    timestamp not null default current_timestamp,
    unique (category_id, name),
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create function tgf_sync_category_option_catname_at()
    returns trigger as
$$
begin
    select x.category into new.category_name from category as x where x.id = new.category_id;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger tg_sync_category_option_catname_at
    before insert or update
    on category_option
    for each row
execute procedure tgf_sync_category_option_catname_at();
--##
create view vw_category_option_detail as
select a.id, a.name, (select b.category from category b where id = a.category_id) as category
from category_option a;
--##
create function fetch_categories(json)
    returns json
as
$$
declare
    _ids        int[]                       := (select array_agg(value)::int[]
                                                from json_each_text($1));
    _categories vw_category_option_detail[] := (select array_agg(a)
                                                from vw_category_option_detail a
                                                where a.id = any (_ids));
    _category   vw_category_option_detail;
    _out        json                        = '{}'::json;
    _key        text;
    _val        int;
begin
    foreach _category in array coalesce(_categories, array []::vw_category_option_detail[])
        loop
            for _key, _val in select * from json_each_text($1)
                loop
                    if _val = _category.id then
                        _out = jsonb_insert(_out::jsonb, array [_key], row_to_json(_category)::jsonb);
                    end if;
                end loop;
        end loop;
    return _out::json;
end;
$$ language plpgsql security definer;
--##
create function fetch_categories_many(json)
    returns json as
$$
declare
    _ids            int[]                       := (select array_agg(x.id)
                                                    from (select unnest(translate(value, '[]', '{}')::int[]) as id
                                                          from json_each_text($1)) as x);
    _categories     vw_category_option_detail[] := (select array_agg(a)
                                                    from vw_category_option_detail a
                                                    where a.id = any (_ids));
    _key            text;
    _val            int[];
    _categories_val jsonb;
    _out            json                        = '{}';
begin
    for _key, _val in select key, translate(value, '[]', '{}') from json_each_text($1)
        loop
            select jsonb_agg(x.*) into _categories_val from unnest(_categories) x where x.id = any (_val);
            if _categories_val is not null then
                _out = jsonb_insert(_out::jsonb, array [_key], _categories_val);
            end if;
        end loop;
    return _out;
end;
$$ language plpgsql security definer;
