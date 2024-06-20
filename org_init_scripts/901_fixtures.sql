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
       (22, 'DUTIES_AND_TAXES', 'Duties And Taxes', 2, true, false, array ['CURRENT_LIABILITY', 'DUTIES_AND_TAXES']);
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
insert into permission (name, resource, action, fields) values
('Select Account Type','account_type','select',null),
('Insert Account Type','account_type','insert','{"name","parent_id","description"}'),
('Update Account Type','account_type','update','{"name","description"}'),
('Delete Account Type','account_type','delete',null),
('Select Category','category','select',null),
('Update Category','category','update','{"category","active","sort_order"}'),
('Category Bulk Update','category_bulk_update','execute',null),
('Select Warehouse','warehouse','select',null),
('Insert Warehouse','warehouse','insert','{"name", "mobile", "email", "telephone", "address", "city", "pincode", "state_id", "country_id"}'),
('Update Warehouse','warehouse','update','{"name", "mobile", "email", "telephone", "address", "city", "pincode", "state_id", "country_id"}'),
('Delete Warehouse','warehouse','delete',null),
('Select Member','member','select',null),
('Insert Member','member','insert','{"name", "pass", "remote_access", "settings", "role_id", "user_id", "nick_name"}'),
('Update Member','member','update','{"name", "pass", "remote_access", "settings", "role_id", "user_id", "nick_name"}'),
('Member Profile','member_profile','execute',null),
('Select Member Role','member_role','select',null),
('Insert Member Role','member_role','insert','{"name", "perms"}'),
('Update Member Role','member_role','update','{"name", "perms"}'),
('Select Approval Tag','approval_tag','select',null),
('Insert Approval Tag','approval_tag','insert','{"name", "members"}'),
('Update Approval Tag','approval_tag','update','{"name", "members"}'),
('Delete Approval Tag','approval_tag','delete',null),
('Select Tds Nature of Payment','tds_nature_of_payment','select',null),
('Insert Tds Nature of Payment','tds_nature_of_payment','insert','{"name", "section", "ind_huf_rate", "ind_huf_rate_wo_pan", "other_deductee_rate", "other_deductee_rate_wo_pan", "threshold"}'),
('Update Tds Nature of Payment','tds_nature_of_payment','update','{"name", "section", "ind_huf_rate", "ind_huf_rate_wo_pan", "other_deductee_rate", "other_deductee_rate_wo_pan", "threshold"}'),
('Delete Tds Nature of Payment','tds_nature_of_payment','delete',null),
('Select Bank Beneficiary','bank_beneficiary','select',null),
('Insert Bank Beneficiary','bank_beneficiary','insert','{"account_no", "bank_name", "branch_name", "ifs_code", "account_type", "account_holder_name"}'),
('Update Bank Beneficiary','bank_beneficiary','update','{"account_no", "bank_name", "branch_name", "ifs_code", "account_type", "account_holder_name"}'),
('Delete Bank Beneficiary','bank_beneficiary','delete',null),
('Select Doctor','doctor','select',null),
('Insert Doctor','doctor','insert','{"name", "license_no"}'),
('Update Doctor','doctor','update','{"name", "license_no"}'),
('Delete Doctor','doctor','delete',null),
('Select Stock Location','stock_location','select',null),
('Insert Stock Location','stock_location','insert','{"name"}'),
('Update Stock Location','stock_location','update','{"name"}'),
('Delete Stock Location','stock_location','delete',null),
('Select Display Rack','display_rack','select',null),
('Insert Display Rack','display_rack','insert','{"name"}'),
('Update Display Rack','display_rack','update','{"name"}'),
('Delete Display Rack','display_rack','delete',null),
('Select Tag','tag','select',null),
('Insert Tag','tag','insert','{"name"}'),
('Update Tag','tag','update','{"name"}'),
('Delete Tag','tag','delete',null),
('Select Manufacturer','manufacturer','select',null),
('Insert Manufacturer','manufacturer','insert','{"name", "mobile", "email", "telephone"}'),
('Update Manufacturer','manufacturer','update','{"name", "mobile", "email", "telephone"}'),
('Delete Manufacturer','manufacturer','delete',null),
('Select Sale Incharge','sale_incharge','select',null),
('Insert Sale Incharge','sale_incharge','insert','{"name", "code"}'),
('Update Sale Incharge','sale_incharge','update','{"name", "code"}'),
('Delete Sale Incharge','sale_incharge','delete',null),
('Select Price List','price_list','select',null),
('Insert Price List','price_list','insert','{"name", "customer_tag_id"}'),
('Update Price List','price_list','update','{"name", "customer_tag_id"}'),
('Delete Price List','price_list','delete',null),
('Select Price List Condition','price_list_condition','select',null),
('Insert Price List Condition','price_list_condition','insert',null),
('Update Price List Condition','price_list_condition','update','{"apply_on", "computation", "priority", 
              "min_qty", "min_value", "value", "branch_id", "inventory_tags", "batches","inventory_id",
              "category1_id", "category2_id", "category3_id", "category4_id", "category5_id",
              "category6_id", "category7_id", "category8_id", "category9_id", "category10_id"}'),
