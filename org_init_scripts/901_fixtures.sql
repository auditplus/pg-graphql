insert into account_type (id, default_name, name, parent_id, allow_account, allow_sub_type,
                          base_types) overriding system value
values (1, 'CURRENT_ASSET', 'Current Asset', null, true, true, array ['CURRENT_ASSET']),
       (2, 'CURRENT_LIABILITY', 'Current Liability', null, true, true, array ['CURRENT_LIABILITY']),
       (3, 'DIRECT_INCOME', 'Direct Income', null, true, true, array ['DIRECT_INCOME']),
       (4, 'INDIRECT_INCOME', 'Indirect Income', null, true, true, array ['INDIRECT_INCOME']),
       (5, 'SALE', 'Sale', null, false, false, array ['SALE']),
       (6, 'DIRECT_EXPENSE', 'Direct Expense', null, true, true, array ['DIRECT_EXPENSE']),
       (7, 'INDIRECT_EXPENSE', 'Indirect Expense', null, true, true, array ['INDIRECT_EXPENSE']),
       (8, 'PURCHASE', 'Purchase', null, false, false, array ['PURCHASE']),
       (9, 'FIXED_ASSET', 'Fixed Asset', null, true, true, array ['FIXED_ASSET']),
       (10, 'LONGTERM_LIABILITY', 'Longterm Liability', null, true, true, array ['LONGTERM_LIABILITY']),
       (11, 'EQUITY', 'Equity', null, true, true, array ['EQUITY']),
       (12, 'STOCK', 'Stock', null, false, false, array ['STOCK']),
       (13, 'BANK_ACCOUNT', 'Bank Account', 1, true, false, array ['CURRENT_ASSET', 'BANK_ACCOUNT']),
       (14, 'EFT_ACCOUNT', 'EFT Account', 1, true, false, array ['CURRENT_ASSET', 'EFT_ACCOUNT']),
       (15, 'TDS_RECEIVABLE', 'Tds Receivable', 1, true, false, array ['CURRENT_ASSET', 'TDS_RECEIVABLE']),
       (16, 'SUNDRY_DEBTOR', 'Sundry Debtors', 1, true, true, array ['CURRENT_ASSET', 'SUNDRY_DEBTOR']),
       (17, 'CASH', 'Cash', 1, true, true, array ['CURRENT_ASSET', 'CASH']),
       (18, 'BANK_OD_ACCOUNT', 'Bank OD Account', 2, true, false, array ['CURRENT_LIABILITY', 'BANK_OD_ACCOUNT']),
       (19, 'SUNDRY_CREDITOR', 'Sundry Creditor', 2, true, true, array ['CURRENT_LIABILITY', 'SUNDRY_CREDITOR']),
       (20, 'BRANCH_OR_DIVISION', 'Branch / Division', 2, true, false,
        array ['CURRENT_LIABILITY', 'BRANCH_OR_DIVISION']),
       (21, 'TDS_PAYABLE', 'Tds Payable', 2, true, false, array ['CURRENT_LIABILITY', 'TDS_PAYABLE']),
       (22, 'DUTIES_AND_TAXES', 'Duties And Taxes', 2, true, false, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES']),
       (23, 'GST', 'Gst', 22, true, false, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES', 'GST']);
--##
insert into gst_tax
(id, name, cgst, sgst, igst) values
('gstna', 'Not Applicable', 0.0, 0.0, 0.0),
('gstexempt', 'GST Exempt', 0.0, 0.0, 0.0),
('gstngs', 'Non GST Supply', 0.0, 0.0, 0.0),
('gst0', 'GST 0%', 0.0, 0.0, 0.0),
('gst0p1', 'GST 0.1%', 0.05, 0.05, 0.1),
('gst0p25', 'GST 0.25%', 0.125, 0.125, 0.25),
('gst1', 'GST 1%', 0.5, 0.5, 1.0),
('gst1p5', 'GST 1.5%', 0.75, 0.75, 1.5),
('gst3', 'GST 3%', 1.5, 1.5, 3.0),
('gst5', 'GST 5%', 2.5, 2.5, 5.0),
('gst7p5', 'GST 7.5%', 3.75, 3.75, 7.5),
('gst12', 'GST 12%', 6.0, 6.0, 12.0),
('gst18', 'GST 18%', 9.0, 9.0, 18.0),
('gst28', 'GST 28%', 14.0, 14.0, 28.0);
--##
insert into account
(id, contact_type, name, account_type_id, gst_type, is_default, base_account_types,
 transaction_enabled) overriding system value
values (1, 'ACCOUNT', 'Cash', 17, null, true, array ['CURRENT_ASSET', 'CASH'], true),
       (2, 'ACCOUNT', 'Sales', 5, null, true, array ['SALE'], true),
       (3, 'ACCOUNT', 'Purchases', 8, null, true, array ['PURCHASE'], true),
       (4, 'ACCOUNT', 'CGST Payable', 22, 'CGST', true, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES'], true),
       (5, 'ACCOUNT', 'SGST Payable', 22, 'SGST', true, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES'], true),
       (6, 'ACCOUNT', 'IGST Payable', 22, 'IGST', true, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES'], true),
       (7, 'ACCOUNT', 'CESS Payable', 22, 'CESS', true, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES'], true),
       (8, 'ACCOUNT', 'CGST Receivable', 22, 'CGST', true, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES'], true),
       (9, 'ACCOUNT', 'SGST Receivable', 22, 'SGST', true, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES'], true),
       (10, 'ACCOUNT', 'IGST Receivable', 22, 'IGST', true, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES'], true),
       (11, 'ACCOUNT', 'CESS Receivable', 22, 'CESS', true, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES'], true),
       (12, 'ACCOUNT', 'Rounded Off', 4, null, true, array ['INDIRECT_INCOME'], true),
       (13, 'ACCOUNT', 'Discount Given', 7, null, true, array ['INDIRECT_EXPENSE'], true),
       (14, 'ACCOUNT', 'Discount Received', 4, null, true, array ['INDIRECT_INCOME'], true),
       (15, 'ACCOUNT', 'Gift Voucher Reimbursement', 2, null, true, array ['CURRENT_LIABILITY'], true),
       (16, 'ACCOUNT', 'Inventory Asset', 12, null, true, array ['STOCK'], true),
       (17, 'ACCOUNT', 'RCM Payable', 2, null, true, array ['CURRENT_LIABILITY'], true);
--##
insert into country
(id, name, country_id) values
('INDIA', 'India', null),
('01', 'Jammu And Kashmir', 'INDIA'),
('02', 'Himachal Pradesh', 'INDIA'),
('03', 'Punjab', 'INDIA'),
('04', 'Chandigarh', 'INDIA'),
('05', 'Uttarakhand', 'INDIA'),
('06', 'Haryana', 'INDIA'),
('07', 'Delhi', 'INDIA'),
('08', 'Rajasthan', 'INDIA'),
('09', 'Uttar Pradesh', 'INDIA'),
('10', 'Bihar', 'INDIA'),
('11', 'Sikkim', 'INDIA'),
('12', 'Arunachal Pradesh', 'INDIA'),
('13', 'Nagaland', 'INDIA'),
('14', 'Manipur', 'INDIA'),
('15', 'Mizoram', 'INDIA'),
('16', 'Tripura', 'INDIA'),
('17', 'Meghlaya', 'INDIA'),
('18', 'Assam', 'INDIA'),
('19', 'West Bengal', 'INDIA'),
('20', 'Jharkhand', 'INDIA'),
('21', 'Odisha', 'INDIA'),
('22', 'Chattisgarh', 'INDIA'),
('23', 'Madhya Pradesh', 'INDIA'),
('24', 'Gujarat', 'INDIA'),
('25', 'Daman And Diu', 'INDIA'),
('26', 'Dadra And Nagar Haveli', 'INDIA'),
('27', 'Maharashtra', 'INDIA'),
('28', 'Andhra Pradesh Old', 'INDIA'),
('29', 'Karnataka', 'INDIA'),
('30', 'Goa', 'INDIA'),
('31', 'Lakshwadeep', 'INDIA'),
('32', 'Kerala', 'INDIA'),
('33', 'TamilNadu', 'INDIA'),
('34', 'Puducherry', 'INDIA'),
('35', 'Andaman and Nicobar Islands', 'INDIA'),
('36', 'Telangana', 'INDIA'),
('37', 'Andhra Pradesh New', 'INDIA');
--##
insert into tds_deductee_type
(id, name) values
('ARTIFICIAL_JURIDICAL_PERSON','Artificial Juridical Person'),
('ASSOCIATION_OF_PERSONS','Association of Persons'),
('BODY_OF_INDIVIDUALS','Body of Individuals'),
('COMPANY_NON_RESIDENT','Company - Non Resident'),
('COMPANY_RESIDENT','Company - Resident'),
('CO_OPERATIVE_SOCIETY_NON_RESIDENT','Co-Operative Society - Non Resident'),
('CO_OPERATIVE_SOCIETY_RESIDENT','Co-Operative Society - Resident'),
('GOVERNMENT','Government'),
('INDIVIDUAL_HUF_NON_RESIDENT','Individual/HUF - Non Resident'),
('INDIVIDUAL_HUF_RESIDENT','Individual/HUF - Resident'),
('LOCAL_AUTHORITY','Local Authority'),
('PARTNERSHIP_FIRM','Partnership Firm');
--##
insert into uqc
(id,name) values
 ('BAG', 'BAG-BAGS'),
 ('BAL', 'BAL-BALE'),
 ('BDL', 'BDL-BUNDLES'),
 ('BKL', 'BKL-BUCKLES'),
 ('BOU', 'BOU-BILLION OF UNITS'),
 ('BOX', 'BOX-BOX'),
 ('BTL', 'BTL-BOTTLES'),
 ('BUN', 'BUN-BUNCHES'),
 ('CAN', 'CAN-CANS'),
 ('CBM', 'CBM-CUBIC METERS'),
 ('CCM', 'CCM-CUBIC CENTIMETERS'),
 ('CMS', 'CMS-CENTIMETERS'),
 ('CTN', 'CTN-CARTONS'),
 ('DOZ', 'DOZ-DOZENS'),
 ('DRM', 'DRM-DRUMS'),
 ('GGK', 'GGK-GREAT GROSS'),
 ('GMS', 'GMS-GRAMMES'),
 ('GRS', 'GRS-GROSS'),
 ('GYD', 'GYD-GROSS YARDS'),
 ('KGS', 'KGS-KILOGRAMS'),
 ('KLR', 'KLR-KILOLITRE'),
 ('KME', 'KME-KILOMETRE'),
 ('LTR', 'LTR-LITRES'),
 ('MLT', 'MLT-MILILITRE'),
 ('MTR', 'MTR-METERS'),
 ('MTS', 'MTS-METRIC TON'),
 ('NOS', 'NOS-NUMBERS'),
 ('PAC', 'PAC-PACKS'),
 ('PCS', 'PCS-PIECES'),
 ('PRS', 'PRS-PAIRS'),
 ('QTL', 'QTL-QUINTAL'),
 ('ROL', 'ROL-ROLLS'),
 ('SET', 'SET-SETS'),
 ('SQF', 'SQF-SQUARE FEET'),
 ('SQM', 'SQM-SQUARE METERS'),
 ('SQY', 'SQY-SQUARE YARDS'),
 ('TBS', 'TBS-TABLETS'),
 ('TGM', 'TGM-TEN GROSS'),
 ('THD', 'THD-THOUSANDS'),
 ('TON', 'TON-TONNES'),
 ('TUB', 'TUB-TUBES'),
 ('UGS', 'UGS-US GALLONS'),
 ('UNT', 'UNT-UNITS'),
 ('YDS', 'YDS-YARDS'),
 ('OTH', 'OTH-OTHERS');
--##
insert into category
(id, name, sort_order, sno, category_type) values
('INV_CAT1','Category 1',1,1,'INVENTORY'),
('INV_CAT2','Category 2',2,2,'INVENTORY'),
('INV_CAT3','Category 3',3,3,'INVENTORY'),
('INV_CAT4','Category 4',4,4,'INVENTORY'),
('INV_CAT5','Category 5',5,5,'INVENTORY'),
('INV_CAT6','Category 6',6,6,'INVENTORY'),
('INV_CAT7','Category 7',7,7,'INVENTORY'),
('INV_CAT8','Category 8',8,8,'INVENTORY'),
('INV_CAT9','Category 9',9,9,'INVENTORY'),
('INV_CAT10','Category 10',10,10,'INVENTORY'),
('ACC_CAT1','Category 1',1,1,'ACCOUNT'),
('ACC_CAT2','Category 2',2,2,'ACCOUNT'),
('ACC_CAT3','Category 3',3,3,'ACCOUNT'),
('ACC_CAT4','Category 4',4,4,'ACCOUNT'),
('ACC_CAT5','Category 5',5,5,'ACCOUNT');
--##
insert into warehouse (name) values ('Default');
--##
insert into voucher_type (id, name, config, is_default, base_type) overriding system value
values (1, 'Payment', '{ "payment": { "print_after_save": false, "pos_counter_transaction_only": false } }', true, 'PAYMENT'),
       (2, 'Receipt', '{ "receipt": { "print_after_save": false, "pos_counter_transaction_only": false } }', true, 'RECEIPT'),
       (3, 'Contra',  '{ "contra":  { "print_after_save": false } }', true, 'CONTRA'),
       (4, 'Journal', '{ "journal": { "print_after_save": false } }', true, 'JOURNAL'),
       (5, 'Sale', '{
         "sale": {
           "enable_e_invoice": false,
           "account": {
             "print_after_save": false
           },
           "inventory": {
             "pos_counter_transaction_only": false,
             "warehouse_enabled": false,
             "hide_rack": false,
             "hide_mrp_in_batch_modal": false,
             "rate_editable": false,
             "tax_editable": false,
             "discount_editable": false,
             "unit_editable": false,
             "bill_discount_editable": false,
             "print_after_save": false,
             "set_focus_on_inventory": false,
             "auto_select_batch": false,
             "set_default_qty": false,
             "enable_silent_print_mode": false,
             "enable_reminder_days": false,
             "enable_description": true,
             "enable_doctor": false,
             "allow_credit_customer": false,
             "enable_sales_person": false,
             "voucherwise_sales_person": false,
             "freeze_sales_person_for_voucher": false,
             "barcode_enabled": false,
             "customer_form_quick_create": false,
             "enable_exchange": false,
             "enable_advance": false,
             "enable_emi": false,
             "set_loose_qty": false
           }
         }
       }', true, 'SALE'),
       (6, 'Credit Note', '{
         "credit_note": {
           "account": {
             "print_after_save": false
           },
           "inventory": {
             "pos_counter_transaction_only": false,
             "warehouse_enabled": false,
             "rate_editable": false,
             "tax_editable": false,
             "discount_editable": false,
             "unit_editable": false,
             "bill_discount_editable": false,
             "print_after_save": false,
             "enable_silent_print_mode": false,
             "allow_credit_customer": false,
             "enable_sales_person": false,
             "voucherwise_sales_person": false,
             "freeze_sales_person_for_voucher": false,
             "barcode_enabled": false,
             "enable_exp": false,
             "customer_form_quick_create": false,
             "print_customer_copy": false,
             "invoice_no_required": false,
             "is_exchange_voucher": false
           }
         }
       }', true, 'CREDIT_NOTE'),
       (7, 'Purchase', '{
         "purchase": {
           "account": {
             "print_after_save": false
           },
           "inventory": {
             "print_after_save": false,
             "s_rate_mrp_required": false,
             "s_rate_as_mrp": false,
             "enable_silent_print_mode": false,
             "allow_credit_vendor": true,
             "barcode_enabled": false,
             "prevent_loss": false,
             "tax_hide": false,
             "enable_gin": false,
             "enable_expiry": false,
             "expiry_required": false,
             "is_exchange_voucher": false,
             "enable_bill_detail": true,
             "enable_automatic_rounded_off": false,
             "enable_weight_bill": false,
             "allow_new_ref_only": false,
             "bill_format": "NORMAL",
             "set_loose_qty": false
           }
         }
       }', true, 'PURCHASE'),
       (8, 'Debit Note', '{
         "debit_note": {
           "account": {
             "print_after_save": false
           },
           "inventory": {
             "cash_register_enabled": false,
             "warehouse_enabled": false,
             "rate_editable": false,
             "tax_editable": false,
             "discount_editable": false,
             "print_after_save": false,
             "enable_silent_print_mode": false,
             "allow_credit_vendor": false,
             "barcode_enabled": false,
             "enable_exp": false,
             "bill_no_required": false
           }
         }
       }', true, 'DEBIT_NOTE'),
       (9, 'Sale Quotation', '{
         "sale_quotation": {
           "rate_editable": false,
           "tax_editable": false,
           "discount_editable": false,
           "unit_editable": false,
           "bill_discount_editable": false,
           "enable_silent_print_mode": false,
           "print_after_save": false,
           "barcode_enabled": false,
           "enable_exp": false
         }
       }', true, 'SALE_QUOTATION'),
       (10, 'Stock Adjustment', '{
         "stock_adjustment": {
           "enable_silent_print_mode": false,
           "print_after_save": false,
           "barcode_enabled": false,
           "enable_exp": false
         }
       }', true, 'STOCK_ADJUSTMENT'),
       (11, 'Stock Deduction', '{
         "stock_deduction": {
           "enable_silent_print_mode": false,
           "print_after_save": false,
           "barcode_enabled": false,
           "enable_exp": false,
           "alt_branch_required": false
         }
       }', true, 'STOCK_DEDUCTION'),
       (12, 'Stock Addition', '{
         "stock_addition": {
           "enable_silent_print_mode": false,
           "print_after_save": false,
           "barcode_enabled": false,
           "enable_exp": false,
           "alt_branch_required": false
         }
       }', true, 'STOCK_ADDITION'),
       (13, 'Material Conversion', '{
         "material_conversion": {
           "enable_silent_print_mode": false,
           "print_after_save": false,
           "barcode_enabled": false,
           "enable_exp": false
         }
       }', true, 'MATERIAL_CONVERSION'),
       (14, 'Manufacturing Journal', '{
         "manufacturing_journal": {
           "barcode_enabled": false
         }
       }', true, 'MANUFACTURING_JOURNAL'),
       (15, 'Memo', '{
         "memo": {
           "expense_only": false,
           "print_after_save": false,
           "open_cheque_book_detail": false
         }
       }', true, 'MEMO'),
       (16, 'Wastage', '{
         "wastage": {
           "enable_silent_print_mode": false,
           "print_after_save": false,
           "barcode_enabled": false,
           "enable_exp": false
         }
       }', true, 'WASTAGE'),
       (17, 'Goods Inward Note', '{
         "goods_inward_note": {
           "print_after_save": false,
           "enable_silent_print_mode": false
         }
       }', true, 'GOODS_INWARD_NOTE'),
       (18, 'Gift Voucher', '{
         "gift_voucher": {
           "print_after_save": false,
           "enable_silent_print_mode": false
         }
       }', true, 'GIFT_VOUCHER'),
       (19, 'Purchased Goods For Personal Use', '{
         "personal_use_purchase": {
           "expense_account": null
         }
       }', true, 'PERSONAL_USE_PURCHASE'),
       (20, 'Customer Advance', '{
         "customer_advance": {
           "print_after_save": false,
           "enable_silent_print_mode": false
         }
       }', true, 'CUSTOMER_ADVANCE');
--##
insert into permission (id, fields) values
('vw_vault__select',null),
('vault__insert',array ['key', 'value']),
('vault__update',array ['key', 'value']),
('vault__delete',null),
('account_type__insert',array ['name','parent_id','description']),
('account_type__update',array ['name','description']),
('account_type__delete',null),
('category__update',array ['category','active','sort_order']),
('category_bulk_update__execute',null),
('warehouse__insert',array ['name', 'mobile', 'email', 'telephone', 'address', 'city', 'pincode', 'state_id', 'country_id']),
('warehouse__update',array ['name', 'mobile', 'email', 'telephone', 'address', 'city', 'pincode', 'state_id', 'country_id']),
('warehouse__delete',null),
('member__select',null),
('member__insert',array ['name', 'pass', 'remote_access', 'settings', 'role_id', 'user_id', 'nick_name']),
('member__update',array ['name', 'pass', 'remote_access', 'settings', 'role_id', 'user_id', 'nick_name']),
('member_role__select',null),
('member_role__insert',array ['name', 'perms', 'ui_perms']),
('member_role__update',array ['name', 'perms', 'ui_perms']),
('approval_tag__insert',array ['name', 'members']),
('approval_tag__update',array ['name', 'members']),
('approval_tag__delete',null),
('tds_nature_of_payment__insert',array ['name', 'section', 'ind_huf_rate', 'ind_huf_rate_wo_pan', 'other_deductee_rate', 'other_deductee_rate_wo_pan', 'threshold']),
('tds_nature_of_payment__update',array ['name', 'section', 'ind_huf_rate', 'ind_huf_rate_wo_pan', 'other_deductee_rate', 'other_deductee_rate_wo_pan', 'threshold']),
('tds_nature_of_payment__delete',null),
('bank__select',null),
('bank__insert',array ['name', 'short_name', 'branch_name', 'bsr_code', 'ifs_code', 'micr_code']),
('bank__update',array ['name', 'short_name', 'branch_name', 'bsr_code', 'ifs_code', 'micr_code']),
('bank__delete',null),
('bank_beneficiary__select',null),
('bank_beneficiary__insert',array ['account_no', 'bank_name', 'branch_name', 'ifs_code', 'account_type', 'account_holder_name']),
('bank_beneficiary__update',array ['account_no', 'bank_name', 'branch_name', 'ifs_code', 'account_type', 'account_holder_name']),
('bank_beneficiary__delete',null),
('doctor__select',null),
('doctor__insert',array ['name', 'license_no']),
('doctor__update',array ['name', 'license_no']),
('doctor__delete',null),
('stock_location__insert',array ['name']),
('stock_location__update',array ['name']),
('stock_location__delete',null),
('display_rack__select',null),
('display_rack__insert',array ['name']),
('display_rack__update',array ['name']),
('display_rack__delete',null),
('tag__insert',array ['name']),
('tag__update',array ['name']),
('tag__delete',null),
('manufacturer__insert',array ['name', 'mobile', 'email', 'telephone']),
('manufacturer__update',array ['name', 'mobile', 'email', 'telephone']),
('manufacturer__delete',null),
('sales_person__insert',array ['name']),
('sales_person__update',array ['name']),
('sales_person__delete',null),
('price_list__select',null),
('price_list__insert',array ['name', 'customer_tag_id']),
('price_list__update',array ['name', 'customer_tag_id']),
('price_list__delete',null),
('price_list_condition__select',null),
('price_list_condition__insert',null),
('price_list_condition__update',array ['apply_on', 'computation', 'priority','include_rate',
              'min_qty', 'min_value', 'value', 'branches', 'inventory_tags', 'batches','inventory_id',
              'category1_id', 'category2_id', 'category3_id', 'category4_id', 'category5_id',
              'category6_id', 'category7_id', 'category8_id', 'category9_id', 'category10_id']),
('price_list_condition__delete',null),
('print_template__insert',array ['name', 'config', 'layout', 'voucher_mode']),
('print_template__update',array ['name', 'config', 'layout', 'voucher_mode']),
('print_template__delete',null),
('gst_registration__insert',array ['reg_type', 'gst_no', 'state_id', 'username', 'email', 'e_invoice_username', 'e_password']),
('gst_registration__update',array ['reg_type', 'gst_no', 'state_id', 'username', 'email', 'e_invoice_username', 'e_password']),
('gst_registration__delete',null),
('account__select',null),
('account__insert',array ['name', 'contact_type', 'account_type_id', 'alias_name', 'cheque_in_favour_of', 'description',
    'commission', 'gst_reg_type', 'gst_location_id', 'gst_no', 'gst_is_exempted', 'gst_exempted_desc', 'sac_code',
    'bill_wise_detail', 'is_commission_discounted', 'due_based_on', 'due_days', 'credit_limit', 'pan_no',
    'aadhar_no', 'mobile', 'email', 'contact_person', 'address', 'city', 'pincode', 'category1', 'category2', 'category3', 'category4',
    'category5', 'state_id', 'country_id', 'bank_beneficiary_id', 'agent_id', 'commission_account_id', 'gst_tax_id',
    'tds_nature_of_payment_id', 'tds_deductee_type_id', 'short_name', 'transaction_enabled', 'alternate_mobile',
    'telephone', 'delivery_address', 'enable_loyalty_point', 'tags']),
('account__update',array ['name', 'alias_name', 'cheque_in_favour_of', 'description',
    'commission', 'gst_reg_type', 'gst_location_id', 'gst_no', 'gst_is_exempted', 'gst_exempted_desc', 'sac_code',
    'bill_wise_detail', 'is_commission_discounted', 'due_based_on', 'due_days', 'credit_limit', 'pan_no',
    'aadhar_no', 'mobile', 'email', 'contact_person', 'address', 'city', 'pincode', 'category1', 'category2', 'category3', 'category4',
    'category5', 'state_id', 'country_id', 'bank_beneficiary_id', 'agent_id', 'commission_account_id', 'gst_tax_id',
    'tds_nature_of_payment_id', 'tds_deductee_type_id', 'short_name', 'transaction_enabled', 'alternate_mobile',
    'telephone', 'delivery_address', 'enable_loyalty_point', 'tags']),
('account__delete',null),

('branch__insert',array ['name', 'mobile', 'alternate_mobile', 'email', 'telephone', 'contact_person', 'address', 'city', 'pincode', 'state_id',
    'country_id', 'gst_registration_id', 'voucher_no_prefix', 'misc', 'members', 'account_id']),
('branch__update',array ['name', 'mobile', 'alternate_mobile', 'email', 'telephone', 'contact_person', 'address', 'city', 'pincode', 'state_id',
    'country_id', 'gst_registration_id', 'voucher_no_prefix', 'misc', 'members']),
('branch__delete',null),

('stock_value__select',null),
('stock_value__insert',null),
('stock_value__update',null),
('stock_value__delete',null),

('offer_management__select',null),
('offer_management__insert',array ['name', 'conditions', 'rewards', 'branch_id', 'price_list_id', 'start_date', 'end_date']),
('offer_management__update',array ['name', 'conditions', 'rewards', 'branch_id', 'price_list_id', 'start_date', 'end_date']),
('offer_management__delete',null),
('offer_management_condition__select',null),
('offer_management_reward__select',null),

('pos_server__select',null),
('pos_server__insert',array ['name', 'branch_id', 'mode']),
('pos_server__update',array ['name', 'mode', 'is_active']),
('pos_server__delete',null),
('generate_pos_server_token__execute',null),
('deactivate_pos_server__execute',null),

('device__select',null),
('device__insert',array ['name','branches']),
('device__update',array ['name','branches']),
('device__delete',null),
('generate_device_token__execute',null),
('deactivate_device__execute',null),

('unit__insert',array ['name', 'uqc_id', 'symbol', 'precision', 'conversions']),
('unit__update',array ['name', 'uqc_id', 'symbol', 'precision', 'conversions']),
('unit__delete',null),

('category_option__insert',array ['category_id', 'name', 'active']),
('category_option__update',array ['category_id', 'name', 'active']),
('category_option__delete',null),

('division__insert',array ['name']),
('division__update',array ['name']),
('division__delete',null),

('gift_coupon__select',null),

('pos_counter__insert',array ['code', 'name', 'branch_id']),
('pos_counter__update',array ['code', 'name']),
('pos_counter__delete',null),

('pos_counter_session__select',null),
('pos_counter_settlement__select',null),
('pos_counter_transaction__select',null),
('pos_counter_transaction_breakup__select',null),
('close_pos_session__execute',null),
('pos_current_session_transacted_accounts__execute', null),
('pos_session_breakup_summary__execute', null),
('pos_session_transaction_summary__execute', null),
('create_pos_settlement__execute', null),
('pos_settlement_breakup_summary__execute', null),
('pos_settlement_transaction_summary__execute', null),

('voucher_type__select',null),
('voucher_type__insert',array ['name', 'prefix', 'sequence_id', 'base_type', 'config', 'members', 'approve1_id', 'approve2_id', 'approve3_id', 'approve4_id', 'approve5_id']),
('voucher_type__update',array ['name', 'prefix', 'sequence_id', 'config', 'members', 'approve1_id', 'approve2_id', 'approve3_id', 'approve4_id', 'approve5_id']),
('voucher_type__delete',null),

('inventory__select',null),
('inventory__insert',array ['name', 'division_id', 'inventory_type', 'allow_negative_stock', 'gst_tax_id', 'unit_id', 'loose_qty',
    'reorder_inventory_id', 'bulk_inventory_id', 'qty', 'sale_unit_id', 'purchase_unit_id', 'cess', 'purchase_config',
    'sale_config', 'barcodes', 'tags', 'hsn_code', 'description', 'manufacturer_id', 'manufacturer_name', 'vendor_id',
    'vendor_name', 'vendors', 'salts', 'set_rate_values_via_purchase', 'apply_s_rate_from_master_for_sale',
    'category1', 'category2', 'category3', 'category4', 'category5', 'category6', 'category7', 'category8',
    'category9', 'category10']),
('inventory__update',array ['name', 'inventory_type', 'allow_negative_stock', 'gst_tax_id', 'unit_id',
    'reorder_inventory_id', 'bulk_inventory_id', 'qty', 'sale_unit_id', 'purchase_unit_id', 'cess', 'purchase_config',
    'sale_config', 'barcodes', 'tags', 'hsn_code', 'description', 'manufacturer_id', 'manufacturer_name', 'vendor_id',
    'vendor_name', 'vendors', 'salts', 'set_rate_values_via_purchase', 'apply_s_rate_from_master_for_sale',
    'category1', 'category2', 'category3', 'category4', 'category5', 'category6', 'category7', 'category8',
    'category9', 'category10']),
('inventory__delete',null),

('inventory_branch_detail__select',null),
('vw_branch_detail_stock_location__select',null),
('vw_branch_detail_stock_location__insert',array ['inventory_id','branch_id','stock_location_id']),
('vw_branch_detail_stock_location__update',array ['stock_location_id']),
('vw_branch_detail_preferred_vendor__select',null),
('vw_branch_detail_preferred_vendor__insert',array ['inventory_id','branch_id','vendor_id']),
('vw_branch_detail_preferred_vendor__update',array ['vendor_id']),
('vw_branch_detail_price_configuration__select',null),
('vw_branch_detail_price_configuration__insert',array ['inventory_id','branch_id','mrp', 's_rate', 'p_rate', 'p_rate_tax_inc', 'discount_1','discount_2','mrp_price_list','s_rate_price_list','nlc_price_list']),
('vw_branch_detail_price_configuration__update',array ['mrp', 's_rate', 'p_rate', 'p_rate_tax_inc', 'discount_1','discount_2','mrp_price_list','s_rate_price_list','nlc_price_list']),

('merge_inventory__execute',null),

('approval_log__select',null),

('financial_year__select',null),
('create_financial_year__execute',null),

('batch__select',null),
('batch__update',array ['batch_no', 'expiry', 's_rate', 'mrp']),
('batch_label__select',null),

('bank_txn__select',null),
('bank_txn__update',array ['bank_date']),

('get_account_opening__execute',null),
('set_account_opening__execute',null),

('get_inventory_opening__execute',null),
('set_inventory_opening__execute',null),

('tds_on_voucher__select',null),
('tds_on_voucher_section_break_up__execute',null),

('exchange__select',null),
('exchange_adjustment__select',null),

('get_voucher__execute',null),
('create_voucher__execute',null),
('update_voucher__execute',null),
('delete_voucher__execute',null),
('pending_approval_voucher__select',null),
('approve_voucher__execute',null),
('day_summary__execute',null),

('goods_inward_note__select',null),
('get_goods_inward_note__execute',null),
('create_goods_inward_note__execute',null),
('update_goods_inward_note__execute',null),
('delete_goods_inward_note__execute',null),

('gift_voucher__select',null),
('get_gift_voucher__execute',null),
('create_gift_voucher__execute',null),
('update_gift_voucher__execute',null),
('delete_gift_voucher__execute',null),

('get_purchase_bill__execute',null),
('create_purchase_bill__execute',null),
('update_purchase_bill__execute',null),
('delete_purchase_bill__execute',null),

('get_debit_note__execute',null),
('create_debit_note__execute',null),
('update_debit_note__execute',null),
('delete_debit_note__execute',null),

('get_sale_bill__execute',null),
('get_recent_sale_bill__execute',null),
('customer_sale_history__select',null),
('vw_recent_sale_bill__select',null),
('create_sale_bill__execute',null),
('update_sale_bill__execute',null),
('delete_sale_bill__execute',null),

('get_credit_note__execute',null),
('create_credit_note__execute',null),
('update_credit_note__execute',null),
('delete_credit_note__execute',null),

('get_personal_use_purchase__execute',null),
('create_personal_use_purchase__execute',null),
('update_personal_use_purchase__execute',null),
('delete_personal_use_purchase__execute',null),

('get_stock_adjustment__execute',null),
('create_stock_adjustment__execute',null),
('update_stock_adjustment__execute',null),
('delete_stock_adjustment__execute',null),

('get_stock_deduction__execute',null),
('create_stock_deduction__execute',null),
('update_stock_deduction__execute',null),
('delete_stock_deduction__execute',null),

('get_stock_addition__execute',null),
('create_stock_addition__execute',null),
('update_stock_addition__execute',null),
('delete_stock_addition__execute',null),

('get_material_conversion__execute',null),
('create_material_conversion__execute',null),
('update_material_conversion__execute',null),
('delete_material_conversion__execute',null),

('customer_advance__select',null),
('get_customer_advance__execute',null),
('create_customer_advance__execute',null),
('update_customer_advance__execute',null),
('delete_customer_advance__execute',null),

('vendor_bill_map__select',null),
('vendor_bill_map__insert',null),
('vendor_bill_map__update',array ['start_row', 'name', 'unit', 'qty', 'mrp', 'rate', 'free', 'batch_no', 'expiry',
    'expiry_format', 'discount']),
('vendor_bill_map__delete',null),

('vendor_item_map__select',null),
('vendor_item_map__insert',array ['vendor_id', 'inventory_id', 'vendor_inventory']),
('vendor_item_map__update',array ['vendor_inventory']),
('vendor_item_map__delete',null),

('inventory_book__select',null),
('inventory_book_group__execute',null),
('inventory_book_summary__execute',null),
('party_info__execute',null),

('account_book__select',null),
('account_closing__execute',null),
('account_book_group__execute',null),
('account_summary__execute',null),
('memo_closing__execute',null),
('difference_in_opening_balance__execute',null),

('pharma_salt__select',null),
('pharma_salt__insert',array ['name', 'drug_category']),
('pharma_salt__update',array ['name', 'drug_category']),
('pharma_salt__delete',null),
('account_pending__select',null),
('account_pending_breakup__execute',null),
('on_account_balance__execute',null),
('voucher_register_detail__select',null),
('purchase_register_detail__select',null),
('purchase_register_group__execute',null),
('purchase_register_summary__execute',null),
('sale_register_detail__select',null),
('sale_register_group__execute',null),
('sale_register_summary__execute',null),
('sale_analysis_by_inventory__execute',null),
('sale_analysis_by_branch__execute',null),
('sale_analysis_by_division__execute',null),
('sale_analysis_by_manufacturer__execute',null),
('sale_analysis_by_customer__execute',null),
('sale_analysis_by_sales_person__execute',null),
('stock_analysis_by_inventory__execute',null),
('stock_analysis_by_branch__execute',null),
('stock_analysis_by_division__execute',null),
('stock_analysis_by_manufacturer__execute',null),
('stock_analysis_by_vendor__execute',null),
('non_movement_analysis_summary__execute',null),
('negative_stock_analysis_summary__execute',null),
('expiry_stock_analysis_summary__execute',null),
('scheduled_drug_report__select',null),
('pos_counter_register__select',null),
('stock_journal_detail__select',null),
('stock_journal_register_group__execute',null),
('stock_journal_register_summary__execute',null),
('pos_counter_summary__execute',null),
('voucher_register_summary__execute',null),
('e_invoice_proxy__execute',null),
('set_e_invoice_irn_details__call',null),
('get_reorder__execute',null),
('set_reorder__execute',null),
('generate_reorder__execute',null),
('provisional_profit__select',null),
('provisional_profit_summary__execute',null),
('provisional_profit_by_group__execute',null),
('cdnr_summary__execute',null),
('cdnur_summary__execute',null),
('hsn_summary__execute',null),
('b2cs_summary__execute',null),
('b2cl_summary__execute',null),
('b2b_summary__execute',null),
('nil_summary__execute',null),
('docs_summary__execute',null);
-- ('day_book__execute',null);

