create table if not exists category_option
(
    id          int       not null generated always as identity primary key,
    category_id text      not null,
    name        text      not null
        constraint category_option_name_min_length check (char_length(trim(name)) > 0),
    active      boolean   not null default true,
    updated_at  timestamp not null default current_timestamp,
    unique (category_id, name)
);
--##
create trigger sync_category_option_updated_at
    before update
    on category_option
    for each row
execute procedure sync_updated_at();
--##
create or replace function category1(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category1);
end
$$ language plpgsql immutable;
--##
create or replace function category2(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category2);
end
$$ language plpgsql immutable;
--##
create or replace function category3(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category3);
end
$$ language plpgsql immutable;
--##
create or replace function category4(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category4);
end
$$ language plpgsql immutable;
--##
create or replace function category5(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category5);
end
$$ language plpgsql immutable;