('Delete Price List Condition','price_list_condition','delete',null),
('Select Print Template','print_template','select',null),
('Insert Print Template','print_template','insert','{"name", "config", "layout", "voucher_mode"}'),
('Update Print Template','print_template','update','{"name", "config", "layout", "voucher_mode"}'),
('Delete Print Template','print_template','delete',null),
('Select Gst Registration','gst_registration','select',null),
('Insert Gst Registration','gst_registration','insert','{"reg_type", "gst_no", "state_id", "username", "email", "e_invoice_username", "e_password"}'),
('Update Gst Registration','gst_registration','update','{"reg_type", "gst_no", "state_id", "username", "email", "e_invoice_username", "e_password"}'),
('Select Account','account','select',null),
('Insert Account','account','insert','{"name", "contact_type", "account_type_id", "alias_name", "cheque_in_favour_of", "description",
    "commission", "gst_reg_type", "gst_location_id", "gst_no", "gst_is_exempted", "gst_exempted_desc", "sac_code",
    "bill_wise_detail", "is_commission_discounted", "due_based_on", "due_days", "credit_limit", "pan_no",
    "aadhar_no", "mobile", "email", "contact_person", "address", "city", "pincode", "category1", "category2", "category3", "category4",
    "category5", "state_id", "country_id", "bank_beneficiary_id", "agent_id", "commission_account_id", "gst_tax_id",
    "tds_nature_of_payment_id", "tds_deductee_type_id", "short_name", "transaction_enabled", "alternate_mobile",
    "telephone", "delivery_address", "enable_loyalty_point", "tags"}'),
('Update Account','account','update','{"name", "alias_name", "cheque_in_favour_of", "description",
    "commission", "gst_reg_type", "gst_location_id", "gst_no", "gst_is_exempted", "gst_exempted_desc", "sac_code",
    "bill_wise_detail", "is_commission_discounted", "due_based_on", "due_days", "credit_limit", "pan_no",
    "aadhar_no", "mobile", "email", "contact_person", "address", "city", "pincode", "category1", "category2", "category3", "category4",
    "category5", "state_id", "country_id", "bank_beneficiary_id", "agent_id", "commission_account_id", "gst_tax_id",
    "tds_nature_of_payment_id", "tds_deductee_type_id", "short_name", "transaction_enabled", "alternate_mobile",
    "telephone", "delivery_address", "enable_loyalty_point", "tags"}'),
('Delete Account','account','delete',null),

('Select Branch','branch','select',null),
('Insert Branch','branch','insert','{"name", "mobile", "alternate_mobile", "email", "telephone", "contact_person", "address", "city", "pincode", "state_id",
    "country_id", "gst_registration_id", "voucher_no_prefix", "misc", "members", "account_id"}'),
('Update Branch','branch','update','{"name", "mobile", "alternate_mobile", "email", "telephone", "contact_person", "address", "city", "pincode", "state_id",
    "country_id", "gst_registration_id", "voucher_no_prefix", "misc", "members"}'),
('Delete Branch','branch','delete',null),

('Select Stock Value','stock_value','select',null),
('Select Stock Value','stock_value','insert',null),
('Select Stock Value','stock_value','update',null),
('Select Stock Value','stock_value','delete',null),

