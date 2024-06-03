alter table warehouse
    add constraint warehouse_state_fkey foreign key (state) references country;
--##
alter table warehouse
    add constraint warehouse_country_fkey foreign key (country) references country;
--##
alter table price_list
    add constraint price_list_customer_tag_fkey foreign key (customer_tag) references tag;
--##
alter table account
    add constraint account_account_type_fkey foreign key (account_type) references account_type;
--##
alter table account
    add constraint account_state_id_fkey foreign key (state_id) references country;
--##
alter table account
    add constraint account_country_id_fkey foreign key (country_id) references country;
--##
alter table account
    add constraint account_bank_beneficiary_fkey foreign key (bank_beneficiary) references bank_beneficiary;
--##
alter table account
    add constraint account_gst_tax_fkey foreign key (gst_tax) references gst_tax;
--##
alter table account
    add constraint account_tds_nature_of_payment_fkey foreign key (tds_nature_of_payment) references tds_nature_of_payment;
--##
alter table account
    add constraint account_tds_deductee_type_fkey foreign key (tds_deductee_type) references tds_deductee_type;
--##
alter table account
    add constraint account_gst_location_id_fkey foreign key (gst_location_id) references country;
--##
alter table customer
    add constraint customer_gst_location_fkey foreign key (gst_location) references country;
--##
alter table customer
    add constraint customer_state_fkey foreign key (state) references country;
--##
alter table customer
    add constraint customer_country_fkey foreign key (country) references country;
--##
alter table customer
    add constraint customer_bank_beneficiary_fkey foreign key (bank_beneficiary) references bank_beneficiary;
--##
alter table customer
    add constraint customer_credit_account_fkey foreign key (credit_account) references account;
--##
alter table customer
    add constraint customer_agent_fkey foreign key (agent) references account;
--##
alter table customer
    add constraint customer_commission_account_fkey foreign key (commission_account) references account;
--##
alter table vendor
    add constraint vendor_gst_location_fkey foreign key (gst_location) references country;
--##
alter table vendor
    add constraint vendor_state_fkey foreign key (state) references country;
--##
alter table vendor
    add constraint vendor_country_fkey foreign key (country) references country;
--##
alter table vendor
    add constraint vendor_bank_beneficiary_fkey foreign key (bank_beneficiary) references bank_beneficiary;
--##
alter table vendor
    add constraint vendor_credit_account_fkey foreign key (credit_account) references account;
--##
alter table vendor
    add constraint vendor_agent_fkey foreign key (agent) references account;
--##
alter table vendor
    add constraint vendor_commission_account_fkey foreign key (commission_account) references account;
--##
alter table vendor
    add constraint vendor_tds_deductee_type_fkey foreign key (tds_deductee_type) references tds_deductee_type;
--##
alter table gst_registration
    add constraint gst_registration_state_fkey foreign key (state) references country;
--##
alter table branch
    add constraint branch_gst_registration_fkey foreign key (gst_registration) references gst_registration;
--##
alter table branch
    add constraint branch_state_fkey foreign key (state) references country;
--##
alter table branch
    add constraint branch_country_fkey foreign key (country) references country;
--##
alter table branch
    add constraint branch_account_fkey foreign key (account) references account;
--##
alter table stock_value
    add constraint stock_value_branch_fkey foreign key (branch) references branch;
--##
alter table offer_management
    add constraint offer_management_price_list_fkey foreign key (price_list) references price_list;
--##
alter table offer_management
    add constraint offer_management_branch_fkey foreign key (branch) references branch;
--##
alter table gift_coupon
    add constraint gift_coupon_gift_voucher_fkey foreign key (gift_voucher) references gift_voucher on delete cascade;
--##
alter table gift_coupon
    add constraint gift_coupon_gift_voucher_account_fkey foreign key (gift_voucher_account) references account;
--##
alter table gift_coupon
    add constraint gift_coupon_branch_fkey foreign key (branch) references branch;
--##
alter table pos_server
    add constraint pos_server_branch_fkey foreign key (branch) references branch;
--##
alter table unit
    add constraint unit_uqc_fkey foreign key (uqc) references uqc;
--##
alter table category_option
    add constraint category_option_category_fkey foreign key (category) references category;
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
    add constraint inventory_manufacturer_fkey foreign key (manufacturer) references manufacturer;
