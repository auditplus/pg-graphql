insert into account_type (id, default_name, name, parent_id, allow_account, allow_sub_type,
                          base_types) overriding system value
values (1, 'CURRENT_ASSET', 'Current Asset', null, true, true, array ['CURRENT_ASSET']),
       (2, 'CURRENT_LIABILITY', 'Current Liability', null, true, true, array ['CURRENT_LIABILITY']),
       (3, 'DIRECT_INCOME', 'Direct Income', null, true, true, array ['DIRECT_INCOME']),
       (4, 'INDIRECT_INCOME', 'Indirect Income', null, true, true, array ['INDIRECT_INCOME']),
       (5, 'SALE', 'Sale', null, false, false, array ['SALE']),
       (6, 'DIRECT_EXPENSE', 'Direct Expense', null, true, true, array ['DIRECT_INCOME']),
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
values (1, 'Payment', '{ "payment": { "printAfterSave": false } }', true, 'PAYMENT'),
       (2, 'Receipt', '{ "receipt": { "printAfterSave": false } }', true, 'RECEIPT'),
       (3, 'Contra',  '{ "contra":  { "printAfterSave": false } }', true, 'CONTRA'),
       (4, 'Journal', '{ "journal": { "printAfterSave": false } }', true, 'JOURNAL'),
       (5, 'Sale', '{
         "sale": {
           "account": {
             "printAfterSave": false
           },
           "inventory": {
             "cashRegisterEnabled": false,
             "warehouseEnabled": false,
             "hideRack": false,
             "hideMrpInBatchModal": false,
             "rateEditable": false,
             "taxEditable": false,
             "discountEditable": false,
             "unitEditable": false,
             "billDiscountEditable": false,
             "printAfterSave": false,
             "setFocusOnInventory": false,
             "autoSelectBatch": false,
             "setDefaultQty": false,
             "enableSilentPrintMode": false,
             "allowCreditCustomer": false,
             "enableSaleIncharge": false,
             "voucherwiseSaleIncharge": false,
             "freezeSaleInchargeForVoucher": false,
             "barcodeEnabled": false,
             "customerFormQuickCreate": false,
             "enableExchange": false,
             "enableAdvance": false,
             "enableEmi": false,
             "setLooseQty": false
           }
         }
       }', true, 'SALE'),
       (6, 'Credit Note', '{
         "creditNote": {
           "account": {
             "printAfterSave": false
           },
           "inventory": {
             "cashRegisterEnabled": false,
             "warehouseEnabled": false,
             "rateEditable": false,
             "taxEditable": false,
             "discountEditable": false,
             "unitEditable": false,
             "billDiscountEditable": false,
             "printAfterSave": false,
             "enableSilentPrintMode": false,
             "allowCreditCustomer": false,
             "enableSaleIncharge": false,
             "voucherwiseSaleIncharge": false,
             "freezeSaleInchargeForVoucher": false,
             "barcodeEnabled": false,
             "enableExp": false,
             "customerFormQuickCreate": false,
             "printCustomerCopy": false,
             "invoiceNoRequired": false,
             "isExchangeVoucher": false
           }
         }
       }', true, 'CREDIT_NOTE'),
       (7, 'Purchase', '{
         "purchase": {
           "account": {
             "printAfterSave": false
           },
           "inventory": {
             "printAfterSave": false,
             "sRateMrpRequired": false,
             "sRateAsMrp": false,
             "enableSilentPrintMode": false,
             "allowCreditVendor": true,
             "barcodeEnabled": false,
             "preventLoss": false,
             "taxHide": false,
             "enableGin": false,
             "enableExpiry": false,
             "expiryRequired": false,
             "isExchangeVoucher": false,
             "enableBillDetail": true,
             "enableAutomaticRoundedOff": false,
             "enableWeightBill": false,
             "allowNewRefOnly": false,
             "billFormat": "NORMAL",
             "setLooseQty": false
           }
         }
       }', true, 'PURCHASE'),
       (8, 'Debit Note', '{
         "debitNote": {
           "account": {
             "printAfterSave": false
           },
           "inventory": {
             "cashRegisterEnabled": false,
             "warehouseEnabled": false,
             "rateEditable": false,
             "taxEditable": false,
             "discountEditable": false,
             "printAfterSave": false,
             "enableSilentPrintMode": false,
             "allowCreditVendor": false,
             "barcodeEnabled": false,
             "enableExp": false,
             "billNoRequired": false
           }
         }
       }', true, 'DEBIT_NOTE'),
       (9, 'Sale Quotation', '{
         "saleQuotation": {
           "rateEditable": false,
           "taxEditable": false,
           "discountEditable": false,
           "unitEditable": false,
           "billDiscountEditable": false,
           "enableSilentPrintMode": false,
           "printAfterSave": false,
           "barcodeEnabled": false,
           "enableExp": false
         }
       }', true, 'SALE_QUOTATION'),
       (10, 'Stock Adjustment', '{
         "stockAdjustment": {
           "enableSilentPrintMode": false,
           "printAfterSave": false,
           "barcodeEnabled": false,
           "enableExp": false
         }
       }', true, 'STOCK_ADJUSTMENT'),
       (11, 'Stock Deduction', '{
         "stockDeduction": {
           "enableSilentPrintMode": false,
           "printAfterSave": false,
           "barcodeEnabled": false,
           "enableExp": false,
           "altBranchRequired": false
         }
       }', true, 'STOCK_DEDUCTION'),
       (12, 'Stock Addition', '{
         "stockAddition": {
           "enableSilentPrintMode": false,
           "printAfterSave": false,
           "barcodeEnabled": false,
           "enableExp": false,
           "altBranchRequired": false
         }
       }', true, 'STOCK_ADDITION'),
       (13, 'Material Conversion', '{
         "materialConversion": {
           "enableSilentPrintMode": false,
           "printAfterSave": false,
           "barcodeEnabled": false,
           "enableExp": false
         }
       }', true, 'MATERIAL_CONVERSION'),
       (14, 'Manufacturing Journal', '{
         "manufacturingJournal": {
           "barcodeEnabled": false
         }
       }', true, 'MANUFACTURING_JOURNAL'),
       (15, 'Memo', '{
         "memo": {
           "expenseOnly": false,
           "printAfterSave": false,
           "openChequeBookDetail": false
         }
       }', true, 'MEMO'),
       (16, 'Wastage', '{
         "wastage": {
           "enableSilentPrintMode": false,
           "printAfterSave": false,
           "barcodeEnabled": false,
           "enableExp": false
         }
       }', true, 'WASTAGE'),
       (17, 'Goods Inward Note', '{
         "goodsInwardNote": {
           "printAfterSave": false,
           "enableSilentPrintMode": false
         }
       }', true, 'GOODS_INWARD_NOTE'),
       (18, 'Gift Voucher', '{
         "giftVoucher": {
           "printAfterSave": false,
           "enableSilentPrintMode": false
         }
       }', true, 'GIFT_VOUCHER'),
       (19, 'Purchased Goods For Personal Use', '{
         "personalUsePurchase": {
           "expenseAccount": null
         }
       }', true, 'PERSONAL_USE_PURCHASE'),
       (20, 'Customer Advance', '{
         "customerAdvance": {
           "printAfterSave": false,
           "enableSilentPrintMode": false
         }
       }', true, 'CUSTOMER_ADVANCE');