('Select Offer Management','offer_management','select',null),
('Insert Offer Management','offer_management','insert','{"name", "conditions", "rewards", "branch_id", "price_list_id", "start_date", "end_date"}'),
('Update Offer Management','offer_management','update','{"name", "conditions", "rewards", "branch_id", "price_list_id", "start_date", "end_date"}'),
('Delete Offer Management','offer_management','delete',null),
('Select Offer Management','offer_management_condition','select',null),
('Select Offer Management','offer_management_reward','select',null),

('Select Transport','transport','select',null),
('Insert Transport','transport','insert','{"name", "mobile", "email", "telephone"}'),
('Update Transport','transport','update','{"name", "mobile", "email", "telephone"}'),
('Delete Transport','transport','delete',null),

('Select Pos Server','pos_server','select',null),
('Insert Pos Server','pos_server','insert','{"name", "branch_id", "mode"}'),
('Update Pos Server','pos_server','update','{"name", "mode", "is_active"}'),
('Delete Pos Server','pos_server','delete',null),

('Select Desktop Client','desktop_client','select',null),
('Insert Desktop Client','desktop_client','insert','{"name","branches"}'),
('Update Desktop Client','desktop_client','update','{"name","branches"}'),
('Delete Desktop Client','desktop_client','delete',null),

('Select Unit','unit','select',null),
('Insert Unit','unit','insert','{"name", "uqc_id", "symbol", "precision", "conversions"}'),
('Update Unit','unit','update','{"name", "uqc_id", "symbol", "precision", "conversions"}'),
('Delete Unit','unit','delete',null),
('Select Unit Conversion','unit_conversion','select',null),

('Select Category Option','category_option','select',null),
('Insert Category Option','category_option','insert','{"category_id", "name", "active"}'),
('Update Category Option','category_option','update','{"category_id", "name", "active"}'),
('Delete Category Option','category_option','delete',null),

('Select Division','division','select',null),
('Insert Division','division','insert','{"name"}'),
('Update Division','division','update','{"name"}'),
('Delete Division','division','delete',null),

('Select Gift Coupon','gift_coupon','select',null),

('Select Pos Counter','pos_counter','select',null),
('Insert Pos Counter','pos_counter','insert','{"name"}'),
('Update Pos Counter','pos_counter','update','{"name"}'),

('Select Pos Counter Session','pos_counter_session','select',null),
('Select Pos Counter Settlement','pos_counter_settlement','select',null),
('Select Pos Counter Transaction','pos_counter_transaction','select',null),
('Select Pos Counter Transaction Breakup','pos_counter_transaction_breakup','select',null),

('Select Voucher Type','voucher_type','select',null),
('Insert Voucher Type','voucher_type','insert','{"name", "prefix", "sequence_id", "base_type", "config", "members", "approval"}'),
('Update Voucher Type','voucher_type','update','{"name", "prefix", "sequence_id", "config", "members", "approval"}'),
('Delete Voucher Type','voucher_type','delete',null),

('Select Inventory','inventory','select',null),
('Insert Inventory','inventory','insert','{"name", "division_id", "inventory_type", "allow_negative_stock", "gst_tax_id", "unit_id", "loose_qty",
    "reorder_inventory_id", "bulk_inventory_id", "qty", "sale_unit_id", "purchase_unit_id", "cess", "purchase_config",
    "sale_config", "barcodes", "tags", "hsn_code", "description", "manufacturer_id", "manufacturer_name", "vendor_id",
    "vendor_name", "vendors", "salts", "set_rate_values_via_purchase", "apply_s_rate_from_master_for_sale",
    "category1", "category2", "category3", "category4", "category5", "category6", "category7", "category8",
    "category9", "category10"}'),
('Update Inventory','inventory','update','{"name", "inventory_type", "allow_negative_stock", "gst_tax_id", "unit_id",
    "reorder_inventory_id", "bulk_inventory_id", "qty", "sale_unit_id", "purchase_unit_id", "cess", "purchase_config",
    "sale_config", "barcodes", "tags", "hsn_code", "description", "manufacturer_id", "manufacturer_name", "vendor_id",
    "vendor_name", "vendors", "salts", "set_rate_values_via_purchase", "apply_s_rate_from_master_for_sale",
    "category1", "category2", "category3", "category4", "category5", "category6", "category7", "category8",
    "category9", "category10"}'),
