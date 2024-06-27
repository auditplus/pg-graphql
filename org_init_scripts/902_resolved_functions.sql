--010_member
drop function if exists permissions(member_role);
--##
create function permissions(member_role)
    returns setof permission as
$$
begin
    return query
        select * from permission where id = any ($1.perms);
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
drop function if exists perms(member);
--##
create or replace function perms(member)
    returns setof permission as
$$
begin
    if $1.is_root then
        return query
        select * from permission;
    else
        return query
        select * from permission where id in (select unnest(perms) from member_role where name=$1.role_id);
    end if;
end
$$ language plpgsql immutable;
--##
drop function if exists ui_perms(member);
--##
create or replace function ui_perms(member)
    returns json as
$$
begin
    return (select ui_perms from member_role where name=$1.role_id);
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
--039_voucher_type
drop function if exists voucher_types(member);
--##
create function voucher_types(member)
    returns setof voucher_type as
$$

begin
    return query
        select *
        from voucher_type
        where (case
                   when $1.is_root then true
                   else members is null or members @> jsonb_build_array(json_build_object('member', $1.id)) end);
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
drop function if exists category1(inventory);
--##
create function category1(inventory)
    returns setof category_option as
$$
begin
    return query
        select * from category_option where id = any ($1.category1);
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
        select * from category_option where id = any ($1.category2);
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
        select * from category_option where id = any ($1.category3);
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
        select * from category_option where id = any ($1.category4);
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
        select * from category_option where id = any ($1.category5);
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
        select * from category_option where id = any ($1.category6);
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
        select * from category_option where id = any ($1.category7);
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
        select * from category_option where id = any ($1.category8);
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
        select * from category_option where id = any ($1.category9);
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
        select * from category_option where id = any ($1.category10);
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
drop function if exists conversions(unit);
--##
create function conversions(unit)
    returns setof unit_conversion as
$$
begin
    return query
        select *
        from jsonb_populate_recordset(null::unit_conversion, 
                                                    $1.conversions);
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(sale_bill);
--##
create function ac_trns(sale_bill)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists emi_account(sale_bill);
--##
create function emi_account(sale_bill)
    returns account as
$$
declare
    acc account;
begin
    select * into acc from account where id = ($1.emi_detail ->> 'accountId')::int;
    return acc;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(credit_note);
--##
create function ac_trns(credit_note)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists branch_gst(voucher);
--##
create function branch_gst(voucher)
    returns json as
