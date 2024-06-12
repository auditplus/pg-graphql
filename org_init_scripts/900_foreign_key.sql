alter table warehouse
    add constraint warehouse_state_id_fkey foreign key (state_id) references country;
--##
alter table warehouse
    add constraint warehouse_country_id_fkey foreign key (country_id) references country;
--##
alter table member
    add constraint member_role_id_fkey foreign key (role_id) references member_role;
--##
alter table price_list
    add constraint price_list_customer_tag_id_fkey foreign key (customer_tag_id) references tag;
--##
alter table price_list_condition
    add constraint price_list_condition_price_list_id_fkey foreign key (price_list_id) references price_list on delete cascade;
--##
alter table price_list_condition
    add constraint price_list_condition_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table price_list_condition
    add constraint price_list_condition_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table price_list_condition
    add constraint price_list_condition_category1_id_fkey foreign key (category1_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category2_id_fkey foreign key (category2_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category3_id_fkey foreign key (category3_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category4_id_fkey foreign key (category4_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category5_id_fkey foreign key (category5_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category6_id_fkey foreign key (category6_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category7_id_fkey foreign key (category7_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category8_id_fkey foreign key (category8_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category9_id_fkey foreign key (category9_id) references category_option;
--##
alter table price_list_condition
    add constraint price_list_condition_category10_id_fkey foreign key (category10_id) references category_option;
--##
alter table account
    add constraint account_account_type_id_fkey foreign key (account_type_id) references account_type;
--##
alter table account
    add constraint account_state_id_fkey foreign key (state_id) references country;
--##
alter table account
    add constraint account_country_id_fkey foreign key (country_id) references country;
--##
alter table account
    add constraint account_bank_beneficiary_id_fkey foreign key (bank_beneficiary_id) references bank_beneficiary;
--##
alter table account
    add constraint account_gst_location_id_fkey foreign key (gst_location_id) references country;
--##
alter table account
    add constraint account_gst_tax_id_fkey foreign key (gst_tax_id) references gst_tax;
--##
alter table account
    add constraint account_tds_nature_of_payment_id_fkey foreign key (tds_nature_of_payment_id) references tds_nature_of_payment;
--##
alter table account
    add constraint account_tds_deductee_type_id_fkey foreign key (tds_deductee_type_id) references tds_deductee_type;
--##
alter table customer
    add constraint customer_gst_location_id_fkey foreign key (gst_location_id) references country;
--##
alter table customer
    add constraint customer_state_id_fkey foreign key (state_id) references country;
--##
alter table customer
    add constraint customer_country_id_fkey foreign key (country_id) references country;
--##
alter table customer
    add constraint customer_bank_beneficiary_id_fkey foreign key (bank_beneficiary_id) references bank_beneficiary;
--##
alter table customer
    add constraint customer_credit_account_id_fkey foreign key (credit_account_id) references account;
--##
alter table customer
    add constraint customer_agent_id_fkey foreign key (agent_id) references account;
--##
alter table customer
    add constraint customer_tracking_account_type_id_fkey foreign key (tracking_account_type_id) references account_type;
--##
alter table customer
    add constraint customer_commission_account_id_fkey foreign key (commission_account_id) references account;
--##
alter table vendor
    add constraint vendor_gst_location_id_fkey foreign key (gst_location_id) references country;
--##
alter table vendor
    add constraint vendor_state_id_fkey foreign key (state_id) references country;
--##
alter table vendor
    add constraint vendor_country_id_fkey foreign key (country_id) references country;
--##
alter table vendor
    add constraint vendor_bank_beneficiary_id_fkey foreign key (bank_beneficiary_id) references bank_beneficiary;
--##
alter table vendor
    add constraint vendor_credit_account_id_fkey foreign key (credit_account_id) references account;
--##
alter table vendor
    add constraint vendor_agent_id_fkey foreign key (agent_id) references account;
--##
alter table vendor
    add constraint vendor_commission_account_id_fkey foreign key (commission_account_id) references account;
--##
alter table vendor
    add constraint vendor_tds_deductee_type_id_fkey foreign key (tds_deductee_type_id) references tds_deductee_type;
--##
alter table vendor
    add constraint vendor_tracking_account_type_id_fkey foreign key (tracking_account_type_id) references account_type;
--##
alter table gst_registration
    add constraint gst_registration_state_id_fkey foreign key (state_id) references country;
--##
alter table branch
    add constraint branch_gst_registration_id_fkey foreign key (gst_registration_id) references gst_registration;
--##
alter table branch
    add constraint branch_state_id_fkey foreign key (state_id) references country;
--##
alter table branch
    add constraint branch_country_id_fkey foreign key (country_id) references country;
--##
alter table branch
    add constraint branch_account_id_fkey foreign key (account_id) references account;
--##
alter table stock_value
    add constraint stock_value_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table offer_management
    add constraint offer_management_price_list_id_fkey foreign key (price_list_id) references price_list;
--##
alter table offer_management
    add constraint offer_management_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table gift_coupon
    add constraint gift_coupon_gift_voucher_id_fkey foreign key (gift_voucher_id) references gift_voucher on delete cascade;
--##
alter table gift_coupon
    add constraint gift_coupon_gift_voucher_account_id_fkey foreign key (gift_voucher_account_id) references account;
--##
alter table gift_coupon
    add constraint gift_coupon_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table pos_server
    add constraint pos_server_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table unit
    add constraint unit_uqc_id_fkey foreign key (uqc_id) references uqc;
--##
alter table category_option
    add constraint category_option_category_id_fkey foreign key (category_id) references category;
--##
alter table inventory
    add constraint inventory_division_id_fkey foreign key (division_id) references division;
--##
alter table inventory
    add constraint inventory_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table inventory
    add constraint inventory_sale_unit_id_fkey foreign key (sale_unit_id) references unit;
--##
alter table inventory
    add constraint inventory_purchase_unit_id_fkey foreign key (purchase_unit_id) references unit;
--##
alter table inventory
    add constraint inventory_gst_tax_id_fkey foreign key (gst_tax_id) references gst_tax;
--##
alter table inventory
    add constraint inventory_manufacturer_id_fkey foreign key (manufacturer_id) references manufacturer;
--##
alter table inventory
    add constraint inventory_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_reorder_inventory_id_fkey foreign key (reorder_inventory_id) references inventory;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_stock_location_id_fkey foreign key (stock_location_id) references stock_location;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table voucher_numbering
    add constraint voucher_numbering_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table voucher_numbering
    add constraint voucher_numbering_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table voucher_numbering
    add constraint voucher_numbering_f_year_id_fkey foreign key (f_year_id) references financial_year;
--##
alter table voucher
    add constraint voucher_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table voucher
    add constraint voucher_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table voucher
    add constraint voucher_party_id_fkey foreign key (party_id) references account;
--##
alter table voucher
    add constraint voucher_pos_counter_id_fkey foreign key (pos_counter_id) references pos_counter;
--##
alter table batch
    add constraint batch_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table batch
    add constraint batch_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table batch
    add constraint batch_reorder_inventory_id_fkey foreign key (reorder_inventory_id) references inventory;
--##
alter table batch
    add constraint batch_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table batch
    add constraint batch_division_id_fkey foreign key (division_id) references division;
--##
alter table batch
    add constraint batch_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table batch
    add constraint batch_manufacturer_id_fkey foreign key (manufacturer_id) references manufacturer;
--##
alter table batch
    add constraint batch_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table batch
    add constraint batch_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table batch
    add constraint batch_category1_id_fkey foreign key (category1_id) references category_option;
--##
alter table batch
    add constraint batch_category2_id_fkey foreign key (category2_id) references category_option;
--##
alter table batch
    add constraint batch_category3_id_fkey foreign key (category3_id) references category_option;
--##
alter table batch
    add constraint batch_category4_id_fkey foreign key (category4_id) references category_option;
--##
alter table batch
    add constraint batch_category5_id_fkey foreign key (category5_id) references category_option;
--##
alter table batch
    add constraint batch_category6_id_fkey foreign key (category6_id) references category_option;
--##
alter table batch
    add constraint batch_category7_id_fkey foreign key (category7_id) references category_option;
--##
alter table batch
    add constraint batch_category8_id_fkey foreign key (category8_id) references category_option;
--##
alter table batch
    add constraint batch_category9_id_fkey foreign key (category9_id) references category_option;
--##
alter table batch
    add constraint batch_category10_id_fkey foreign key (category10_id) references category_option;
--##
alter table account_daily_summary
    add constraint account_daily_summary_account_id_fkey foreign key (account_id) references account;
--##
alter table account_daily_summary
    add constraint account_daily_summary_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table ac_txn
    add constraint ac_txn_account_id_fkey foreign key (account_id) references account;
--##
alter table ac_txn
    add constraint ac_txn_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table ac_txn
    add constraint ac_txn_alt_account_id_fkey foreign key (alt_account_id) references account;
--##
alter table ac_txn
    add constraint ac_txn_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table ac_txn
    add constraint ac_txn_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table bill_allocation
    add constraint bill_allocation_account_id_fkey foreign key (account_id) references account;
--##
alter table bill_allocation
    add constraint bill_allocation_agent_fkey foreign key (agent_id) references account;
--##
alter table bill_allocation
    add constraint bill_allocation_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table bill_allocation
    add constraint bill_allocation_ac_txn_id_fkey foreign key (ac_txn_id) references ac_txn on delete cascade;
--##
alter table bill_allocation
    add constraint bill_allocation_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table bank_txn
    add constraint bank_txn_account_id_fkey foreign key (account_id) references account;
--##
alter table bank_txn
    add constraint bank_txn_alt_account_id_fkey foreign key (alt_account_id) references account;
--##
alter table bank_txn
    add constraint bank_txn_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table bank_txn
    add constraint bank_ac_txn_id_fkey foreign key (ac_txn_id) references ac_txn on delete cascade;
--##
alter table bank_txn
    add constraint bank_txn_bank_beneficiary_id_fkey foreign key (bank_beneficiary_id) references bank_beneficiary;
--##
alter table bank_txn
    add constraint bank_txn_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_account_id_fkey foreign key (account_id) references account;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table acc_cat_txn
    add constraint acc_cat_ac_txn_id_fkey foreign key (ac_txn_id) references ac_txn on delete cascade;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category1_id_fkey foreign key (category1_id) references category_option;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category2_id_fkey foreign key (category2_id) references category_option;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category3_id_fkey foreign key (category3_id) references category_option;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category4_id_fkey foreign key (category4_id) references category_option;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category5_id_fkey foreign key (category5_id) references category_option;
--##
alter table account_opening
    add constraint account_opening_account_id_fkey foreign key (account_id) references account;
--##
alter table account_opening
    add constraint account_opening_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table inventory_opening
    add constraint inventory_opening_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table inventory_opening
    add constraint inventory_opening_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table inventory_opening
    add constraint inventory_opening_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table inventory_opening
    add constraint inventory_opening_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table inv_txn
    add constraint inv_txn_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table inv_txn
    add constraint inv_txn_reorder_inventory_id_fkey foreign key (reorder_inventory_id) references inventory;
--##
alter table inv_txn
    add constraint inv_txn_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table inv_txn
    add constraint inv_txn_division_id_fkey foreign key (division_id) references division;
--##
alter table inv_txn
    add constraint inv_txn_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table inv_txn
    add constraint inv_txn_customer_id_fkey foreign key (customer_id) references customer;
--##
alter table inv_txn
    add constraint inv_txn_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table inv_txn
    add constraint inv_txn_batch_id_fkey foreign key (batch_id) references batch;
--##
alter table inv_txn
    add constraint inv_txn_manufacturer_id_fkey foreign key (manufacturer_id) references manufacturer;
--##
alter table inv_txn
    add constraint inv_txn_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table inv_txn
    add constraint inv_txn_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table inv_txn
    add constraint inv_txn_category1_id_fkey foreign key (category1_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category2_id_fkey foreign key (category2_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category3_id_fkey foreign key (category3_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category4_id_fkey foreign key (category4_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category5_id_fkey foreign key (category5_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category6_id_fkey foreign key (category6_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category7_id_fkey foreign key (category7_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category8_id_fkey foreign key (category8_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category9_id_fkey foreign key (category9_id) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category10_id_fkey foreign key (category10_id) references category_option;
--##
alter table gst_txn
    add constraint gst_txn_party_id_fkey foreign key (party_id) references account;
--##
alter table gst_txn
    add constraint gst_txn_uqc_id_fkey foreign key (uqc_id) references uqc;
--##
alter table gst_txn
    add constraint gst_txn_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table gst_txn
    add constraint gst_ac_txn_id_fkey foreign key (ac_txn_id) references ac_txn on delete cascade;
--##
alter table gst_txn
    add constraint gst_txn_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table gst_txn
    add constraint gst_txn_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table gst_txn
    add constraint gst_txn_branch_location_id_fkey foreign key (branch_location_id) references country;
--##
alter table gst_txn
    add constraint gst_txn_party_location_id_fkey foreign key (party_location_id) references country;
--##
alter table gst_txn
    add constraint gst_txn_gst_tax_id_fkey foreign key (gst_tax_id) references gst_tax;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_party_account_id_fkey foreign key (party_account_id) references account;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_tds_account_id_fkey foreign key (tds_account_id) references account;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table tds_on_voucher
    add constraint tds_on_tds_nature_of_payment_id_fkey foreign key (tds_nature_of_payment_id) references tds_nature_of_payment;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_tds_deductee_type_id_fkey foreign key (tds_deductee_type_id) references tds_deductee_type;
--##
alter table exchange
    add constraint exchange_account_id_fkey foreign key (account_id) references account;
--##
alter table exchange
    add constraint exchange_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table exchange
    add constraint exchange_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table exchange_adjustment
    add constraint exchange_adjustment_exchange_id_fkey foreign key (exchange_id) references exchange on delete cascade;
--##
alter table exchange_adjustment
    add constraint exchange_adjustment_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table goods_inward_note
    add constraint goods_inward_note_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table goods_inward_note
    add constraint goods_inward_note_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table goods_inward_note
    add constraint goods_inward_note_division_id_fkey foreign key (division_id) references division;
--##
alter table goods_inward_note
    add constraint goods_inward_note_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table goods_inward_note
    add constraint goods_inward_note_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table goods_inward_note
    add constraint goods_inward_note_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table goods_inward_note
    add constraint goods_inward_note_transport_id_fkey foreign key (transport_id) references transport;
--##
alter table goods_inward_note
    add constraint goods_inward_note_state_id_fkey foreign key (state_id) references country;
--##
alter table approval_log
    add constraint approval_log_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table approval_log
    add constraint approval_log_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table approval_log
    add constraint approval_log_member_id_fkey foreign key (member_id) references member;
--##
alter table gift_voucher
    add constraint gift_voucher_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table gift_voucher
    add constraint gift_voucher_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table gift_voucher
    add constraint gift_voucher_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table purchase_bill
    add constraint purchase_bill_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table gift_voucher
    add constraint gift_voucher_gift_voucher_account_id_fkey foreign key (gift_voucher_account_id) references account;
--##
alter table gift_voucher
    add constraint gift_voucher_party_account_id_fkey foreign key (party_account_id) references account;
--##
alter table purchase_bill
    add constraint purchase_bill_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table purchase_bill
    add constraint purchase_bill_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table purchase_bill
    add constraint purchase_bill_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table purchase_bill
    add constraint purchase_bill_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table purchase_bill
    add constraint purchase_bill_party_account_id_fkey foreign key (party_account_id) references account;
--##
alter table purchase_bill
    add constraint purchase_bill_exchange_account_id_fkey foreign key (exchange_account_id) references account;
--##
alter table purchase_bill
    add constraint purchase_bill_gin_voucher_id_fkey foreign key (gin_voucher_id) references voucher;
--##
alter table debit_note
    add constraint debit_note_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table debit_note
    add constraint debit_note_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table debit_note
    add constraint debit_note_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table debit_note
    add constraint debit_note_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table debit_note
    add constraint debit_note_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table debit_note
    add constraint debit_note_party_account_id_fkey foreign key (party_account_id) references account;
--##
alter table debit_note
    add constraint debit_note_purchase_bill_voucher_id_fkey foreign key (purchase_bill_voucher_id) references voucher;
--##
alter table sale_bill
    add constraint sale_bill_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table sale_bill
    add constraint sale_bill_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table sale_bill
    add constraint sale_bill_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table sale_bill
    add constraint sale_bill_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table sale_bill
    add constraint sale_bill_customer_id_fkey foreign key (customer_id) references customer;
--##
alter table sale_bill
    add constraint sale_bill_customer_group_id_fkey foreign key (customer_group_id) references tag;
--##
alter table sale_bill
    add constraint sale_bill_doctor_id_fkey foreign key (doctor_id) references doctor;
--##
alter table sale_bill
    add constraint sale_bill_bank_account_id_fkey foreign key (bank_account_id) references account;
--##
alter table sale_bill
    add constraint sale_bill_cash_account_id_fkey foreign key (cash_account_id) references account;
--##
alter table sale_bill
    add constraint sale_bill_credit_account_id_fkey foreign key (credit_account_id) references account;
--##
alter table sale_bill
    add constraint sale_bill_eft_account_id_fkey foreign key (eft_account_id) references account;
--##
alter table sale_bill
    add constraint sale_bill_pos_counter_id_fkey foreign key (pos_counter_id) references pos_counter;
--##
alter table credit_note
    add constraint credit_note_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table credit_note
    add constraint credit_note_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table credit_note
    add constraint credit_note_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table credit_note
    add constraint credit_note_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table credit_note
    add constraint credit_note_sale_bill_voucher_id_fkey foreign key (sale_bill_voucher_id) references voucher;
--##
alter table credit_note
    add constraint credit_note_customer_id_fkey foreign key (customer_id) references customer;
--##
alter table credit_note
    add constraint credit_note_bank_account_id_fkey foreign key (bank_account_id) references account;
--##
alter table credit_note
    add constraint credit_note_exchange_account_id_fkey foreign key (exchange_account_id) references account;
--##
alter table credit_note
    add constraint credit_note_cash_account_id_fkey foreign key (cash_account_id) references account;
--##
alter table credit_note
    add constraint credit_note_credit_account_id_fkey foreign key (credit_account_id) references account;
--##
alter table credit_note
    add constraint credit_note_pos_counter_id_fkey foreign key (pos_counter_id) references pos_counter;
--##
alter table material_conversion
    add constraint material_conversion_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table material_conversion
    add constraint material_conversion_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table material_conversion
    add constraint material_conversion_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table material_conversion
    add constraint material_conversion_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table stock_adjustment
    add constraint stock_adjustment_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table stock_adjustment
    add constraint stock_adjustment_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table stock_adjustment
    add constraint stock_adjustment_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table stock_adjustment
    add constraint stock_adjustment_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table customer_advance
    add constraint customer_advance_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table customer_advance
    add constraint customer_advance_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table customer_advance
    add constraint customer_advance_advance_account_id_fkey foreign key (advance_account_id) references account;
--##
alter table customer_advance
    add constraint customer_advance_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_batch_id_fkey foreign key (batch_id) references batch;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_personal_use_purchase_id_fkey foreign key (personal_use_purchase_id) references personal_use_purchase on delete cascade;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_gst_tax_id_fkey foreign key (gst_tax_id) references gst_tax;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_expense_account_id_fkey foreign key (expense_account_id) references account;
--##
alter table stock_addition
    add constraint stock_addition_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table stock_addition
    add constraint stock_addition_alt_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table stock_addition
    add constraint stock_addition_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table stock_addition
    add constraint stock_addition_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table stock_addition
    add constraint stock_addition_alt_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table stock_addition
    add constraint stock_addition_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table stock_addition
    add constraint stock_addition_deduction_voucher_id_fkey foreign key (deduction_voucher_id) references voucher;
--##
alter table stock_deduction
    add constraint stock_deduction_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table stock_deduction
    add constraint stock_deduction_alt_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table stock_deduction
    add constraint stock_deduction_voucher_id_fkey foreign key (voucher_id) references voucher;
--##
alter table stock_deduction
    add constraint stock_deduction_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table stock_deduction
    add constraint stock_deduction_alt_warehouse_id_fkey foreign key (warehouse_id) references warehouse;
--##
alter table stock_deduction
    add constraint stock_deduction_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table purchase_bill_inv_item
    add constraint purchase_bill_inv_item_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table purchase_bill_inv_item
    add constraint purchase_bill_inv_item_purchase_bill_id_fkey foreign key (purchase_bill_id) references purchase_bill on delete cascade;
--##
alter table purchase_bill_inv_item
    add constraint purchase_bill_inv_item_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table purchase_bill_inv_item
    add constraint purchase_bill_inv_item_gst_tax_id_fkey foreign key (gst_tax_id) references gst_tax;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_batch_id_fkey foreign key (batch_id) references batch;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_sale_bill_id_fkey foreign key (sale_bill_id) references sale_bill on delete cascade;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_gst_tax_id_fkey foreign key (gst_tax_id) references gst_tax;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_s_inc_id_fkey foreign key (s_inc_id) references sale_incharge on delete set null;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_batch_id_fkey foreign key (batch_id) references batch;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_credit_note_id_fkey foreign key (credit_note_id) references credit_note on delete cascade;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_gst_tax_id_fkey foreign key (gst_tax_id) references gst_tax;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_s_inc_id_fkey foreign key (s_inc_id) references sale_incharge on delete set null;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_batch_id_fkey foreign key (batch_id) references batch;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_debit_note_id_fkey foreign key (debit_note_id) references debit_note on delete cascade;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_gst_tax_id_fkey foreign key (gst_tax_id) references gst_tax;
--##
alter table stock_adjustment_inv_item
    add constraint stock_adjustment_inv_item_batch_id_fkey foreign key (batch_id) references batch;
--##
alter table stock_adjustment_inv_item
    add constraint stock_adjustment_inv_item_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table stock_adjustment_inv_item
    add constraint stock_adjustment_inv_item_stock_adjustment_id_fkey foreign key (stock_adjustment_id) references stock_adjustment on delete cascade;
--##
alter table stock_adjustment_inv_item
    add constraint stock_adjustment_inv_item_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table stock_deduction_inv_item
    add constraint stock_deduction_inv_item_batch_id_fkey foreign key (batch_id) references batch;
--##
alter table stock_deduction_inv_item
    add constraint stock_deduction_inv_item_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table stock_deduction_inv_item
    add constraint stock_deduction_inv_item_stock_deduction_id_fkey foreign key (stock_deduction_id) references stock_deduction on delete cascade;
--##
alter table stock_deduction_inv_item
    add constraint stock_deduction_inv_item_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table stock_addition_inv_item
    add constraint stock_addition_inv_item_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table stock_addition_inv_item
    add constraint stock_addition_inv_item_stock_addition_id_fkey foreign key (stock_addition_id) references stock_addition on delete cascade;
--##
alter table stock_addition_inv_item
    add constraint stock_addition_inv_item_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_source_inventory_id_fkey foreign key (source_inventory_id) references inventory;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_source_batch_id_fkey foreign key (source_batch_id) references batch;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_target_inventory_id_fkey foreign key (target_inventory_id) references inventory;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_material_conversion_id_fkey foreign key (material_conversion_id) references material_conversion on delete cascade;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_source_unit_id_fkey foreign key (source_unit_id) references unit;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_target_unit_id_fkey foreign key (target_unit_id) references unit;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_target_gst_tax_id_fkey foreign key (target_gst_tax_id) references gst_tax;
--##
alter table vendor_bill_map
    add constraint vendor_bill_map_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table vendor_item_map
    add constraint vendor_item_map_vendor_id_fkey foreign key (vendor_id) references vendor;
--##
alter table vendor_item_map
    add constraint vendor_item_map_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table pos_counter_settlement
    add constraint pos_counter_settlement_pos_counter_id_fkey foreign key (pos_counter_id) references pos_counter on delete cascade;
--##
alter table pos_counter_settlement
    add constraint pos_counter_settlement_created_by_fkey foreign key (created_by) references member;
--##
alter table pos_counter_transaction
    add constraint pos_counter_transaction_pos_counter_id_fkey foreign key (pos_counter_id) references pos_counter on delete cascade;
--##
alter table pos_counter_transaction
    add constraint pos_counter_transaction_branch_id_fkey foreign key (branch_id) references branch;
--##
alter table pos_counter_transaction
    add constraint pos_counter_transaction_voucher_id_fkey foreign key (voucher_id) references voucher on delete cascade;
--##
alter table pos_counter_transaction
    add constraint pos_counter_transaction_voucher_type_id_fkey foreign key (voucher_type_id) references voucher_type;
--##
alter table pos_counter_transaction
    add constraint pos_counter_transaction_settlement_id_fkey foreign key (settlement_id) references pos_counter_settlement on delete cascade;
--##
alter table pos_counter_transaction_breakup
    add constraint pos_counter_transaction_breakup_voucher_id_fkey foreign key (voucher_id) references pos_counter_transaction on delete cascade;
--##
alter table pos_counter_transaction_breakup
    add constraint pos_counter_transaction_breakup_account_id_fkey foreign key (account_id) references account;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category1_id_fkey foreign key (category1_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category2_id_fkey foreign key (category2_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category3_id_fkey foreign key (category3_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category4_id_fkey foreign key (category4_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category5_id_fkey foreign key (category5_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category6_id_fkey foreign key (category6_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category7_id_fkey foreign key (category7_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category8_id_fkey foreign key (category8_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category9_id_fkey foreign key (category9_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_category10_id_fkey foreign key (category10_id) references category_option;
--##
alter table offer_management_reward
    add constraint offer_management_reward_inventory_id_fkey foreign key (inventory_id) references inventory;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category1_id_fkey foreign key (category1_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category2_id_fkey foreign key (category2_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category3_id_fkey foreign key (category3_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category4_id_fkey foreign key (category4_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category5_id_fkey foreign key (category5_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category6_id_fkey foreign key (category6_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category7_id_fkey foreign key (category7_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category8_id_fkey foreign key (category8_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category9_id_fkey foreign key (category9_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_category10_id_fkey foreign key (category10_id) references category_option;
--##
alter table offer_management_condition
    add constraint offer_management_condition_inventory_id_fkey foreign key (inventory_id) references inventory;