('Delete Inventory','inventory','delete',null),

('Select Inventory Branch Detail','inventory_branch_detail','select',null),
('Insert Inventory Branch Detail','inventory_branch_detail','insert','{"inventory_id", "inventory_name", "branch_id", "branch_name", "stock_location_id",
    "s_disc", "discount_1", "discount_2", "vendor_id", "s_customer_disc", "mrp_price_list", "s_rate_price_list",
    "nlc_price_list", "mrp", "s_rate", "p_rate_tax_inc", "p_rate", "landing_cost", "nlc", "stock", "reorder_inventory_id",
    "reorder_mode", "reorder_level", "min_order", "max_order"}'),
('Update Inventory Branch Detail','inventory_branch_detail','update','{"inventory_name", "branch_name", "stock_location_id",
    "s_disc", "discount_1", "discount_2", "vendor_id", "s_customer_disc", "mrp_price_list", "s_rate_price_list",
    "nlc_price_list", "mrp", "s_rate", "p_rate_tax_inc", "p_rate", "landing_cost", "nlc", "stock", "reorder_inventory_id",
    "reorder_mode", "reorder_level", "min_order", "max_order"}'),

('Merge Inventory','merge_inventory','execute',null),
('pos_current_session_transacted_accounts', 'pos_current_session_transacted_accounts', 'execute', null),
('pos_session_breakup_summary', 'pos_session_breakup_summary', 'execute', null),
('close_pos_session', 'close_pos_session', 'execute', null),
('create_pos_settlement', 'create_pos_settlement', 'execute', null),

('Select Approval Log','approval_log','select',null),

('Select Financial Year','financial_year','select',null),
('Create Financial Year','create_financial_year','execute',null),

('Select Batch','batch','select',null),
('Update Batch','batch','update','{"batch_no", "expiry", "s_rate", "mrp"}'),
('Select Batch Label','batch_label','select',null),

('Select Bill Allocation','bill_allocation','select',null),
('Select Bank Transaction','bank_txn','select',null),
('Update Bank Transaction','bank_txn','update','{"bank_date"}'),

('Select Account Opening','account_opening','select',null),
('Set Account Opening','set_account_opening','execute',null),

('Select Inventory Opening','inventory_opening','select',null),
('Set Inventory Opening','set_inventory_opening','execute',null),

('Select Tds On Voucher','tds_on_voucher','select',null),
('Tds On Voucher Section Breakup','tds_on_voucher_section_break_up','execute',null),

('Select Exchange','exchange','select',null),
('Select Exchange Adjustment','exchange_adjustment','select',null),

('Select Voucher','voucher','select',null),
('Create Voucher','create_voucher','execute',null),
('Update Voucher','update_voucher','execute',null),
('Delete Voucher','delete_voucher','execute',null),
('Approve Voucher','approve_voucher','execute',null),

('Select Goods Inward Note','goods_inward_note','select',null),
('Create Goods Inward Note','create_goods_inward_note','execute',null),
('Update Goods Inward Note','update_goods_inward_note','execute',null),
('Delete Goods Inward Note','delete_goods_inward_note','execute',null),

('Select Gift Voucher','gift_voucher','select',null),
('Create Gift Voucher','create_gift_voucher','execute',null),
('Update Gift Voucher','update_gift_voucher','execute',null),
('Delete Gift Voucher','delete_gift_voucher','execute',null),

('Select Purchase Bill Inventory Item','purchase_bill_inv_item','select',null),
('Select Purchase Bill','purchase_bill','select',null),
('Create Purchase Bill','create_purchase_bill','execute',null),
('Update Purchase Bill','update_purchase_bill','execute',null),
('Delete Purchase Bill','delete_purchase_bill','execute',null),

('Select Debit Note Inventory Item','debit_note_inv_item','select',null),
('Select Debit Note','debit_note','select',null),
('Create Debit Note','create_debit_note','execute',null),
('Update Debit Note','update_debit_note','execute',null),
('Delete Debit Note','delete_debit_note','execute',null),