--##
insert into permission (id, fields) values
('account_type__select',null),
('account_type__insert',array ['name','parent_id','description']),
('account_type__update',array ['name','description']),
('account_type__delete',null),
('category__select',null),
('category__update',array ['category','active','sort_order']),
('category_bulk_update__execute',null),
('warehouse__select',null),
('warehouse__insert',array ['name', 'mobile', 'email', 'telephone', 'address', 'city', 'pincode', 'state_id', 'country_id']),
('warehouse__update',array ['name', 'mobile', 'email', 'telephone', 'address', 'city', 'pincode', 'state_id', 'country_id']),
('warehouse__delete',null),
('member__select',null),
('member__insert',array ['name', 'pass', 'remote_access', 'settings', 'role_id', 'user_id', 'nick_name']),
('member__update',array ['name', 'pass', 'remote_access', 'settings', 'role_id', 'user_id', 'nick_name']),
('member_profile__execute',null),
('voucher_types(member)__execute',null),
('branches(member)__execute',null),
('perms(member)__execute',null),
('ui_perms(member)__execute',null),
('member_role__select',null),
('member_role__insert',array ['name', 'perms', 'ui_perms']),
('member_role__update',array ['name', 'perms', 'ui_perms']),
('permissions(member_role)__execute',null),
('approval_tag__select',null),
('approval_tag__insert',array ['name', 'members']),
('approval_tag__update',array ['name', 'members']),
('approval_tag__delete',null),
('tds_nature_of_payment__select',null),
('tds_nature_of_payment__insert',array ['name', 'section', 'ind_huf_rate', 'ind_huf_rate_wo_pan', 'other_deductee_rate', 'other_deductee_rate_wo_pan', 'threshold']),
('tds_nature_of_payment__update',array ['name', 'section', 'ind_huf_rate', 'ind_huf_rate_wo_pan', 'other_deductee_rate', 'other_deductee_rate_wo_pan', 'threshold']),
('tds_nature_of_payment__delete',null),
('bank_beneficiary__select',null),
('bank_beneficiary__insert',array ['account_no', 'bank_name', 'branch_name', 'ifs_code', 'account_type', 'account_holder_name']),
('bank_beneficiary__update',array ['account_no', 'bank_name', 'branch_name', 'ifs_code', 'account_type', 'account_holder_name']),
('bank_beneficiary__delete',null),
('doctor__select',null),
('doctor__insert',array ['name', 'license_no']),
('doctor__update',array ['name', 'license_no']),
('doctor__delete',null),
('stock_location__select',null),
('stock_location__insert',array ['name']),
('stock_location__update',array ['name']),
('stock_location__delete',null),
('display_rack__select',null),
('display_rack__insert',array ['name']),
('display_rack__update',array ['name']),
('display_rack__delete',null),
('tag__select',null),
('tag__insert',array ['name']),
('tag__update',array ['name']),
('tag__delete',null),
('manufacturer__select',null),
('manufacturer__insert',array ['name', 'mobile', 'email', 'telephone']),
('manufacturer__update',array ['name', 'mobile', 'email', 'telephone']),
('manufacturer__delete',null),
('sale_incharge__select',null),
('sale_incharge__insert',array ['name', 'code']),
('sale_incharge__update',array ['name', 'code']),
('sale_incharge__delete',null),
('price_list__select',null),
('price_list__insert',array ['name', 'customer_tag_id']),
('price_list__update',array ['name', 'customer_tag_id']),
('price_list__delete',null),
('price_list_condition__select',null),
('price_list_condition__insert',null),
('price_list_condition__update',array ['apply_on', 'computation', 'priority',
              'min_qty', 'min_value', 'value', 'branch_id', 'inventory_tags', 'batches','inventory_id',
              'category1_id', 'category2_id', 'category3_id', 'category4_id', 'category5_id',
              'category6_id', 'category7_id', 'category8_id', 'category9_id', 'category10_id']),