--##
alter table inventory
    add constraint inventory_vendor_fkey foreign key (vendor) references vendor;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_inventory_fkey foreign key (inventory) references inventory;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_reorder_inventory_fkey foreign key (reorder_inventory) references inventory;    
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_branch_fkey foreign key (branch) references branch;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_stock_location_fkey foreign key (stock_location) references stock_location;
--##
alter table inventory_branch_detail
    add constraint inventory_branch_detail_vendor_fkey foreign key (vendor) references vendor;
--##
alter table voucher_numbering
    add constraint voucher_numbering_branch_fkey foreign key (branch) references branch;
--##
alter table voucher_numbering
    add constraint voucher_numbering_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table voucher_numbering
    add constraint voucher_numbering_f_year_fkey foreign key (f_year) references financial_year;
--##
alter table voucher
    add constraint voucher_branch_fkey foreign key (branch) references branch;
--##
alter table voucher
    add constraint voucher_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table voucher
    add constraint voucher_party_fkey foreign key (party) references account;
--##
alter table batch
    add constraint batch_branch_fkey foreign key (branch) references branch;
--##
alter table batch
    add constraint batch_inventory_fkey foreign key (inventory) references inventory;
--##
alter table batch
    add constraint batch_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table batch
    add constraint batch_division_fkey foreign key (division) references division;
--##
alter table batch
    add constraint batch_unit_id_fkey foreign key (unit_id) references unit;
--##
alter table batch
    add constraint batch_manufacturer_fkey foreign key (manufacturer) references manufacturer;
--##
alter table batch
    add constraint batch_vendor_fkey foreign key (vendor) references vendor;
--##
alter table batch
    add constraint batch_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table batch
    add constraint batch_category1_fkey foreign key (category1) references category_option;
--##
alter table batch
    add constraint batch_category2_fkey foreign key (category2) references category_option;
--##
alter table batch
    add constraint batch_category3_fkey foreign key (category3) references category_option;
--##
alter table batch
    add constraint batch_category4_fkey foreign key (category4) references category_option;
--##
alter table batch
    add constraint batch_category5_fkey foreign key (category5) references category_option;
--##
alter table batch
    add constraint batch_category6_fkey foreign key (category6) references category_option;
--##
alter table batch
    add constraint batch_category7_fkey foreign key (category7) references category_option;
--##
alter table batch
    add constraint batch_category8_fkey foreign key (category8) references category_option;
--##
alter table batch
    add constraint batch_category9_fkey foreign key (category9) references category_option;
--##
alter table batch
    add constraint batch_category10_fkey foreign key (category10) references category_option;
--##
alter table account_daily_summary
    add constraint account_daily_summary_account_fkey foreign key (account) references account;
--##
alter table account_daily_summary
    add constraint account_daily_summary_branch_fkey foreign key (branch) references branch;
--##
alter table account_daily_summary
    add constraint account_daily_summary_account_type_fkey foreign key (account_type) references account_type;
--##
alter table ac_txn
    add constraint ac_txn_account_fkey foreign key (account) references account;
--##
alter table ac_txn
    add constraint ac_txn_account_type_fkey foreign key (account_type) references account_type;
--##
alter table ac_txn
    add constraint ac_txn_branch_fkey foreign key (branch) references branch;
--##
alter table ac_txn
    add constraint ac_txn_alt_account_fkey foreign key (alt_account) references account;
--##
alter table ac_txn
    add constraint ac_txn_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table ac_txn
    add constraint ac_txn_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table bill_allocation
    add constraint bill_allocation_account_fkey foreign key (account) references account;
--##
alter table bill_allocation
    add constraint bill_allocation_account_type_fkey foreign key (account_type) references account_type;
--##
alter table bill_allocation
    add constraint bill_allocation_agent_fkey foreign key (agent) references account;
--##
alter table bill_allocation
    add constraint bill_allocation_branch_fkey foreign key (branch) references branch;
--##
alter table bill_allocation
    add constraint bill_allocation_ac_txn_fkey foreign key (ac_txn) references ac_txn on delete cascade;
--##
alter table bill_allocation
    add constraint bill_allocation_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table bank_txn
    add constraint bank_txn_account_fkey foreign key (account) references account;
--##
alter table bank_txn
    add constraint bank_txn_account_type_fkey foreign key (account_type) references account_type;
--##
alter table bank_txn
    add constraint bank_txn_alt_account_fkey foreign key (alt_account) references account;
--##
alter table bank_txn
    add constraint bank_txn_branch_fkey foreign key (branch) references branch;
