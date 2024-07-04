create or replace function apply_member_role()
returns trigger as
$$
declare
    role_name text := (select concat(current_database(), '_', new.name));
    cur_task text := '';
    p permission;
    res_fun text;
resolved_funs text[] := array ['voucher_types(member)__execute',
        'branches(member)__execute',
        'perms(member)__execute',
        'ui_perms(member)__execute',
        'permissions(member_role)__execute',
        'inventory_tags(price_list_condition)__execute',
        'config(print_template)__execute',
        'category1(account)__execute',
        'category2(account)__execute',
        'category3(account)__execute',
        'category4(account)__execute',
        'category5(account)__execute',
        'delivery_address(account)__execute',
        'members(branch)__execute',
        'offer_conditions(offer_management)__execute',
        'offer_rewards(offer_management)__execute',
        'inventory_tags(offer_management_condition)__execute',
        'inventory_tags(offer_management_reward)__execute',
        'registration(pos_server)__execute',
        'branches(desktop_client)__execute',
        'registration(desktop_client)__execute',
        'conversions(unit)__execute',
        'petty_cash_denomination(pos_counter_session)__execute',
        'denomination(pos_counter_session)__execute',
        'config(voucher_type)__execute',
        'members(voucher_type)__execute',
        'approval(voucher_type)__execute',
        'category1(inventory)__execute',
        'category2(inventory)__execute',
        'category3(inventory)__execute',
        'category4(inventory)__execute',
        'category5(inventory)__execute',
        'category6(inventory)__execute',
        'category7(inventory)__execute',
        'category8(inventory)__execute',
        'category9(inventory)__execute',
        'category10(inventory)__execute',
        'salts(inventory)__execute',
        'tags(inventory)__execute',
        'vendors(inventory)__execute',
        'purchase_config(inventory)__execute',
        'sale_config(inventory)__execute',
        'cess(inventory)__execute',
        's_customer_disc(inventory_branch_detail)__execute',
        'mrp_price_list(inventory_branch_detail)__execute',
        's_rate_price_list(inventory_branch_detail)__execute',
        'nlc_price_list(inventory_branch_detail)__execute',
        'closing(bill_allocation)__execute',
        'bill_allocations(account_opening)__execute',
        'ac_trns(voucher)__execute',
        'branch_gst(voucher)__execute',
        'party_gst(voucher)__execute',
        'ac_trns(gift_voucher)__execute',
        'denominations(gift_voucher)__execute',
        'batch(purchase_bill_inv_item)__execute',
        'batch(stock_addition_inv_item)__execute',
        'target_batch(material_conversion_inv_item)__execute',
        'ac_trns(purchase_bill)__execute',
        'branch_gst(purchase_bill)__execute',
        'party_gst(purchase_bill)__execute',
        'tds_details(purchase_bill)__execute',
        'agent_detail(purchase_bill)__execute',
        'agent_account(purchase_bill)__execute',
        'commission_account(purchase_bill)__execute',
        'ac_trns(debit_note)__execute',
        'branch_gst(debit_note)__execute',
        'party_gst(debit_note)__execute',
        'ac_trns(sale_bill)__execute',
        'emi_account(sale_bill)__execute',
        'branch_gst(sale_bill)__execute',
        'party_gst(sale_bill)__execute',
        'emi_detail(sale_bill)__execute',
        'delivery_info(sale_bill)__execute',
        'exchange_adjs(sale_bill)__execute',
        'advance_adjs(sale_bill)__execute',
        'e_invoice_details(sale_bill)__execute',
        'ac_trns(credit_note)__execute',
        'branch_gst(personal_use_purchase)__execute',
        'branch_gst(credit_note)__execute',
        'party_gst(credit_note)__execute',
        'exchange_detail(credit_note)__execute',
        'ac_trns(personal_use_purchase)__execute',
        'ac_trns(stock_adjustment)__execute',
        'ac_trns(stock_deduction)__execute',
        'ac_trns(stock_addition)__execute',
        'ac_trns(material_conversion)__execute',
        'ac_trns(customer_advance)__execute',
        'advance_detail(customer_advance)__execute',
        'member_list(approval_tag)__execute'];