('price_list_condition__delete',null),
('inventory_tags(price_list_condition)__execute',null),
('print_template__select',null),
('print_template__insert',array ['name', 'config', 'layout', 'voucher_mode']),
('print_template__update',array ['name', 'config', 'layout', 'voucher_mode']),
('print_template__delete',null),
('gst_registration__select',null),
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
('category1(account)__execute',null),
('category2(account)__execute',null),
('category3(account)__execute',null),
('category4(account)__execute',null),
('category5(account)__execute',null),

('branch__select',null),
('branch__insert',array ['name', 'mobile', 'alternate_mobile', 'email', 'telephone', 'contact_person', 'address', 'city', 'pincode', 'state_id',
    'country_id', 'gst_registration_id', 'voucher_no_prefix', 'misc', 'members', 'account_id']),
('branch__update',array ['name', 'mobile', 'alternate_mobile', 'email', 'telephone', 'contact_person', 'address', 'city', 'pincode', 'state_id',
    'country_id', 'gst_registration_id', 'voucher_no_prefix', 'misc', 'members']),
('branch__delete',null),
('members(branch)__execute',null),

('stock_value__select',null),
('stock_value__insert',null),
('stock_value__update',null),
('stock_value__delete',null),

('offer_management__select',null),
('offer_management__insert',array ['name', 'conditions', 'rewards', 'branch_id', 'price_list_id', 'start_date', 'end_date']),
('offer_management__update',array ['name', 'conditions', 'rewards', 'branch_id', 'price_list_id', 'start_date', 'end_date']),
('offer_management__delete',null),
('offer_conditions(offer_management)__execute',null),
('offer_rewards(offer_management)__execute',null),
('offer_management_condition__select',null),
('inventory_tags(offer_management_condition)__execute',null),
('offer_management_reward__select',null),
('inventory_tags(offer_management_reward)__execute',null),

