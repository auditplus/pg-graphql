create procedure activate_user(text) as
$$
declare
    new_user text := (select concat(current_database(),'_',$1));
    cur_task text := '';
begin
    
    begin
    cur_task = '001_gst_tax';
    execute format('grant select on table gst_tax to %s',new_user);
    cur_task = '002_account_type';
    execute format('grant select on table account_type to %s',new_user);
    cur_task = '--003_permission';
    execute format('grant select on table permission to %s',new_user);
    execute format('grant insert(id, name, uri, tag, req) on table permission to %s',new_user);
    execute format('grant update(name, uri, tag, req) on table permission to %s',new_user);
    execute format('grant delete on table permission to %s',new_user);
    cur_task = '--004_country';
    execute format('grant select on table country to %s',new_user);
    cur_task = '--005_uqc';
    execute format('grant select on table uqc to %s',new_user);
    cur_task = '--006_tds_deductee_type';
    execute format('grant select on table tds_deductee_type to %s',new_user);
    cur_task = '--007_category';
    execute format('grant select on table category to %s',new_user);
    execute format('grant update(category,active,sort_order) on table category to %s',new_user);
    cur_task = '--008_organization';
    execute format('grant select on table organization to %s',new_user);
    cur_task = '--009_warehouse';
    execute format('grant select on table warehouse to %s',new_user);
    execute format('grant insert(name, mobile, email, telephone, address, city, pincode, state, country) on table warehouse to %s',new_user);
    execute format('grant update(name, mobile, email, telephone, address, city, pincode, state, country) on table warehouse to %s',new_user);
    execute format('grant delete on table warehouse to %s',new_user);
    cur_task = '--010_member';
    execute format('grant select(id, name, remote_access, is_root,settings,perms, user_id, nick_name, created_at,updated_at, branches, voucher_types) on table member to %s',new_user);
    execute format('grant insert(name, pass, remote_access, settings, perms, user_id, nick_name) on table member to %s',new_user);
    execute format('grant update(name, pass, remote_access, settings, perms, user_id, nick_name) on table member to %s',new_user);
    cur_task = '--011_approval_tag';
    execute format('grant select on table approval_tag to %s',new_user);
    execute format('grant insert(name, members) on table approval_tag to %s',new_user);
    execute format('grant update(name, members) on table approval_tag to %s',new_user);
    execute format('grant delete on table approval_tag to %s',new_user);
    cur_task = '--012_tds_nature_of_payment';
    execute format('grant select on table tds_nature_of_payment to %s',new_user);
    execute format('grant insert(name, section, ind_huf_rate, ind_huf_rate_wo_pan, other_deductee_rate, other_deductee_rate_wo_pan, threshold) on table tds_nature_of_payment to %s',new_user);
    execute format('grant update(name, section, ind_huf_rate, ind_huf_rate_wo_pan, other_deductee_rate, other_deductee_rate_wo_pan, threshold) on table tds_nature_of_payment to %s',new_user);
    execute format('grant delete on table tds_nature_of_payment to %s',new_user);
    cur_task = '--013_bank';
    execute format('grant select on table bank to %s',new_user);
    execute format('grant insert(name, short_name, branch_name, bsr_code, ifsc_code, micr_code) on table bank to %s',new_user);
    execute format('grant update(name, short_name, branch_name, bsr_code, ifsc_code, micr_code) on table bank to %s',new_user);
    execute format('grant delete on table bank to %s',new_user);
    cur_task = '--014_bank_beneficiary';
    execute format('grant select on table bank_beneficiary to %s',new_user);
    execute format('grant insert(account_no, bank_name, branch_name, ifsc_code, account_type, account_holder_name) on table bank_beneficiary to %s',new_user);
    execute format('grant update(account_no, bank_name, branch_name, ifsc_code, account_type, account_holder_name) on table bank_beneficiary to %s',new_user);
    execute format('grant delete on table bank_beneficiary to %s',new_user);
    cur_task = '--015_doctor';
    execute format('grant select on table doctor to %s',new_user);
    execute format('grant insert(name, license_no) on table doctor to %s',new_user);
    execute format('grant update(name, license_no) on table doctor to %s',new_user);
    execute format('grant delete on table doctor to %s',new_user);
    cur_task = '--016_stock_location';
    execute format('grant select on table stock_location to %s',new_user);
    execute format('grant insert(name) on table stock_location to %s',new_user);
    execute format('grant update(name) on table stock_location to %s',new_user);
    execute format('grant delete on table stock_location to %s',new_user);
    cur_task = '--017_display_rack';
    execute format('grant select on table display_rack to %s',new_user);
    execute format('grant insert(name) on table display_rack to %s',new_user);
    execute format('grant update(name) on table display_rack to %s',new_user);
    execute format('grant delete on table display_rack to %s',new_user);
    cur_task = '--018_tag';
    execute format('grant select on table tag to %s',new_user);
    execute format('grant insert(name) on table tag to %s',new_user);
    execute format('grant update(name) on table tag to %s',new_user);
    execute format('grant delete on table tag to %s',new_user);
    cur_task = '--019_manufacturer';
    execute format('grant select on table manufacturer to %s',new_user);
    execute format('grant insert(name, mobile, email, telephone) on table manufacturer to %s',new_user);
    execute format('grant update(name, mobile, email, telephone) on table manufacturer to %s',new_user);
    execute format('grant delete on table manufacturer to %s',new_user);
    cur_task = '--020_pharma_salt';
    execute format('grant select on table pharma_salt to %s',new_user);
    execute format('grant insert(name, drug_category) on table pharma_salt to %s',new_user);
    execute format('grant update(name, drug_category) on table pharma_salt to %s',new_user);
    execute format('grant delete on table pharma_salt to %s',new_user);
    cur_task = '--021_sale_incharge';
    execute format('grant select on table sale_incharge to %s',new_user);
    execute format('grant insert(name, code) on table sale_incharge to %s',new_user);
    execute format('grant update(name, code) on table sale_incharge to %s',new_user);
    execute format('grant delete on table sale_incharge to %s',new_user);
    cur_task = '--022_price_list';
    execute format('grant select on table price_list to %s',new_user);
    execute format('grant insert(name, customer_tag, list) on table price_list to %s',new_user);
    execute format('grant update(name, customer_tag, list) on table price_list to %s',new_user);
    execute format('grant delete on table price_list to %s',new_user);
    cur_task = '--023_print_template';
    execute format('grant select on table print_template to %s',new_user);
    execute format('grant insert(name, config, layout, voucher_mode) on table print_template to %s',new_user);
    execute format('grant update(name, config, layout, voucher_mode) on table print_template to %s',new_user);
    execute format('grant delete on table print_template to %s',new_user);
    cur_task = '--024_gst_registration';
    execute format('grant select on table gst_registration to %s',new_user);
    execute format('grant insert(reg_type, gst_no, state, username, email, e_invoice_username, e_password) on table gst_registration to %s',new_user);
    execute format('grant update(username, email, e_invoice_username, e_password) on table gst_registration to %s',new_user);
    execute format('grant delete on table gst_registration to %s',new_user);
    cur_task = '--025_account';
    execute format('grant select on table account to %s',new_user);
    execute format('grant insert(name, account_type, alias_name, cheque_in_favour_of, description,
    commission, gst_reg_type, gst_location_id, gst_no, gst_is_exempted, gst_exempted_desc, sac_code, 
    bill_wise_detail, is_commission_discounted, due_based_on, due_days, credit_limit, pan_no, 
    aadhar_no, mobile, email, contact_person, address, city, pincode, category1, category2, category3, category4, 
    category5, state_id, country_id, bank_beneficiary, agent_id, commission_account_id, parent_id, gst_tax, tds_nature_of_payment, 
    tds_deductee_type) on table account to %s',new_user);
    execute format('grant update(name, alias_name, cheque_in_favour_of, description,
    commission, gst_reg_type, gst_location_id, gst_no, gst_is_exempted, gst_exempted_desc, sac_code, 
    bill_wise_detail, is_commission_discounted, due_based_on, due_days, credit_limit, pan_no, 
    aadhar_no, mobile, email, contact_person, address, city, pincode, category1, category2, category3, category4, 
    category5, state_id, country_id, bank_beneficiary, agent_id, commission_account_id, parent_id, gst_tax, tds_nature_of_payment, 
    tds_deductee_type) on table account to %s',new_user);
    execute format('grant delete on table account to %s',new_user);
    
    cur_task = '--025_account: row level security';
    ALTER TABLE account ENABLE ROW LEVEL SECURITY;
    drop policy if exists account_select_policy ON account;
    drop policy if exists account_insert_policy ON account;
    drop policy if exists account_update_policy ON account;
    drop policy if exists account_delete_policy ON account;
    CREATE POLICY account_select_policy ON account FOR SELECT USING (true);
    CREATE POLICY account_insert_policy ON account FOR INSERT WITH CHECK (true);
    CREATE POLICY account_update_policy ON account FOR UPDATE WITH CHECK (true);
    CREATE POLICY account_delete_policy ON account FOR DELETE USING (is_default=false);

    cur_task = '--026_customer';
    execute format('grant select on table customer to %s',new_user);
    execute format('grant insert(name,short_name, pan_no, aadhar_no, gst_reg_type, gst_location, gst_no, mobile, alternate_mobile, 
    email, telephone, contact_person, address, city, pincode, state, country, bank_beneficiary, delivery_address, 
    tracking_account, enable_loyalty_point, agent, commission_account, commission, is_commission_discounted, 
    bill_wise_detail, tags, due_based_on, due_days, credit_limit) on table customer to %s',new_user);
    execute format('grant update(name,short_name, pan_no, aadhar_no, gst_reg_type, gst_location, gst_no, mobile, alternate_mobile, 
    email, telephone, contact_person, address, city, pincode, state, country, bank_beneficiary, delivery_address, 
    enable_loyalty_point, agent, commission_account, commission, is_commission_discounted, bill_wise_detail, tags, 
    due_based_on, due_days, credit_limit) on table customer to %s',new_user);
    execute format('grant delete on table customer to %s',new_user);
    cur_task = '--027_branch';
    execute format('grant select on table branch to %s',new_user);
    execute format('grant insert(name, mobile, alternate_mobile, email, telephone, contact_person, address, city, pincode, state, 
    country, gst_registration, voucher_no_prefix, misc, members, account) on table branch to %s',new_user);
    execute format('grant update(name, mobile, alternate_mobile, email, telephone, contact_person, address, city, pincode, state, 
    country, gst_registration, voucher_no_prefix, misc, members) on table branch to %s',new_user);
    execute format('grant delete on table category_option to %s',new_user);
    cur_task = '--028_vendor';
    execute format('grant select on table vendor to %s',new_user);
    execute format('grant insert(name, short_name, pan_no, aadhar_no, gst_reg_type, gst_location, gst_no, mobile, alternate_mobile, 
    email, telephone, contact_person, address, city, pincode, state, country, bank_beneficiary, tracking_account, 
    agent, commission_account, commission, is_commission_discounted, bill_wise_detail, due_based_on, 
    due_days, credit_limit, tds_deductee_type) on table vendor to %s',new_user);
    execute format('grant update(name, short_name, pan_no, aadhar_no, gst_reg_type, gst_location, gst_no, mobile, alternate_mobile, 
    email, telephone, contact_person, address, city, pincode, state, country, bank_beneficiary, 
    agent, commission_account, commission, is_commission_discounted, bill_wise_detail, due_based_on, 
    due_days, credit_limit, tds_deductee_type) on table vendor to %s',new_user);
    execute format('grant delete on table vendor to %s',new_user);
    cur_task = '--029_stock_value';
    execute format('grant all on table stock_value to %s',new_user);
    cur_task = '--030_offer_management';
    execute format('grant select on table offer_management to %s',new_user);
    execute format('grant insert(name, conditions, rewards, branch, price_list, start_date, end_date) on table offer_management to %s',new_user);
    execute format('grant update(name, conditions, rewards, branch, price_list, start_date, end_date) on table offer_management to %s',new_user);
    execute format('grant delete on table offer_management to %s',new_user);
    cur_task = '--031_transport';
    execute format('grant select on table transport to %s',new_user);
    execute format('grant insert(name, mobile, email, telephone) on table transport to %s',new_user);
    execute format('grant update(name, mobile, email, telephone) on table transport to %s',new_user);
    execute format('grant delete on table transport to %s',new_user);
    cur_task = '--032_pos_server';
    execute format('grant select on table pos_server to %s',new_user);
    execute format('grant insert(name, branch, mode) on table pos_server to %s',new_user);
    execute format('grant update(name, mode, is_active) on table pos_server to %s',new_user);
    execute format('grant delete on table pos_server to %s',new_user);
    cur_task = '--033_desktop_client';
    execute format('grant select on table desktop_client to %s',new_user);
    execute format('grant insert(name, branch) on table desktop_client to %s',new_user);
    execute format('grant update(name, branch) on table desktop_client to %s',new_user);
    execute format('grant delete on table desktop_client to %s',new_user);
    cur_task = '--034_unit';
    execute format('grant select on table unit to %s',new_user);
    execute format('grant insert(name, uqc, symbol, precision, conversions) on table unit to %s',new_user);
    execute format('grant update(name, uqc, symbol, precision, conversions) on table unit to %s',new_user);
    execute format('grant delete on table unit to %s',new_user);
    cur_task = '--035_category_option';
    execute format('grant select on table category_option to %s',new_user);
    execute format('grant insert(category, name, active) on table category_option to %s',new_user);
    execute format('grant update(category, name, active) on table category_option to %s',new_user);
    execute format('grant delete on table category_option to %s',new_user);
    cur_task = '--036_division';
    execute format('grant select on table division to %s',new_user);
    execute format('grant insert(name) on table division to %s',new_user);
    execute format('grant update(name) on table division to %s',new_user);
    execute format('grant delete on table division to %s',new_user);
    cur_task = '--037_gift_coupon';
    execute format('grant select on table gift_coupon to %s',new_user);
    cur_task = '--039_voucher_type';
    execute format('grant select on table voucher_type to %s',new_user);
    execute format('grant insert(name, prefix, sequence, base_type, config, members) on table voucher_type to %s',new_user);
    execute format('grant update(name, prefix, sequence, config, members) on table voucher_type to %s',new_user);
    execute format('grant delete on table voucher_type to %s',new_user);
    cur_task = '--040_inventory';
    execute format('grant select on table inventory to %s',new_user);
    execute format('grant insert(name, division_id, inventory_type, allow_negative_stock, gst_tax_id, unit_id, loose_qty, 
    reorder_inventory, bulk_inventory_id, qty, sale_unit_id, purchase_unit_id, cess, purchase_config, 
    sale_config, barcodes, tags, hsn_code, description, manufacturer, manufacturer_name, vendor, 
    vendor_name, vendors, salts, set_rate_values_via_purchase, apply_s_rate_from_master_for_sale, 
    category1, category2, category3, category4, category5, category6, category7, category8, 
    category9, category10) on table inventory to %s',new_user);
    execute format('grant update(name, inventory_type, allow_negative_stock, gst_tax_id, unit_id,  
    reorder_inventory, bulk_inventory_id, qty, sale_unit_id, purchase_unit_id, cess, purchase_config, 
    sale_config, barcodes, tags, hsn_code, description, manufacturer, manufacturer_name, vendor, 
    vendor_name, vendors, salts, set_rate_values_via_purchase, apply_s_rate_from_master_for_sale, 
    category1, category2, category3, category4, category5, category6, category7, category8, 
    category9, category10) on table inventory to %s',new_user);
    execute format('grant delete on table inventory to %s',new_user);
    cur_task = '--041_inventory_branch_detail';
    execute format('grant select on table inventory_branch_detail to %s',new_user);
    execute format('grant insert(inventory, inventory_name, branch, branch_name, inventory_barcodes, stock_location, 
    s_disc, discount_1, discount_2, vendor, s_customer_disc, mrp_price_list, s_rate_price_list, 
    nlc_price_list, mrp, s_rate, p_rate_tax_inc, p_rate, landing_cost, nlc, stock, reorder_inventory, 
    reorder_mode, reorder_level, min_order, max_order) on table inventory_branch_detail to %s',new_user);
    execute format('grant update(inventory_name, branch_name, inventory_barcodes, stock_location, 
    s_disc, discount_1, discount_2, vendor, s_customer_disc, mrp_price_list, s_rate_price_list, 
    nlc_price_list, mrp, s_rate, p_rate_tax_inc, p_rate, landing_cost, nlc, stock, reorder_inventory, 
    reorder_mode, reorder_level, min_order, max_order) on table inventory_branch_detail to %s',new_user);
    cur_task = '--042_approval_log';
    execute format('grant select on table approval_log to %s',new_user);
    cur_task = '--043_financial_year';
    execute format('grant select on table financial_year to %s',new_user);
    execute format('grant insert(fy_start, fy_end) on table financial_year to %s',new_user);
    cur_task = '--044_voucher_numbering--none';
    cur_task = '--045_batch';
    execute format('grant select on table batch to %s',new_user);
    execute format('grant update(batch_no, expiry, s_rate, mrp) on table batch to %s',new_user);
    cur_task = '--046_account_daily_summary--none';
    cur_task = '--047_bill_allocation';
    execute format('grant select on table bill_allocation to %s',new_user);
    cur_task = '--048_acc_cat_txn--none';
    cur_task = '--049_bank_txn';
    execute format('grant select on table bank_txn to %s',new_user);
    execute format('grant update(bank_date) on table bank_txn to %s',new_user);
    cur_task = '--050_gst_txn--none';
    cur_task = '--051_ac_txn--none';
    cur_task = '--052_inv_txn--none';
    cur_task = '--053_account_opening';
    execute format('grant select on table account_opening to %s',new_user);
    execute format('grant execute on function set_account_opening to %s',new_user);
    cur_task = '--054_inventory_opening';
    execute format('grant select on table account_opening to %s',new_user);
    execute format('grant execute on function set_inventory_opening to %s',new_user);
    cur_task = '--055_tds_on_voucher';
    execute format('grant select on table tds_on_voucher to %s',new_user);--514_tds_on_voucher_section_break_up
    execute format('grant execute on function tds_on_voucher_section_break_up to %s',new_user);
    cur_task = '--056_exchange';
    execute format('grant select on table exchange to %s',new_user);
    cur_task = '--057_exchange_adjustment';
    execute format('grant select on table exchange_adjustment to %s',new_user);
    cur_task = '--058_voucher';
    execute format('grant select on table voucher to %s',new_user);
    execute format('grant execute on function create_voucher to %s',new_user);
    execute format('grant execute on function update_voucher to %s',new_user);
    execute format('grant execute on function delete_voucher to %s',new_user);
    execute format('grant execute on function approve_voucher to %s',new_user);
    cur_task = '--059_good_inward_note';
    execute format('grant select on table goods_inward_note to %s',new_user);
    execute format('grant execute on function create_goods_inward_note to %s',new_user);
    execute format('grant execute on function update_goods_inward_note to %s',new_user);
    execute format('grant execute on function delete_goods_inward_note to %s',new_user);
    cur_task = '--060_gift_voucher';
    execute format('grant select on table gift_voucher to %s',new_user);
    execute format('grant execute on function create_gift_voucher to %s',new_user);
    execute format('grant execute on function update_gift_voucher to %s',new_user);
    execute format('grant execute on function delete_gift_voucher to %s',new_user);
    cur_task = '--061_purchase_bill_inv_item';
    execute format('grant select on table purchase_bill_inv_item to %s',new_user);
    cur_task = '--062_purchase_bill';
    execute format('grant select on table purchase_bill to %s',new_user);
    execute format('grant execute on function create_purchase_bill to %s',new_user);
    execute format('grant execute on function update_purchase_bill to %s',new_user);
    execute format('grant execute on function delete_purchase_bill to %s',new_user);
    cur_task = '--063_debit_note_inv_item';
    execute format('grant select on table debit_note_inv_item to %s',new_user);
    cur_task = '--064_debit_note';
    execute format('grant select on table debit_note to %s',new_user);
    execute format('grant execute on function create_debit_note to %s',new_user);
    execute format('grant execute on function update_debit_note to %s',new_user);
    execute format('grant execute on function delete_debit_note to %s',new_user);
    cur_task = '--065_sale_bill_inv_item';
    execute format('grant select on table sale_bill_inv_item to %s',new_user);
    cur_task = '--066_sale_bill';
    execute format('grant select on table sale_bill to %s',new_user);
    execute format('grant execute on function create_sale_bill to %s',new_user);
    execute format('grant execute on function update_sale_bill to %s',new_user);
    execute format('grant execute on function delete_sale_bill to %s',new_user);
    cur_task = '--067_credit_note_inv_item';
    execute format('grant select on table credit_note_inv_item to %s',new_user);
    cur_task = '--068_credit_note';
    execute format('grant select on table credit_note to %s',new_user);
    execute format('grant execute on function create_credit_note to %s',new_user);
    execute format('grant execute on function update_credit_note to %s',new_user);
    execute format('grant execute on function delete_credit_note to %s',new_user);
    cur_task = '--069_personal_use_purchase_item';
    execute format('grant select on table personal_use_purchase_inv_item to %s',new_user);
    cur_task = '--070_personal_use_purchase';
    execute format('grant select on table personal_use_purchase to %s',new_user);
    execute format('grant execute on function create_personal_use_purchase to %s',new_user);
    execute format('grant execute on function update_personal_use_purchase to %s',new_user);
    execute format('grant execute on function delete_personal_use_purchase to %s',new_user);
    cur_task = '--073_customer_advance';
    execute format('grant select on table customer_advance to %s',new_user);
    execute format('grant execute on function create_customer_advance to %s',new_user);
    execute format('grant execute on function update_customer_advance to %s',new_user);
    execute format('grant execute on function delete_customer_advance to %s',new_user);
    cur_task = '--081_stock_adjustment_inv_item';
    execute format('grant select on table stock_adjustment_inv_item to %s',new_user);
    cur_task = '--082_stock_adjustment';
    execute format('grant select on table stock_adjustment to %s',new_user);
    execute format('grant execute on function create_stock_adjustment to %s',new_user);
    execute format('grant execute on function update_stock_adjustment to %s',new_user);
    execute format('grant execute on function delete_stock_adjustment to %s',new_user);
    cur_task = '--083_stock_deduction_inv_item';
    execute format('grant select on table stock_adjustment_inv_item to %s',new_user);
    cur_task = '--084_stock_deduction';
    execute format('grant select on table stock_deduction to %s',new_user);
    execute format('grant execute on function create_stock_deduction to %s',new_user);
    execute format('grant execute on function update_stock_deduction to %s',new_user);
    execute format('grant execute on function delete_stock_deduction to %s',new_user);
    cur_task = '--085_stock_addition_inv_item';
    execute format('grant select on table stock_addition_inv_item to %s',new_user);
    cur_task = '--086_stock_addition';
    execute format('grant select on table stock_addition to %s',new_user);
    execute format('grant execute on function create_stock_addition to %s',new_user);
    execute format('grant execute on function update_stock_addition to %s',new_user);
    execute format('grant execute on function delete_stock_addition to %s',new_user);
    cur_task = '--087_material_conversion_inv_item';
    execute format('grant select on table material_conversion_inv_item to %s',new_user);
    cur_task = '--088_material_conversion';
    execute format('grant select on table material_conversion to %s',new_user);
    execute format('grant execute on function create_material_conversion to %s',new_user);
    execute format('grant execute on function update_material_conversion to %s',new_user);
    execute format('grant execute on function delete_material_conversion to %s',new_user);
    cur_task = '--089_vendor_bill_map';
    execute format('grant select on table vendor_bill_map to %s',new_user);
    execute format('grant insert on table vendor_bill_map to %s',new_user);
    execute format('grant update(start_row, name, unit, qty, mrp, rate, free, batch_no, expiry,
    expiry_format, discount) on table vendor_bill_map to %s',new_user);
    execute format('grant delete on table vendor_bill_map to %s',new_user);
    cur_task = '--090_vendor_item_map';
    execute format('grant select on table vendor_item_map to %s',new_user);
    execute format('grant insert(vendor, inventory, vendor_inventory) on table vendor_item_map to %s',new_user);
    execute format('grant update(vendor_inventory) on table vendor_item_map to %s',new_user);
    execute format('grant delete on table vendor_item_map to %s',new_user);
    exception 
	   when others then 
	      raise exception 'error while running task %',cur_task;
    end;
end
$$ language plpgsql security definer;
--##
comment on schema public is e'@graphql({"max_rows": 100, "inflect_names": true})';
--##
call activate_user('admin');