--##
alter table bank_txn
    add constraint bank_ac_txn_fkey foreign key (ac_txn) references ac_txn on delete cascade;
--##
alter table bank_txn
    add constraint bank_bank_beneficiary_fkey foreign key (bank_beneficiary) references bank_beneficiary;
--##
alter table bank_txn
    add constraint bank_txn_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_account_fkey foreign key (account) references account;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_account_type_fkey foreign key (account_type) references account_type;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_branch_fkey foreign key (branch) references branch;
--##
alter table acc_cat_txn
    add constraint acc_cat_ac_txn_fkey foreign key (ac_txn) references ac_txn on delete cascade;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category1_fkey foreign key (category1) references category_option;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category2_fkey foreign key (category2) references category_option;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category3_fkey foreign key (category3) references category_option;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category4_fkey foreign key (category4) references category_option;
--##
alter table acc_cat_txn
    add constraint acc_cat_txn_category5_fkey foreign key (category5) references category_option;
--##
alter table account_opening
    add constraint account_opening_account_fkey foreign key (account) references account;
--##
alter table account_opening
    add constraint account_opening_branch_fkey foreign key (branch) references branch;
--##
alter table inventory_opening
    add constraint inventory_opening_inventory_fkey foreign key (inventory) references inventory;
--##
alter table inventory_opening
    add constraint inventory_opening_branch_fkey foreign key (branch) references branch;
--##
alter table inventory_opening
    add constraint inventory_opening_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table inventory_opening
    add constraint inventory_opening_unit_fkey foreign key (unit) references unit;
--##
alter table inv_txn
    add constraint inv_txn_inventory_fkey foreign key (inventory) references inventory;
--##
alter table inv_txn
    add constraint inv_txn_reorder_inventory_fkey foreign key (reorder_inventory) references inventory;
--##
alter table inv_txn
    add constraint inv_txn_branch_fkey foreign key (branch) references branch;
--##
alter table inv_txn
    add constraint inv_txn_division_fkey foreign key (division) references division;
--##
alter table inv_txn
    add constraint inv_txn_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table inv_txn
    add constraint inv_txn_customer_fkey foreign key (customer) references customer;
--##
alter table inv_txn
    add constraint inv_txn_vendor_fkey foreign key (vendor) references vendor;
--##
alter table inv_txn
    add constraint inv_txn_batch_fkey foreign key (batch) references batch;
--##
alter table inv_txn
    add constraint inv_txn_manufacturer_fkey foreign key (manufacturer) references manufacturer;
--##
alter table inv_txn
    add constraint inv_txn_voucher_fkey foreign key (voucher) references voucher;
--##
alter table inv_txn
    add constraint inv_txn_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table inv_txn
    add constraint inv_txn_category1_fkey foreign key (category1) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category2_fkey foreign key (category2) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category3_fkey foreign key (category3) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category4_fkey foreign key (category4) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category5_fkey foreign key (category5) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category6_fkey foreign key (category6) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category7_fkey foreign key (category7) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category8_fkey foreign key (category8) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category9_fkey foreign key (category9) references category_option;
--##
alter table inv_txn
    add constraint inv_txn_category10_fkey foreign key (category10) references category_option;
--##
alter table gst_txn
    add constraint gst_txn_party_fkey foreign key (party) references account;
--##
alter table gst_txn
    add constraint gst_txn_uqc_fkey foreign key (uqc) references uqc;
--##
alter table gst_txn
    add constraint gst_txn_branch_fkey foreign key (branch) references branch;
--##
alter table gst_txn
    add constraint gst_ac_txn_fkey foreign key (ac_txn) references ac_txn on delete cascade;
--##
alter table gst_txn
    add constraint gst_txn_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table gst_txn
    add constraint gst_txn_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table gst_txn
    add constraint gst_txn_branch_location_fkey foreign key (branch_location) references country;
--##
alter table gst_txn
    add constraint gst_txn_party_location_fkey foreign key (party_location) references country;
--##
alter table gst_txn
    add constraint gst_txn_gst_tax_fkey foreign key (gst_tax) references gst_tax;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_party_account_fkey foreign key (party_account) references account;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_tds_account_fkey foreign key (tds_account) references account;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_branch_fkey foreign key (branch) references branch;