$$
begin
    return json_convert_case($1.branch_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists party_gst(voucher);
--##
create function party_gst(voucher)
    returns json as
$$
begin
    return json_convert_case($1.party_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##                    
drop function if exists branch_gst(sale_bill);
--##
create function branch_gst(sale_bill)
    returns json as
$$
begin
    return json_convert_case($1.branch_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists party_gst(sale_bill);
--##
create function party_gst(sale_bill)
    returns json as
$$
begin
    return json_convert_case($1.party_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists branch_gst(credit_note);
--##
create function branch_gst(credit_note)
    returns json as
$$
begin
    return json_convert_case($1.branch_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists party_gst(credit_note);
--##
create function party_gst(credit_note)
    returns json as
$$
begin
    return json_convert_case($1.party_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists branch_gst(purchase_bill);
--##
create function branch_gst(purchase_bill)
    returns json as
$$
begin
    return json_convert_case($1.branch_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists party_gst(purchase_bill);
--##
create function party_gst(purchase_bill)
    returns json as
$$
begin
    return json_convert_case($1.party_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists branch_gst(debit_note);
--##
create function branch_gst(debit_note)
    returns json as
$$
begin
    return json_convert_case($1.branch_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists party_gst(debit_note);
--##
create function party_gst(debit_note)
    returns json as
$$
begin
    return json_convert_case($1.party_gst::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists bill_allocations(account_opening);
--##
create function bill_allocations(account_opening)
    returns setof bill_allocation as
$$
begin
    return query
        select *
        from bill_allocation
        where account_id = $1.account_id
          and branch_id = $1.branch_id
          and voucher_id is null;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists closing(bill_allocation);
--##
create function closing(bill_allocation)
    returns float as
$$
declare
    cls float;
begin
    select sum(amount)
    into cls
    from bill_allocation
    where pending = $1.pending;
    return cls;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(debit_note);
--##
create function ac_trns(debit_note)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(purchase_bill);
--##
create function ac_trns(purchase_bill)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists batch(purchase_bill_inv_item);
--##
create function batch(purchase_bill_inv_item)
    returns batch as
$$
declare
    bat batch;
begin
    select *
    into bat
    from batch
    where txn_id = $1.id;
    return bat;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists tds_details(purchase_bill);
--##
create function tds_details(purchase_bill)
    returns setof tds_on_voucher as
$$
begin
    return query select *
                 from tds_on_voucher
                 where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(personal_use_purchase);
--##
create function ac_trns(personal_use_purchase)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists agent_detail(purchase_bill);
--##
create function agent_detail(purchase_bill)
    returns jsonb as
$$
begin
    return json_convert_case($1.agent_detail::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists agent_account(purchase_bill);
--##
create function agent_account(purchase_bill)
    returns account as
$$
begin
    return (select account from account where id = ($1.agent_detail ->> 'agent_account_id')::int);
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists commission_account(purchase_bill);
--##
create function commission_account(purchase_bill)
    returns account as
$$
begin
    return (select account from account where id = ($1.agent_detail ->> 'commission_account_id')::int);
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(customer_advance);
--##
create function ac_trns(customer_advance)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(gift_voucher);
--##
create function ac_trns(gift_voucher)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(stock_adjustment);
--##
create function ac_trns(stock_adjustment)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(stock_addition);
--##
create function ac_trns(stock_addition)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(stock_deduction);
--##
create function ac_trns(stock_deduction)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(material_conversion);
--##
create function ac_trns(material_conversion)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.voucher_id;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists ac_trns(voucher);
--##
create function ac_trns(voucher)
    returns setof ac_txn as
$$
begin
    return query
        select *
        from ac_txn
        where voucher_id = $1.id;
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
drop function if exists registration(desktop_client);                    
--##
create function registration(desktop_client)
    returns json as
$$
begin
    return json_convert_case($1.registration::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists s_customer_disc(inventory_branch_detail);                    
--##
create function s_customer_disc(inventory_branch_detail)
    returns jsonb as
$$
begin
    return json_convert_case($1.s_customer_disc::jsonb, 'lower_camel_case')::jsonb;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists mrp_price_list(inventory_branch_detail);                    
--##
create function mrp_price_list(inventory_branch_detail)
    returns json as
$$
begin
    return json_convert_case($1.mrp_price_list::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists s_rate_price_list(inventory_branch_detail);                    
--##
create function s_rate_price_list(inventory_branch_detail)
    returns json as
$$
begin
    return json_convert_case($1.s_rate_price_list::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists nlc_price_list(inventory_branch_detail);                    
--##
create function nlc_price_list(inventory_branch_detail)
    returns json as
$$
begin
    return json_convert_case($1.nlc_price_list::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists denominations(gift_voucher);                    
--##
create function denominations(gift_voucher)
    returns jsonb as
$$
begin
    return json_convert_case($1.denominations::jsonb, 'lower_camel_case')::jsonb;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists emi_detail(sale_bill);                    
--##
create function emi_detail(sale_bill)
    returns json as
$$
begin
    return json_convert_case($1.emi_detail::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists delivery_info(sale_bill);                    
--##
create function delivery_info(sale_bill)
    returns json as
$$
begin
    return json_convert_case($1.delivery_info::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists exchange_adjs(sale_bill);                    
--##
create function exchange_adjs(sale_bill)
    returns jsonb as
$$
begin
    return json_convert_case($1.exchange_adjs::jsonb, 'lower_camel_case')::jsonb;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists advance_adjs(sale_bill);                    
--##
create function advance_adjs(sale_bill)
    returns jsonb as
$$
begin
    return json_convert_case($1.advance_adjs::jsonb, 'lower_camel_case')::jsonb;
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists exchange_detail(credit_note);                    
--##
create function exchange_detail(credit_note)
    returns json as
$$
begin
    return json_convert_case($1.exchange_detail::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists advance_detail(customer_advance);                    
--##
create function advance_detail(customer_advance)
    returns json as
$$
begin
    return json_convert_case($1.advance_detail::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists petty_cash_denomination(pos_counter_session);                    
--##
create function petty_cash_denomination(pos_counter_session)
    returns json as
$$
begin
    return json_convert_case($1.petty_cash_denomination::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
--##
drop function if exists denomination(pos_counter_session);                    
--##
create function denomination(pos_counter_session)
    returns json as
$$
begin
    return json_convert_case($1.denomination::jsonb, 'lower_camel_case');
end
$$ language plpgsql immutable
                    security definer;