('Select Sale Bill Inventory Item','sale_bill_inv_item','select',null),
('Select Sale Bill','sale_bill','select',null),
('Create Sale Bill','create_sale_bill','execute',null),
('Update Sale Bill','update_sale_bill','execute',null),
('Delete Sale Bill','delete_sale_bill','execute',null),

('Select Credit Note Inventory Item','credit_note_inv_item','select',null),
('Select Credit Note','credit_note','select',null),
('Create Credit Note','create_credit_note','execute',null),
('Update Credit Note','update_credit_note','execute',null),
('Delete Credit Note','delete_credit_note','execute',null),

('Select Personal Use Purchase Inventory Item','personal_use_purchase_inv_item','select',null),
('Select Personal Use Purchase','personal_use_purchase','select',null),
('Create Personal Use Purchase','create_personal_use_purchase','execute',null),
('Update Personal Use Purchase','update_personal_use_purchase','execute',null),
('Delete Personal Use Purchase','delete_personal_use_purchase','execute',null),

('Select Stock Adjustment Inventory Item','stock_adjustment_inv_item','select',null),
('Select Stock Adjustment','stock_adjustment','select',null),
('Create Stock Adjustment','create_stock_adjustment','execute',null),
('Update Stock Adjustment','update_stock_adjustment','execute',null),
('Delete Stock Adjustment','delete_stock_adjustment','execute',null),

('Select Stock Deduction Inventory Item','stock_deduction_inv_item','select',null),
('Select Stock Deduction','stock_deduction','select',null),
('Create Stock Deduction','create_stock_deduction','execute',null),
('Update Stock Deduction','update_stock_deduction','execute',null),
('Delete Stock Deduction','delete_stock_deduction','execute',null),

('Select Stock Addition Inventory Item','stock_addition_inv_item','select',null),
('Select Stock Addition','stock_addition','select',null),
('Create Stock Addition','create_stock_addition','execute',null),
('Update Stock Addition','update_stock_addition','execute',null),
('Delete Stock Addition','delete_stock_addition','execute',null),

('Select Material Conversion Inventory Item','material_conversion_inv_item','select',null),
('Select Material Conversion','material_conversion','select',null),
('Create Material Conversion','create_material_conversion','execute',null),
('Update Material Conversion','update_material_conversion','execute',null),
('Delete Material Conversion','delete_material_conversion','execute',null),

('Select Customer Advance','customer_advance','select',null),
('Create Customer Advance','create_customer_advance','execute',null),
('Update Customer Advance','update_customer_advance','execute',null),
('Delete Customer Advance','delete_customer_advance','execute',null),

('Select Vendor Bill Map','vendor_bill_map','select',null),
('Insert Vendor Bill Map','vendor_bill_map','insert',null),
('Update Vendor Bill Map','vendor_bill_map','update','{"start_row", "name", "unit", "qty", "mrp", "rate", "free", "batch_no", "expiry",
    "expiry_format", "discount"}'),
('Delete Vendor Bill Map','vendor_bill_map','delete',null),

('Select Vendor Item Map','vendor_item_map','select',null),
('Insert Vendor Item Map','vendor_item_map','insert','{"vendor_id", "inventory_id", "vendor_inventory"}'),
('Update Vendor Item Map','vendor_item_map','update','{"vendor_inventory"}'),
('Delete Vendor Item Map','vendor_item_map','delete',null),

('Select voucher_register_detail','voucher_register_detail','select',null),
('Select Purchase Register Detail','purchase_register_detail','select',null),
('Select Sale Register Detail','sale_register_detail','select',null),
('Select Scheduled Drug Report','scheduled_drug_report','select',null),
('Select POS Counter Register','pos_counter_register','select',null),
('Select Stock Journal Detail','stock_journal_detail','select',null),
('Select Account Pending','account_pending','select',null),
('POS Counter Summary','pos_counter_summary','execute',null),
('voucher_register_summary','voucher_register_summary','execute',null),

('Account Book Detail','account_book_detail','execute',null),
('Account Closing','account_closing','execute',null),
('Account Book Group','account_book_group','execute',null);