--##
alter table tds_on_voucher
    add constraint tds_on_tds_nature_of_payment_fkey foreign key (tds_nature_of_payment) references tds_nature_of_payment;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table tds_on_voucher
    add constraint tds_on_voucher_tds_deductee_type_fkey foreign key (tds_deductee_type) references tds_deductee_type;
--##
alter table exchange
    add constraint exchange_account_fkey foreign key (account) references account;
--##
alter table exchange
    add constraint exchange_branch_fkey foreign key (branch) references branch;
--##
alter table exchange
    add constraint exchange_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table exchange_adjustment
    add constraint exchange_adjustment_exchange_fkey foreign key (exchange) references exchange on delete cascade;
--##
alter table exchange_adjustment
    add constraint exchange_adjustment_voucher_fkey foreign key (voucher) references voucher on delete cascade;
--##
alter table goods_inward_note
    add constraint goods_inward_note_vendor_fkey foreign key (vendor) references vendor;
--##
alter table goods_inward_note
    add constraint goods_inward_note_branch_fkey foreign key (branch) references branch;
--##
alter table goods_inward_note
    add constraint goods_inward_note_division_fkey foreign key (division) references division;
--##
alter table goods_inward_note
    add constraint goods_inward_note_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table goods_inward_note
    add constraint goods_inward_note_voucher_fkey foreign key (voucher) references voucher;
--##
alter table goods_inward_note
    add constraint goods_inward_note_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table goods_inward_note
    add constraint goods_inward_note_transport_fkey foreign key (transport) references transport;
--##
alter table goods_inward_note
    add constraint goods_inward_note_state_fkey foreign key (state) references country;
--##
alter table approval_log
    add constraint approval_log_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table approval_log
    add constraint approval_log_member_fkey foreign key (member) references member;
--##
alter table gift_voucher
    add constraint gift_voucher_branch_fkey foreign key (branch) references branch;
--##
alter table gift_voucher
    add constraint gift_voucher_voucher_fkey foreign key (voucher) references voucher;
--##
alter table gift_voucher
    add constraint gift_voucher_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table purchase_bill
    add constraint purchase_bill_branch_fkey foreign key (branch) references branch;
--##
alter table gift_voucher
    add constraint gift_voucher_gift_voucher_account_fkey foreign key (gift_voucher_account) references account;
--##
alter table gift_voucher
    add constraint gift_voucher_party_account_fkey foreign key (party_account) references account;
--##
alter table purchase_bill
    add constraint purchase_bill_voucher_fkey foreign key (voucher) references voucher;
--##
alter table purchase_bill
    add constraint purchase_bill_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table purchase_bill
    add constraint purchase_bill_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table purchase_bill
    add constraint purchase_bill_vendor_fkey foreign key (vendor) references vendor;
--##
alter table purchase_bill
    add constraint purchase_bill_party_account_fkey foreign key (party_account) references account;
--##
alter table purchase_bill
    add constraint purchase_bill_exchange_account_fkey foreign key (exchange_account) references account;
--##
alter table purchase_bill
    add constraint purchase_bill_gin_fkey foreign key (gin) references goods_inward_note;
--##
alter table debit_note
    add constraint debit_note_branch_fkey foreign key (branch) references branch;
--##
alter table debit_note
    add constraint debit_note_voucher_fkey foreign key (voucher) references voucher;
--##
alter table debit_note
    add constraint debit_note_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table debit_note
    add constraint debit_note_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table debit_note
    add constraint debit_note_vendor_fkey foreign key (vendor) references vendor;
--##
alter table debit_note
    add constraint debit_note_party_account_fkey foreign key (party_account) references account;
--##
alter table debit_note
    add constraint debit_note_purchase_bill_fkey foreign key (purchase_bill) references purchase_bill;
--##
alter table sale_bill
    add constraint sale_bill_branch_fkey foreign key (branch) references branch;
--##
alter table sale_bill
    add constraint sale_bill_voucher_fkey foreign key (voucher) references voucher;
--##
alter table sale_bill
    add constraint sale_bill_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table sale_bill
    add constraint sale_bill_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table sale_bill
    add constraint sale_bill_customer_fkey foreign key (customer) references customer;
--##
alter table sale_bill
    add constraint sale_bill_customer_group_fkey foreign key (customer_group) references tag;
--##
alter table sale_bill
    add constraint sale_bill_doctor_fkey foreign key (doctor) references doctor;
--##
alter table sale_bill
    add constraint sale_bill_bank_account_fkey foreign key (bank_account) references account;
