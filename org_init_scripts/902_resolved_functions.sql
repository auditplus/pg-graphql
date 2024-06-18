--010_member
drop function if exists permissions(member_role);
--##
create function permissions(member_role)
    returns setof permission as
$$
begin
    return query
    select * from permission where id = any($1.perms);
end
$$ language plpgsql immutable;
--##
drop function if exists members(branch);
--##
create function members(branch)
    returns setof member as
$$
begin
    return query
        select * from member where id = any ($1.members);
end
$$ language plpgsql immutable;
--##
--022_price_list
drop function if exists inventory_tags(price_list_condition);
--##
create function inventory_tags(price_list_condition)
    returns setof tag as
$$
begin
    return query
    select * from tag where id = any($1.inventory_tags);
end
$$ language plpgsql immutable;
--##
--030_offer_management
drop function if exists inventory_tags(offer_management_condition);
--##
create function inventory_tags(offer_management_condition)
    returns setof tag as
$$
begin
    return query
    select * from tag where id = any($1.inventory_tags);
end
$$ language plpgsql immutable;
--##
--030_offer_management
drop function if exists inventory_tags(offer_management_reward);
--##
create function inventory_tags(offer_management_reward)
    returns setof tag as
$$
begin
    return query
    select * from tag where id = any($1.inventory_tags);
end
$$ language plpgsql immutable;
--##
--027_branch
drop function if exists branches(member);
--##
create function branches(member)
    returns setof branch as
$$
begin
    return query
        select * from branch where (case when $1.is_root then true else $1.id = any (members) end);
end
$$ language plpgsql immutable;
--##
--033_desktop_client
drop function if exists branches(desktop_client);
--##
create function branches(desktop_client)
    returns setof branch as
$$
begin
    return query
    select * from branch where id = any($1.branches);
end
$$ language plpgsql immutable;
--##
--025_account
drop function if exists category1(account);
--##
create function category1(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category1);
end
$$ language plpgsql immutable;
--##
drop function if exists category2(account);
--##
create function category2(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category2);
end
$$ language plpgsql immutable;
--##
drop function if exists category3(account);
--##
create function category3(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category3);
end
$$ language plpgsql immutable;
--##
drop function if exists category4(account);
--##
create function category4(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category4);
end
$$ language plpgsql immutable;
--##
drop function if exists category5(account);
--##
create function category5(account)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category5);
end
$$ language plpgsql immutable;
--##
--039_voucher_type
drop function if exists voucher_types(member);
--##
create function voucher_types(member)
    returns setof voucher_type as
$$
declare
    is_root bool := (select (x::json->>'is_root')::bool from current_setting('my.claims') x);
    mem_arr jsonb := jsonb_build_array(json_build_object('member',$1.id));    
begin
    if is_root then
        return query
        select * from voucher_type;
    else
        return query
        select * from voucher_type where members is null or members @> mem_arr;
    end if;
end
$$ language plpgsql immutable;
--##
--040_inventory
drop function if exists salts(inventory);
--##
create function salts(inventory)
    returns setof pharma_salt as
$$
begin
    return query
    select * from pharma_salt where id = any($1.salts);
end
$$ language plpgsql immutable;
--##
drop function if exists tags(inventory);
--##
create function tags(inventory)
    returns setof tag as
$$
begin
    return query
    select * from tag where id = any($1.tags);
end
$$ language plpgsql immutable;
--##
drop function if exists vendors(inventory);
--##
create function vendors(inventory)
    returns setof vendor as
$$
begin
    return query
    select * from vendor where id = any($1.vendors);
end
$$ language plpgsql immutable;
--##
drop function if exists category1(inventory);
--##
create function category1(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category1);
end
$$ language plpgsql immutable;
--##
drop function if exists category2(inventory);
--##
create function category2(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category2);
end
$$ language plpgsql immutable;
--##
drop function if exists category3(inventory);
--##
create function category3(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category3);
end
$$ language plpgsql immutable;
--##
drop function if exists category4(inventory);
--##
create function category4(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category4);
end
$$ language plpgsql immutable;
--##
drop function if exists category5(inventory);
--##
create function category5(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category5);
end
$$ language plpgsql immutable;
--##
drop function if exists category6(inventory);
--##
create function category6(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category6);
end
$$ language plpgsql immutable;
--##
drop function if exists category7(inventory);
--##
create function category7(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category7);
end
$$ language plpgsql immutable;
--##
drop function if exists category8(inventory);
--##
create function category8(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category8);
end
$$ language plpgsql immutable;
--##
drop function if exists category9(inventory);
--##
create function category9(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category9);
end
$$ language plpgsql immutable;
--##
drop function if exists category10(inventory);
--##
create function category10(inventory)
    returns setof category_option as
$$
begin
    return query
    select * from category_option where id = any($1.category10);
end
$$ language plpgsql immutable;
--##
drop function if exists conditions(offer_management);
--##
create function conditions(offer_management)
    returns setof offer_management_condition as
$$
begin
    return query
        select *
        from jsonb_populate_recordset(null::offer_management_condition,
                                      json_convert_case($1.conditions, 'snake_case'));
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists rewards(offer_management);
--##
create function rewards(offer_management)
    returns setof offer_management_reward as
$$
begin
    return query
        select *
        from jsonb_populate_recordset(null::offer_management_reward,
                                      json_convert_case($1.rewards, 'snake_case'));
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists conversions(unit);
--##
create function conversions(unit)
    returns setof unit_conversion as
$$
begin
    return query
        select *
        from jsonb_populate_recordset(null::unit_conversion,
                                      json_convert_case($1.conversions, 'snake_case'));
end
$$ language plpgsql immutable
                    security definer;                    