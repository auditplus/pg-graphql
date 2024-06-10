create type typ_cat_type as enum ('ACCOUNT', 'INVENTORY');
--##
create table if not exists category
(
    id            text         not null primary key,
    name          text         not null,
    category_type typ_cat_type not null,
    active        boolean      not null default false,
    sort_order    smallint     not null,
    sno           smallint     not null,
    category      text,
    updated_at    timestamp    not null default current_timestamp,
    unique (id, category),
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_category_updated_at
    before update
    on category
    for each row
execute procedure sync_updated_at();
--##
create or replace function category_bulk_update(input json)
returns setof category
as
$$
begin

    with s1 as (
        select (x->>'id')::text as id, 
            (x->>'category')::text as category, 
            (x->>'active')::bool as active, 
            (x->>'sno')::int as sno 
        from json_array_elements(input) as x
    )
    update category as c
    set category=s1.category, active=coalesce(s1.active,false), sno=coalesce(s1.sno,c.sno)
    from s1
    where c.id=s1.id;

    return query
    select * 
    from category 
    order by category_type,sort_order;
end;
$$ language plpgsql security definer;