--##
alter table sale_bill
    add constraint sale_bill_cash_account_fkey foreign key (cash_account) references account;
--##
alter table sale_bill
    add constraint sale_bill_credit_account_fkey foreign key (credit_account) references account;
--##
alter table sale_bill
    add constraint sale_bill_eft_account_fkey foreign key (eft_account) references account;
--##
alter table credit_note
    add constraint credit_note_branch_fkey foreign key (branch) references branch;
--##
alter table credit_note
    add constraint credit_note_voucher_fkey foreign key (voucher) references voucher;
--##
alter table credit_note
    add constraint credit_note_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table credit_note
    add constraint credit_note_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table credit_note
    add constraint credit_note_sale_id_fkey foreign key (sale_id) references sale_bill;
--##
alter table credit_note
    add constraint credit_note_customer_fkey foreign key (customer) references customer;
--##
alter table credit_note
    add constraint credit_note_bank_account_fkey foreign key (bank_account) references account;
--##
alter table credit_note
    add constraint credit_note_exchange_account_fkey foreign key (exchange_account) references account;
--##
alter table credit_note
    add constraint credit_note_cash_account_fkey foreign key (cash_account) references account;
--##
alter table credit_note
    add constraint credit_note_credit_account_fkey foreign key (credit_account) references account;
--##
alter table material_conversion
    add constraint material_conversion_branch_fkey foreign key (branch) references branch;
--##
alter table material_conversion
    add constraint material_conversion_voucher_fkey foreign key (voucher) references voucher;
--##
alter table material_conversion
    add constraint material_conversion_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table material_conversion
    add constraint material_conversion_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table stock_adjustment
    add constraint stock_adjustment_branch_fkey foreign key (branch) references branch;
--##
alter table stock_adjustment
    add constraint stock_adjustment_voucher_fkey foreign key (voucher) references voucher;
--##
alter table stock_adjustment
    add constraint stock_adjustment_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table stock_adjustment
    add constraint stock_adjustment_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table customer_advance
    add constraint customer_advance_branch_fkey foreign key (branch) references branch;
--##
alter table customer_advance
    add constraint customer_advance_voucher_fkey foreign key (voucher) references voucher;
--##
alter table customer_advance
    add constraint customer_advance_advance_account_fkey foreign key (advance_account) references account;
--##
alter table customer_advance
    add constraint customer_advance_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_batch_fkey foreign key (batch) references batch;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_inventory_fkey foreign key (inventory) references inventory;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_personal_use_purchase_fkey foreign key (personal_use_purchase) references personal_use_purchase on delete cascade;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_gst_tax_fkey foreign key (gst_tax) references gst_tax;
--##
alter table personal_use_purchase_inv_item
    add constraint personal_use_purchase_inv_item_unit_fkey foreign key (unit) references unit;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_branch_fkey foreign key (branch) references branch;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_voucher_fkey foreign key (voucher) references voucher;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table personal_use_purchase
    add constraint personal_use_purchase_expense_account_fkey foreign key (expense_account) references account;
--##
alter table stock_addition
    add constraint stock_addition_branch_fkey foreign key (branch) references branch;
--##
alter table stock_addition
    add constraint stock_addition_alt_branch_fkey foreign key (branch) references branch;
--##
alter table stock_addition
    add constraint stock_addition_voucher_fkey foreign key (voucher) references voucher;
--##
alter table stock_addition
    add constraint stock_addition_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table stock_addition
    add constraint stock_addition_alt_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table stock_addition
    add constraint stock_addition_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table stock_addition
    add constraint stock_addition_deduction_id_fkey foreign key (deduction_id) references stock_deduction;
--##
alter table stock_deduction
    add constraint stock_deduction_branch_fkey foreign key (branch) references branch;
--##
alter table stock_deduction
    add constraint stock_deduction_alt_branch_fkey foreign key (branch) references branch;
--##
alter table stock_deduction
    add constraint stock_deduction_voucher_fkey foreign key (voucher) references voucher;
--##
alter table stock_deduction
    add constraint stock_deduction_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table stock_deduction
    add constraint stock_deduction_alt_warehouse_fkey foreign key (warehouse) references warehouse;
--##
alter table stock_deduction
    add constraint stock_deduction_voucher_type_fkey foreign key (voucher_type) references voucher_type;
--##
alter table purchase_bill_inv_item
    add constraint purchase_bill_inv_item_inventory_fkey foreign key (inventory) references inventory;