('transport__select',null),
('transport__insert',array ['name', 'mobile', 'email', 'telephone']),
('transport__update',array ['name', 'mobile', 'email', 'telephone']),
('transport__delete',null),

('pos_server__select',null),
('pos_server__insert',array ['name', 'branch_id', 'mode']),
('pos_server__update',array ['name', 'mode', 'is_active']),
('pos_server__delete',null),

('desktop_client__select',null),
('desktop_client__insert',array ['name','branches']),
('desktop_client__update',array ['name','branches']),
('desktop_client__delete',null),
('branches(desktop_client)__execute',null),

('unit__select',null),
('unit__insert',array ['name', 'uqc_id', 'symbol', 'precision', 'conversions']),
('unit__update',array ['name', 'uqc_id', 'symbol', 'precision', 'conversions']),
('unit__delete',null),
('conversions(unit)__execute',null),

('unit_conversion__select',null),
('unit_conversion__insert',null),
('unit_conversion__update',null),
('unit_conversion__delete',null),

('category_option__select',null),
('category_option__insert',array ['category_id', 'name', 'active']),
('category_option__update',array ['category_id', 'name', 'active']),
('category_option__delete',null),

('division__select',null),
('division__insert',array ['name']),
('division__update',array ['name']),
('division__delete',null),

('gift_coupon__select',null),

('pos_counter__select',null),
('pos_counter__insert',array ['name', 'branch_id']),
('pos_counter__update',array ['name']),
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
('voucher_type__insert',array ['name', 'prefix', 'sequence_id', 'base_type', 'config', 'members', 'approval']),
('voucher_type__update',array ['name', 'prefix', 'sequence_id', 'config', 'members', 'approval']),
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
('category1(inventory)__execute',null),
('category2(inventory)__execute',null),
('category3(inventory)__execute',null),
('category4(inventory)__execute',null),
('category5(inventory)__execute',null),
('category6(inventory)__execute',null),
('category7(inventory)__execute',null),
('category8(inventory)__execute',null),
('category9(inventory)__execute',null),
('category10(inventory)__execute',null),
('salts(inventory)__execute',null),
('tags(inventory)__execute',null),
('vendors(inventory)__execute',null),

('inventory_branch_detail__select',null),
('inventory_branch_detail__insert',array ['inventory_id', 'inventory_name', 'branch_id', 'branch_name', 'stock_location_id',
    's_disc', 'discount_1', 'discount_2', 'vendor_id', 's_customer_disc', 'mrp_price_list', 's_rate_price_list',
    'nlc_price_list', 'mrp', 's_rate', 'p_rate_tax_inc', 'p_rate', 'landing_cost', 'nlc', 'stock', 'reorder_inventory_id',
    'reorder_mode', 'reorder_level', 'min_order', 'max_order']),
('inventory_branch_detail__update',array ['inventory_name', 'branch_name', 'stock_location_id',
    's_disc', 'discount_1', 'discount_2', 'vendor_id', 's_customer_disc', 'mrp_price_list', 's_rate_price_list',
    'nlc_price_list', 'mrp', 's_rate', 'p_rate_tax_inc', 'p_rate', 'landing_cost', 'nlc', 'stock', 'reorder_inventory_id',
    'reorder_mode', 'reorder_level', 'min_order', 'max_order']),

('merge_inventory__execute',null),

('approval_log__select',null),

('financial_year__select',null),
('create_financial_year__execute',null),

('batch__select',null),
('batch__update',array ['batch_no', 'expiry', 's_rate', 'mrp']),
('batch_label__select',null),

('bill_allocation__select',null),
('closing(bill_allocation)__execute',null),
('bank_txn__select',null),
('bank_txn__update',array ['bank_date']),

('account_opening__select',null),
('set_account_opening__execute',null),
('bill_allocations(account_opening)__execute',null),

('inventory_opening__select',null),
('set_inventory_opening__execute',null),

('tds_on_voucher__select',null),
('tds_on_voucher_section_break_up__execute',null),

('exchange__select',null),
('exchange_adjustment__select',null),

('voucher__select',null),
('create_voucher__execute',null),
('update_voucher__execute',null),
('delete_voucher__execute',null),
('approve_voucher__execute',null),
('ac_trns(voucher)__execute',null),
('branch_gst(voucher)__execute',null),
('party_gst(voucher)__execute',null),

