create or replace function apply_member_role()
returns trigger as
$$
declare
    role_name text := (select concat(current_database(), '_', new.name));
    cur_task text := '';
    p permission;
    arr_val text;

    common_tables text[] := array[
        'gst_tax',
        'permission',
        'country',
        'uqc',
        'tds_deductee_type',
        'organization',
        'account_type',
        'category',
        'warehouse',
        'approval_tag',
        'tds_nature_of_payment',
        'stock_location',
        'tag',
        'sales_person',
        'print_template',
        'unit',
        'unit_conversion',
        'category_option',
        'division',
        'pos_counter',
        'voucher_type',
        'pharma_salt',
        'vw_gst_registration',
        'member_profile'];
    common_funs text[] := array [
        'json_convert_case',
        'check_gst_no',
        'eligible_approval_states',
        'register_device',
        'register_pos_server',
        'check_voucher_mode',
        'check_base_account_type',
        'check_base_account_types',
        'check_category_type',
        'check_org_status',
        'check_drug_category',
        'check_price_apply_on',
        'check_price_computation',
        'check_print_layout',
        'check_gst_reg_type',
        'check_contact_type',
        'check_due_based_on',
        'check_offer_reward_type',
        'check_pos_mode',
        'check_base_voucher_type',
        'check_inventory_type',
        'check_reorder_mode',
        'check_batch_entry_type',
        'check_pending_ref_type',
        'check_bank_txn_type',
        'check_gst_location_type',
        'check_gift_voucher_expiry_type',
        'check_purchase_mode',
        'voucher_types(member)',
        'branches(member)',
        'perms(member)',
        'ui_perms(member)',
        'permissions(member_role)',
        'inventory_tags(price_list_condition)',
        'config(print_template)',
        'category1(account)',
        'category2(account)',
        'category3(account)',
        'category4(account)',
        'category5(account)',
        'delivery_address(account)',
        'members(branch)',
        'offer_conditions(offer_management)',
        'offer_rewards(offer_management)',
        'inventory_tags(offer_management_condition)',
        'inventory_tags(offer_management_reward)',
        'registration(pos_server)',
        'branches(device)',
        'conversions(unit)',
        'petty_cash_denomination(pos_counter_session)',
        'denomination(pos_counter_session)',
        'config(voucher_type)',
        'members(voucher_type)',
        'approval(voucher_type)',
        'category1(inventory)',
        'category2(inventory)',
        'category3(inventory)',
        'category4(inventory)',
        'category5(inventory)',
        'category6(inventory)',
        'category7(inventory)',
        'category8(inventory)',
        'category9(inventory)',
        'category10(inventory)',
        'salts(inventory)',
        'tags(inventory)',
        'vendors(inventory)',
        'purchase_config(inventory)',
        'sale_config(inventory)',
        'cess(inventory)',
        's_customer_disc(inventory_branch_detail)',
        'mrp_price_list(inventory_branch_detail)',
        's_rate_price_list(inventory_branch_detail)',
        'nlc_price_list(inventory_branch_detail)',
        'closing(bill_allocation)',
        'bill_allocations(account_opening)',
        'ac_trns(voucher)',
        'branch_gst(voucher)',
        'party_gst(voucher)',
        'ac_trns(gift_voucher)',
        'denominations(gift_voucher)',
        'batch(purchase_bill_inv_item)',
        'batch(stock_addition_inv_item)',
        'target_batch(material_conversion_inv_item)',
        'ac_trns(purchase_bill)',
        'branch_gst(purchase_bill)',
        'party_gst(purchase_bill)',
        'tds_details(purchase_bill)',
        'agent_detail(purchase_bill)',
        'agent_account(purchase_bill)',
        'commission_account(purchase_bill)',
        'ac_trns(debit_note)',
        'branch_gst(debit_note)',
        'party_gst(debit_note)',
        'ac_trns(sale_bill)',
        'emi_account(sale_bill)',
        'branch_gst(sale_bill)',
        'party_gst(sale_bill)',
        'emi_detail(sale_bill)',
        'delivery_info(sale_bill)',
        'exchange_adjs(sale_bill)',
        'advance_adjs(sale_bill)',
        'e_invoice_details(sale_bill)',
        'ac_trns(credit_note)',
        'branch_gst(personal_use_purchase)',
        'branch_gst(credit_note)',
        'party_gst(credit_note)',
        'exchange_detail(credit_note)',
        'ac_trns(personal_use_purchase)',
        'ac_trns(stock_adjustment)',
        'ac_trns(stock_deduction)',
        'ac_trns(stock_addition)',
        'ac_trns(material_conversion)',
        'ac_trns(customer_advance)',
        'advance_detail(customer_advance)',
        'conditions(offer_management)',
        'rewards(offer_management)'];
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
        
        cur_task = '--common tables';
        foreach arr_val in array common_tables
        loop
            cur_task := format('common table: grant select on table %s to %s', arr_val, role_name);
            execute format('grant select on table %s to %s', arr_val, role_name);
        end loop;

        cur_task = '--common functions';
        foreach arr_val in array common_funs
        loop
            cur_task := format('cmn_fun: grant execute on function %s to %s', arr_val, role_name);
            execute format('grant execute on function %s to %s', arr_val, role_name);
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
                cur_task := format('revoke execute on procedure %s from %s', split_part(p.id,'__',1), role_name);
                execute format('revoke execute on procedure %s from %s', split_part(p.id,'__',1), role_name);
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
