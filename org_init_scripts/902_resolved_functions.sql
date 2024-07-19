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
        select * from tag where id = any ($1.inventory_tags);
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
        select * from tag where id = any ($1.inventory_tags);
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
        select * from tag where id = any ($1.inventory_tags);
end
$$ language plpgsql immutable;
--##
--##
--033_device
drop function if exists branches(device);
--##
create function branches(device)
    returns setof branch as
$$
begin
    return query
        select * from branch where id = any ($1.branches);
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
        select * from category_option where id = any ($1.category1);
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
        select * from category_option where id = any ($1.category2);
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
        select * from category_option where id = any ($1.category3);
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
        select * from category_option where id = any ($1.category4);
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
        select * from category_option where id = any ($1.category5);
end
$$ language plpgsql immutable;
--##
drop function if exists salts(inventory);
--##
create function salts(inventory)
    returns setof pharma_salt as
$$
begin
    return query
        select * from pharma_salt where id = any ($1.salts);
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
        select * from tag where id = any ($1.tags);
end
$$ language plpgsql immutable;
--##
drop function if exists vendors(inventory);
--##
create function vendors(inventory)
    returns setof account as
$$
begin
    return query
        select * from account where id = any ($1.vendors);
end
$$ language plpgsql immutable;
--##
drop function if exists purchase_config(inventory);
--##
create function purchase_config(inventory)
    returns json as
$$
begin
    return json_convert_case($1.purchase_config::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists sale_config(inventory);
--##
create function sale_config(inventory)
    returns json as
$$
begin
    return json_convert_case($1.sale_config::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists cess(inventory);
--##
create function cess(inventory)
    returns json as
$$
begin
    return json_convert_case($1.cess::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists offer_conditions(offer_management);
--##
create function offer_conditions(offer_management)
    returns setof offer_management_condition as
$$
begin
    return query
        select *
        from jsonb_populate_recordset(null::offer_management_condition,
                                                        $1.conditions);
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists offer_rewards(offer_management);
--##
create function offer_rewards(offer_management)
    returns setof offer_management_reward as
$$
begin
    return query
        select *
        from jsonb_populate_recordset(null::offer_management_reward,
                                                        $1.rewards);
end
$$ language plpgsql immutable
                    security definer;
--##
create function conditions(offer_management)
    returns json as
$$
begin
    return json_convert_case($1.conditions::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
create function rewards(offer_management)
    returns json as
$$
begin
    return json_convert_case($1.rewards::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists conversions(unit);
--##
create function conversions(unit)
    returns json as
$$
begin
    return 
    (select json_agg((select jsonb_build_object('id', id, 'name', name, 'precision', precision, 'uqc_id', uqc_id, 'symbol', symbol,
                                                               'conversion', (x ->> 'conversion')::int)
                                     from unit
                                     where id = (x ->> 'unit_id')::int))
                    FROM jsonb_array_elements($1.conversions) x);
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists config(voucher_type);
--##
create function config(voucher_type)
    returns json as
$$
begin
    return json_convert_case($1.config::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists members(voucher_type);
--##
create function members(voucher_type)
    returns json as
$$
begin
    return json_convert_case($1.members::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists approval(voucher_type);
--##
create function approval(voucher_type)
    returns json as
$$
begin
    return json_convert_case($1.approval::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists config(print_template);
--##
create function config(print_template)
    returns json as
$$
begin
    return json_convert_case($1.config::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists delivery_address(account);
--##
create function delivery_address(account)
    returns json as
$$
begin
    return json_convert_case($1.delivery_address::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists registration(pos_server);
--##
create function registration(pos_server)
    returns json as
$$
begin
    return json_convert_case($1.registration::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists member_list(approval_tag);
--##
create function member_list(approval_tag)
    returns setof member as
$$
begin
    return query
        select * from member where id = any ($1.members);
end
$$ language plpgsql immutable
                    security definer;