begin
    begin
    if tg_op='INSERT' then
        cur_task = 'create role';
        execute format('create role %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = 'grant role';
        execute format('grant %s to postgres',role_name);
        execute format('grant all on schema graphql to %s',role_name);
        execute format('grant usage ON SCHEMA pg_catalog to %s;',role_name);
        execute format('grant select ON ALL TABLES IN SCHEMA pg_catalog to %s;',role_name);
        execute format('grant usage on schema public to %s;',role_name);
        raise info 'current task: %',cur_task;
        
        cur_task = '000_common';
        execute format('grant execute on function check_gst_no to %s',role_name);
        execute format('grant execute on function json_convert_case to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '001_gst_tax';
        execute format('grant select on table gst_tax to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--003_permission';
        execute format('grant select on table permission to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--004_country';
        execute format('grant select on table country to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--005_uqc';
        execute format('grant select on table uqc to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--006_tds_deductee_type';
        execute format('grant select on table tds_deductee_type to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--008_organization';
        execute format('grant select on table organization to %s',role_name);
        raise info 'current task: %',cur_task;

        cur_task = '--resolved functions';
        foreach res_fun in array resolved_funs
        loop
            cur_task := format('res_fun: grant execute on function %s to %s', split_part(res_fun,'__',1), role_name);
            execute format('grant execute on function %s to %s', split_part(res_fun,'__',1), role_name);
        end loop;
        
    end if;

    if tg_op='UPDATE' then
        cur_task = '--loop permission table for update';
        for p in (select * from permission where id=any(old.perms))
        loop
            if split_part(p.id,'__',2)='execute' then
                cur_task := format('revoke execute on function %s from %s', split_part(p.id,'__',1), role_name);
                execute format('revoke execute on function %s from %s', split_part(p.id,'__',1), role_name);
            elsif split_part(p.id,'__',2)='call' then
                cur_task := format('grant execute on procedure %s to %s', split_part(p.id,'__',1), role_name);
                execute format('grant execute on procedure %s to %s', split_part(p.id,'__',1), role_name);
            elsif array_length(p.fields, 1) > 0 then
                cur_task := format('revoke %s(%s) on table %s from %s', split_part(p.id,'__',2), array_to_string(p.fields,','), split_part(p.id,'__',1), role_name);
                execute format('revoke %s(%s) on table %s from %s', split_part(p.id,'__',2), array_to_string(p.fields,','), split_part(p.id,'__',1), role_name);
            else
                cur_task := format('revoke %s on table %s from %s', split_part(p.id,'__',2), split_part(p.id,'__',1), role_name);
                execute format('revoke %s on table %s from %s', split_part(p.id,'__',2), split_part(p.id,'__',1), role_name);
            end if;
            raise info 'current task: %',cur_task;
        end loop;
    end if;
    ---------------------------------------------------------------------
    cur_task = '--loop permission table for insert';
    for p in (select * from permission where id=any(new.perms))
    loop
        if split_part(p.id,'__',2)='execute' then
            cur_task := format('grant execute on function %s to %s', split_part(p.id,'__',1), role_name);
            execute format('grant execute on function %s to %s', split_part(p.id,'__',1), role_name);
        elsif split_part(p.id,'__',2)='call' then
            cur_task := format('grant execute on procedure %s to %s', split_part(p.id,'__',1), role_name);
            execute format('grant execute on procedure %s to %s', split_part(p.id,'__',1), role_name);
        elsif array_length(p.fields, 1) > 0 then
            cur_task := format('grant %s(%s) on table %s to %s', split_part(p.id,'__',2), array_to_string(p.fields,','), split_part(p.id,'__',1), role_name);
            execute format('grant %s(%s) on table %s to %s', split_part(p.id,'__',2), array_to_string(p.fields,','), split_part(p.id,'__',1), role_name);
        else
            cur_task := format('grant %s on table %s to %s', split_part(p.id,'__',2), split_part(p.id,'__',1), role_name);
            execute format('grant %s on table %s to %s', split_part(p.id,'__',2), split_part(p.id,'__',1), role_name);
        end if;
        raise info 'current task: %',cur_task;
    end loop;

    cur_task = '--025_account: row level security';
    ALTER TABLE account ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS account_select_policy ON account;
    DROP POLICY IF EXISTS account_insert_policy ON account;
    DROP POLICY IF EXISTS account_update_policy ON account;
    DROP POLICY IF EXISTS account_delete_policy ON account;
    CREATE POLICY account_select_policy ON account FOR SELECT USING (true);
    CREATE POLICY account_insert_policy ON account FOR INSERT WITH CHECK (is_default=false);
    CREATE POLICY account_update_policy ON account FOR UPDATE USING (is_default=false) WITH CHECK (is_default=false);
    CREATE POLICY account_delete_policy ON account FOR DELETE USING (is_default=false);

    exception
	   when others then
	      raise exception 'error while running task %',cur_task;
    end;
    return new;
end
$$ language plpgsql security definer;
--##
create or replace trigger apply_member_role
    after insert or update
    on member_role
    for each row
execute procedure apply_member_role();