('goods_inward_note__select',null),
('create_goods_inward_note__execute',null),
('update_goods_inward_note__execute',null),
('delete_goods_inward_note__execute',null),

('gift_voucher__select',null),
('create_gift_voucher__execute',null),
('update_gift_voucher__execute',null),
('delete_gift_voucher__execute',null),
('ac_trns(gift_voucher)__execute',null),

('purchase_bill_inv_item__select',null),
('batch(purchase_bill_inv_item)__execute',null),
('purchase_bill__select',null),
('create_purchase_bill__execute',null),
('update_purchase_bill__execute',null),
('delete_purchase_bill__execute',null),
('ac_trns(purchase_bill)__execute',null),
('branch_gst(purchase_bill)__execute',null),
('party_gst(purchase_bill)__execute',null),
('tds_details(purchase_bill)__execute',null),
('agent_detail(purchase_bill)__execute',null),
('agent_account(purchase_bill)__execute',null),
('commission_account(purchase_bill)__execute',null),

('debit_note_inv_item__select',null),
('debit_note__select',null),
('create_debit_note__execute',null),
('update_debit_note__execute',null),
('delete_debit_note__execute',null),
('ac_trns(debit_note)__execute',null),
('branch_gst(debit_note)__execute',null),
('party_gst(debit_note)__execute',null),

('sale_bill_inv_item__select',null),
('sale_bill__select',null),
('create_sale_bill__execute',null),
('update_sale_bill__execute',null),
('delete_sale_bill__execute',null),
('ac_trns(sale_bill)__execute',null),
('emi_account(sale_bill)__execute',null),
('branch_gst(sale_bill)__execute',null),
('party_gst(sale_bill)__execute',null),

('credit_note_inv_item__select',null),
('credit_note__select',null),
('create_credit_note__execute',null),
('update_credit_note__execute',null),
('delete_credit_note__execute',null),
('ac_trns(credit_note)__execute',null),
('branch_gst(credit_note)__execute',null),
('party_gst(credit_note)__execute',null),

('personal_use_purchase_inv_item__select',null),
('personal_use_purchase__select',null),
('create_personal_use_purchase__execute',null),
('update_personal_use_purchase__execute',null),
('delete_personal_use_purchase__execute',null),
('ac_trns(personal_use_purchase)__execute',null),

('stock_adjustment_inv_item__select',null),
('stock_adjustment__select',null),
('create_stock_adjustment__execute',null),
('update_stock_adjustment__execute',null),
('delete_stock_adjustment__execute',null),
('ac_trns(stock_adjustment)__execute',null),

('stock_deduction_inv_item__select',null),
('stock_deduction__select',null),
('create_stock_deduction__execute',null),
('update_stock_deduction__execute',null),
('delete_stock_deduction__execute',null),
('ac_trns(stock_deduction)__execute',null),

('stock_addition_inv_item__select',null),
('stock_addition__select',null),
('create_stock_addition__execute',null),
('update_stock_addition__execute',null),
('delete_stock_addition__execute',null),
('ac_trns(stock_addition)__execute',null),

('material_conversion_inv_item__select',null),
('material_conversion__select',null),
('create_material_conversion__execute',null),
('update_material_conversion__execute',null),
('delete_material_conversion__execute',null),
('ac_trns(material_conversion)__execute',null),

('customer_advance__select',null),
('create_customer_advance__execute',null),
('update_customer_advance__execute',null),
('delete_customer_advance__execute',null),
('ac_trns(customer_advance)__execute',null),

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
('account_book_summary__execute',null),

('pharma_salt__select',null),
('pharma_salt__insert',array ['name', 'drug_category']),
('pharma_salt__update',array ['name', 'drug_category']),
('pharma_salt__delete',null),

('ac_txn__select',array ['id', 'account_id', 'credit', 'debit', 'is_default']),
('gst_txn__select',array ['ac_txn_id', 'hsn_code', 'gst_tax_id', 'taxable_amount']),
('acc_cat_txn__select',array ['id', 'ac_txn_id', 'amount', 'category1_id', 'category2_id', 'category3_id', 'category4_id', 'category5_id']),
('account_daily_summary__select',null),

('account_pending__select',null),
('voucher_register_detail__select',null),
('purchase_register_detail__select',null),
('sale_register_detail__select',null),
('scheduled_drug_report__select',null),
('pos_counter_register__select',null),
('stock_journal_detail__select',null),
('pos_counter_summary__execute',null),
('voucher_register_summary__execute',null);

