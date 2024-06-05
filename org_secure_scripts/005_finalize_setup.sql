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
--##
create or replace function branches(member)
    returns setof branch as
$$
begin
    return query
    select * from branch where (case when $1.is_root then true else $1.id = any(members) end);

end
$$ language plpgsql immutable;
--##
create or replace function voucher_types(member)
    returns setof voucher_type as
$$
declare
    mem_arr jsonb := jsonb_build_array(json_build_object('member',$1.id));
begin
    return query
    select * from voucher_type where members is null or members @> mem_arr;
end
$$ language plpgsql immutable;
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
--##
create or replace function salts(inventory)
    returns setof pharma_salt as
$$
begin
    return query
    select * from pharma_salt where id = any($1.salts);
end
$$ language plpgsql immutable;
--##
create or replace function tags(inventory)
    returns setof tag as
$$
begin
    return query
    select * from tag where id = any($1.tags);
end
$$ language plpgsql immutable;
--##
create or replace function category1(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category1);
end
$$ language plpgsql immutable;
--##
create or replace function category2(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category2);
end
$$ language plpgsql immutable;
--##
create or replace function category3(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category3);
end
$$ language plpgsql immutable;
--##
create or replace function category4(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category4);
end
$$ language plpgsql immutable;
--##
create or replace function category5(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category5);
end
$$ language plpgsql immutable;
--##
create or replace function category6(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category6);
end
$$ language plpgsql immutable;
--##
create or replace function category7(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category7);
end
$$ language plpgsql immutable;
--##
create or replace function category8(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category8);
end
$$ language plpgsql immutable;
--##
create or replace function category9(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category9);
end
$$ language plpgsql immutable;
--##
create or replace function category10(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category10);
end
$$ language plpgsql immutable;
--##