--##
alter table purchase_bill_inv_item
    add constraint purchase_bill_inv_item_purchase_bill_fkey foreign key (purchase_bill) references purchase_bill on delete cascade;
--##
alter table purchase_bill_inv_item
    add constraint purchase_bill_inv_item_unit_fkey foreign key (unit) references unit;
--##
alter table purchase_bill_inv_item
    add constraint purchase_bill_inv_item_gst_tax_fkey foreign key (gst_tax) references gst_tax;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_inventory_fkey foreign key (inventory) references inventory;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_batch_fkey foreign key (batch) references batch;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_sale_bill_fkey foreign key (sale_bill) references sale_bill on delete cascade;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_unit_fkey foreign key (unit) references unit;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_gst_tax_fkey foreign key (gst_tax) references gst_tax;
--##
alter table sale_bill_inv_item
    add constraint sale_bill_inv_item_s_inc_fkey foreign key (s_inc) references sale_incharge on delete set null;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_batch_fkey foreign key (batch) references batch;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_inventory_fkey foreign key (inventory) references inventory;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_credit_note_fkey foreign key (credit_note) references credit_note on delete cascade;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_unit_fkey foreign key (unit) references unit;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_gst_tax_fkey foreign key (gst_tax) references gst_tax;
--##
alter table credit_note_inv_item
    add constraint credit_note_inv_item_s_inc_fkey foreign key (s_inc) references sale_incharge on delete set null;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_batch_fkey foreign key (batch) references batch;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_inventory_fkey foreign key (inventory) references inventory;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_debit_note_fkey foreign key (debit_note) references debit_note on delete cascade;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_unit_fkey foreign key (unit) references unit;
--##
alter table debit_note_inv_item
    add constraint debit_note_inv_item_gst_tax_fkey foreign key (gst_tax) references gst_tax;
--##
alter table stock_adjustment_inv_item
    add constraint stock_adjustment_inv_item_batch_fkey foreign key (batch) references batch;
--##
alter table stock_adjustment_inv_item
    add constraint stock_adjustment_inv_item_inventory_fkey foreign key (inventory) references inventory;
--##
alter table stock_adjustment_inv_item
    add constraint stock_adjustment_inv_item_stock_adjustment_fkey foreign key (stock_adjustment) references stock_adjustment on delete cascade;
--##
alter table stock_adjustment_inv_item
    add constraint stock_adjustment_inv_item_unit_fkey foreign key (unit) references unit;
--##
alter table stock_deduction_inv_item
    add constraint stock_deduction_inv_item_batch_fkey foreign key (batch) references batch;
--##
alter table stock_deduction_inv_item
    add constraint stock_deduction_inv_item_inventory_fkey foreign key (inventory) references inventory;
--##
alter table stock_deduction_inv_item
    add constraint stock_deduction_inv_item_stock_deduction_fkey foreign key (stock_deduction) references stock_deduction on delete cascade;
--##
alter table stock_deduction_inv_item
    add constraint stock_deduction_inv_item_unit_fkey foreign key (unit) references unit;
--##
alter table stock_addition_inv_item
    add constraint stock_addition_inv_item_inventory_fkey foreign key (inventory) references inventory;
--##
alter table stock_addition_inv_item
    add constraint stock_addition_inv_item_stock_addition_fkey foreign key (stock_addition) references stock_addition on delete cascade;
--##
alter table stock_addition_inv_item
    add constraint stock_addition_inv_item_unit_fkey foreign key (unit) references unit;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_source_inventory_fkey foreign key (source_inventory) references inventory;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_source_batch_fkey foreign key (source_batch) references batch;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_target_inventory_fkey foreign key (target_inventory) references inventory;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_material_conversion_fkey foreign key (material_conversion) references material_conversion on delete cascade;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_source_unit_fkey foreign key (source_unit) references unit;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_target_unit_fkey foreign key (target_unit) references unit;
--##
alter table material_conversion_inv_item
    add constraint material_conversion_inv_item_target_gst_tax_fkey foreign key (target_gst_tax) references gst_tax;
--##    
alter table vendor_bill_map
    add constraint vendor_bill_map_vendor_fkey foreign key (vendor) references vendor;
--##    
alter table vendor_item_map
    add constraint vendor_item_map_vendor_fkey foreign key (vendor) references vendor;
--##    
alter table vendor_item_map
    add constraint vendor_item_map_inventory_fkey foreign key (inventory) references inventory;