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
insert into permission (id,name, resource, action, fields) values
('account_type__select',null),
('account_type__insert','{"name","parent_id","description"}'),
('account_type__update','{"name","description"}'),
('account_type__delete',null),
('category__select',null),
('category__update','{"category","active","sort_order"}'),
('category_bulk_update__execute','execute',null),
('warehouse__select',null),
('warehouse__insert','{"name", "mobile", "email", "telephone", "address", "city", "pincode", "state_id", "country_id"}'),
('warehouse__update','{"name", "mobile", "email", "telephone", "address", "city", "pincode", "state_id", "country_id"}'),
('warehouse__delete','Delete Warehouse','warehouse','delete',null),
('member__select',null),
('member__insert','{"name", "pass", "remote_access", "settings", "role_id", "user_id", "nick_name"}'),
('member__update','{"name", "pass", "remote_access", "settings", "role_id", "user_id", "nick_name"}'),
('member_profile__execute',null),
('member_role__select','Select Member Role','member_role','select',null),
('member_role__insert','Insert Member Role','member_role','insert','{"id", "name", "perms", "ui_perms"}'),
('member_role__update','Update Member Role','member_role','update','{"id", "name", "perms", "ui_perms"}'),
('approval_tag__select','Select Approval Tag','approval_tag','select',null),
('approval_tag__insert','Insert Approval Tag','approval_tag','insert','{"name", "members"}'),
('approval_tag__update','Update Approval Tag','approval_tag','update','{"name", "members"}'),
('approval_tag__delete','Delete Approval Tag','approval_tag','delete',null),
('tds_nature_of_payment__select','Select Tds Nature of Payment','tds_nature_of_payment','select',null),
('tds_nature_of_payment__insert','Insert Tds Nature of Payment','tds_nature_of_payment','insert','{"name", "section", "ind_huf_rate", "ind_huf_rate_wo_pan", "other_deductee_rate", "other_deductee_rate_wo_pan", "threshold"}'),
('tds_nature_of_payment__update','Update Tds Nature of Payment','tds_nature_of_payment','update','{"name", "section", "ind_huf_rate", "ind_huf_rate_wo_pan", "other_deductee_rate", "other_deductee_rate_wo_pan", "threshold"}'),
('tds_nature_of_payment__delete','Delete Tds Nature of Payment','tds_nature_of_payment','delete',null),
('bank_beneficiary__select','Select Bank Beneficiary','bank_beneficiary','select',null),
('bank_beneficiary__insert','Insert Bank Beneficiary','bank_beneficiary','insert','{"account_no", "bank_name", "branch_name", "ifs_code", "account_type", "account_holder_name"}'),
('bank_beneficiary__update','Update Bank Beneficiary','bank_beneficiary','update','{"account_no", "bank_name", "branch_name", "ifs_code", "account_type", "account_holder_name"}'),
('bank_beneficiary__delete','Delete Bank Beneficiary','bank_beneficiary','delete',null),
('doctor__select','Select Doctor','doctor','select',null),
('doctor__insert','Insert Doctor','doctor','insert','{"name", "license_no"}'),
('doctor__update','Update Doctor','doctor','update','{"name", "license_no"}'),
('doctor__delete','Delete Doctor','doctor','delete',null),
('stock_location__select','Select Stock Location','stock_location','select',null),
('stock_location__insert','Insert Stock Location','stock_location','insert','{"name"}'),
('stock_location__update','Update Stock Location','stock_location','update','{"name"}'),
('stock_location__delete','Delete Stock Location','stock_location','delete',null),
('display_rack__select','Select Display Rack','display_rack','select',null),
('display_rack__insert','Insert Display Rack','display_rack','insert','{"name"}'),
('display_rack__update','Update Display Rack','display_rack','update','{"name"}'),
('display_rack__delete','Delete Display Rack','display_rack','delete',null),
('tag__select','Select Tag','tag','select',null),
('tag__insert','Insert Tag','tag','insert','{"name"}'),
('tag__update','Update Tag','tag','update','{"name"}'),
('tag__delete','Delete Tag','tag','delete',null),
('manufacturer__select','Select Manufacturer','manufacturer','select',null),
('manufacturer__insert','Insert Manufacturer','manufacturer','insert','{"name", "mobile", "email", "telephone"}'),
('manufacturer__update','Update Manufacturer','manufacturer','update','{"name", "mobile", "email", "telephone"}'),
('manufacturer__delete','Delete Manufacturer','manufacturer','delete',null),
('sale_incharge__select','Select Sale Incharge','sale_incharge','select',null),
('sale_incharge__insert','Insert Sale Incharge','sale_incharge','insert','{"name", "code"}'),
('sale_incharge__update','Update Sale Incharge','sale_incharge','update','{"name", "code"}'),
('sale_incharge__delete','Delete Sale Incharge','sale_incharge','delete',null),
('price_list__select','Select Price List','price_list','select',null),
('price_list__insert','Insert Price List','price_list','insert','{"name", "customer_tag_id"}'),
('price_list__update','Update Price List','price_list','update','{"name", "customer_tag_id"}'),
('price_list__delete','Delete Price List','price_list','delete',null),
('price_list_condition__select','Select Price List Condition','price_list_condition','select',null),
('price_list_condition__insert','Insert Price List Condition','price_list_condition','insert',null),
('price_list_condition__update','Update Price List Condition','price_list_condition','update','{"apply_on", "computation", "priority", 
              "min_qty", "min_value", "value", "branch_id", "inventory_tags", "batches","inventory_id",
              "category1_id", "category2_id", "category3_id", "category4_id", "category5_id",
              "category6_id", "category7_id", "category8_id", "category9_id", "category10_id"}'),
('price_list_condition__delete','Delete Price List Condition','price_list_condition','delete',null),
('print_template__select','Select Print Template','print_template','select',null),
('print_template__insert','Insert Print Template','print_template','insert','{"name", "config", "layout", "voucher_mode"}'),
('print_template__update','Update Print Template','print_template','update','{"name", "config", "layout", "voucher_mode"}'),
('print_template__delete','Delete Print Template','print_template','delete',null),
('gst_registration__select','Select Gst Registration','gst_registration','select',null),
('gst_registration__insert','Insert Gst Registration','gst_registration','insert','{"reg_type", "gst_no", "state_id", "username", "email", "e_invoice_username", "e_password"}'),
('gst_registration__update','Update Gst Registration','gst_registration','update','{"reg_type", "gst_no", "state_id", "username", "email", "e_invoice_username", "e_password"}'),
('gst_registration__delete','Delete Gst Registration','gst_registration','delete',null),
('account__select','Select Account','account','select',null),
('account__insert','Insert Account','account','insert','{"name", "contact_type", "account_type_id", "alias_name", "cheque_in_favour_of", "description",
    "commission", "gst_reg_type", "gst_location_id", "gst_no", "gst_is_exempted", "gst_exempted_desc", "sac_code",
    "bill_wise_detail", "is_commission_discounted", "due_based_on", "due_days", "credit_limit", "pan_no",
    "aadhar_no", "mobile", "email", "contact_person", "address", "city", "pincode", "category1", "category2", "category3", "category4",
    "category5", "state_id", "country_id", "bank_beneficiary_id", "agent_id", "commission_account_id", "gst_tax_id",
    "tds_nature_of_payment_id", "tds_deductee_type_id", "short_name", "transaction_enabled", "alternate_mobile",
    "telephone", "delivery_address", "enable_loyalty_point", "tags"}'),
('account__update','Update Account','account','update','{"name", "alias_name", "cheque_in_favour_of", "description",
    "commission", "gst_reg_type", "gst_location_id", "gst_no", "gst_is_exempted", "gst_exempted_desc", "sac_code",
    "bill_wise_detail", "is_commission_discounted", "due_based_on", "due_days", "credit_limit", "pan_no",
    "aadhar_no", "mobile", "email", "contact_person", "address", "city", "pincode", "category1", "category2", "category3", "category4",
    "category5", "state_id", "country_id", "bank_beneficiary_id", "agent_id", "commission_account_id", "gst_tax_id",
    "tds_nature_of_payment_id", "tds_deductee_type_id", "short_name", "transaction_enabled", "alternate_mobile",
    "telephone", "delivery_address", "enable_loyalty_point", "tags"}'),
('account__delete','Delete Account','account','delete',null),

('branch__select','Select Branch','branch','select',null),
('branch__insert','Insert Branch','branch','insert','{"name", "mobile", "alternate_mobile", "email", "telephone", "contact_person", "address", "city", "pincode", "state_id",
    "country_id", "gst_registration_id", "voucher_no_prefix", "misc", "members", "account_id"}'),
('branch__update','Update Branch','branch','update','{"name", "mobile", "alternate_mobile", "email", "telephone", "contact_person", "address", "city", "pincode", "state_id",
    "country_id", "gst_registration_id", "voucher_no_prefix", "misc", "members"}'),
('branch__delete','Delete Branch','branch','delete',null),

('stock_value__select','Select Stock Value','stock_value','select',null),
('stock_value__insert','Select Stock Value','stock_value','insert',null),
('stock_value__update','Select Stock Value','stock_value','update',null),
('stock_value__delete','Select Stock Value','stock_value','delete',null),

('offer_management__select','Select Offer Management','offer_management','select',null),
('offer_management__insert','Insert Offer Management','offer_management','insert','{"name", "conditions", "rewards", "branch_id", "price_list_id", "start_date", "end_date"}'),
('offer_management__update','Update Offer Management','offer_management','update','{"name", "conditions", "rewards", "branch_id", "price_list_id", "start_date", "end_date"}'),
('offer_management__delete','Delete Offer Management','offer_management','delete',null),
('offer_management_condition__select','Select Offer Management','offer_management_condition','select',null),
('offer_management_reward__select','Select Offer Management','offer_management_reward','select',null),

('transport__select','Select Transport','transport','select',null),
('transport__insert','Insert Transport','transport','insert','{"name", "mobile", "email", "telephone"}'),
('transport__update','Update Transport','transport','update','{"name", "mobile", "email", "telephone"}'),
('transport__delete','Delete Transport','transport','delete',null),

('pos_server__select','Select Pos Server','pos_server','select',null),
('pos_server__insert','Insert Pos Server','pos_server','insert','{"name", "branch_id", "mode"}'),
('pos_server__update','Update Pos Server','pos_server','update','{"name", "mode", "is_active"}'),
('pos_server__delete','Delete Pos Server','pos_server','delete',null),

('desktop_client__select','Select Desktop Client','desktop_client','select',null),
('desktop_client__insert','Insert Desktop Client','desktop_client','insert','{"name","branches"}'),
('desktop_client__update','Update Desktop Client','desktop_client','update','{"name","branches"}'),
('desktop_client__delete','Delete Desktop Client','desktop_client','delete',null),

('unit__select','Select Unit','unit','select',null),
('unit__insert','Insert Unit','unit','insert','{"name", "uqc_id", "symbol", "precision", "conversions"}'),
('unit__update','Update Unit','unit','update','{"name", "uqc_id", "symbol", "precision", "conversions"}'),
('unit__delete','Delete Unit','unit','delete',null),

('unit_conversion__select','Select Unit Conversion','unit_conversion','select',null),
('unit_conversion__insert','Insert Unit Conversion','unit_conversion','insert',null),
('unit_conversion__update','Update Unit Conversion','unit_conversion','update',null),
('unit_conversion__delete','Delete Unit Conversion','unit_conversion','delete',null),

('category_option__select','Select Category Option','category_option','select',null),
('category_option__insert','Insert Category Option','category_option','insert','{"category_id", "name", "active"}'),
('category_option__update','Update Category Option','category_option','update','{"category_id", "name", "active"}'),
('category_option__delete','Delete Category Option','category_option','delete',null),

('division__select','Select Division','division','select',null),
('division__insert','Insert Division','division','insert','{"name"}'),
('division__update','Update Division','division','update','{"name"}'),
('division__delete','Delete Division','division','delete',null),

('gift_coupon__select','Select Gift Coupon','gift_coupon','select',null),

('pos_counter__select','Select Pos Counter','pos_counter','select',null),
('pos_counter__insert','Insert Pos Counter','pos_counter','insert','{"name"}'),
('pos_counter__update','Update Pos Counter','pos_counter','update','{"name"}'),
('pos_counter__delete','delete Pos Counter','pos_counter','select',null),

('voucher_type__select','Select Voucher Type','voucher_type','select',null),
('voucher_type__insert','Insert Voucher Type','voucher_type','insert','{"name", "prefix", "sequence_id", "base_type", "config", "members", "approval"}'),
('voucher_type__update','Update Voucher Type','voucher_type','update','{"name", "prefix", "sequence_id", "config", "members", "approval"}'),
('voucher_type__delete','Delete Voucher Type','voucher_type','delete',null),

('inventory__select','Select Inventory','inventory','select',null),
('inventory__insert','Insert Inventory','inventory','insert','{"name", "division_id", "inventory_type", "allow_negative_stock", "gst_tax_id", "unit_id", "loose_qty",
    "reorder_inventory_id", "bulk_inventory_id", "qty", "sale_unit_id", "purchase_unit_id", "cess", "purchase_config",
    "sale_config", "barcodes", "tags", "hsn_code", "description", "manufacturer_id", "manufacturer_name", "vendor_id",
    "vendor_name", "vendors", "salts", "set_rate_values_via_purchase", "apply_s_rate_from_master_for_sale",
    "category1", "category2", "category3", "category4", "category5", "category6", "category7", "category8",
    "category9", "category10"}'),
('inventory__update','Update Inventory','inventory','update','{"name", "inventory_type", "allow_negative_stock", "gst_tax_id", "unit_id",
    "reorder_inventory_id", "bulk_inventory_id", "qty", "sale_unit_id", "purchase_unit_id", "cess", "purchase_config",
    "sale_config", "barcodes", "tags", "hsn_code", "description", "manufacturer_id", "manufacturer_name", "vendor_id",
    "vendor_name", "vendors", "salts", "set_rate_values_via_purchase", "apply_s_rate_from_master_for_sale",
    "category1", "category2", "category3", "category4", "category5", "category6", "category7", "category8",
    "category9", "category10"}'),
('inventory__delete','Delete Inventory','inventory','delete',null),

('inventory_branch_detail__select','Select Inventory Branch Detail','inventory_branch_detail','select',null),
('inventory_branch_detail__insert','Insert Inventory Branch Detail','inventory_branch_detail','insert','{"inventory_id", "inventory_name", "branch_id", "branch_name", "stock_location_id",
    "s_disc", "discount_1", "discount_2", "vendor_id", "s_customer_disc", "mrp_price_list", "s_rate_price_list",
    "nlc_price_list", "mrp", "s_rate", "p_rate_tax_inc", "p_rate", "landing_cost", "nlc", "stock", "reorder_inventory_id",
    "reorder_mode", "reorder_level", "min_order", "max_order"}'),
('inventory_branch_detail__update','Update Inventory Branch Detail','inventory_branch_detail','update','{"inventory_name", "branch_name", "stock_location_id",
    "s_disc", "discount_1", "discount_2", "vendor_id", "s_customer_disc", "mrp_price_list", "s_rate_price_list",
    "nlc_price_list", "mrp", "s_rate", "p_rate_tax_inc", "p_rate", "landing_cost", "nlc", "stock", "reorder_inventory_id",
    "reorder_mode", "reorder_level", "min_order", "max_order"}'),

('merge_inventory__execute','Merge Inventory','merge_inventory','execute',null),

('approval_log__select','Select Approval Log','approval_log','select',null),

('financial_year__select','Select Financial Year','financial_year','select',null),
('create_financial_year__execute','Create Financial Year','create_financial_year','execute',null),

('batch__select','Select Batch','batch','select',null),
('batch__update','Update Batch','batch','update','{"batch_no", "expiry", "s_rate", "mrp"}'),
('batch_label__select','Select Batch Label','batch_label','select',null),

('bill_allocation__select','Select Bill Allocation','bill_allocation','select',null),
('bank_txn__select','Select Bank Transaction','bank_txn','select',null),
('bank_txn__update','Update Bank Transaction','bank_txn','update','{"bank_date"}'),

('account_opening__select','Select Account Opening','account_opening','select',null),
('set_account_opening__execute','Set Account Opening','set_account_opening','execute',null),

('inventory_opening__select','Select Inventory Opening','inventory_opening','select',null),
('set_inventory_opening__execute','Set Inventory Opening','set_inventory_opening','execute',null),

('tds_on_voucher__select','Select Tds On Voucher','tds_on_voucher','select',null),
('tds_on_voucher_section_break_up__execute','Tds On Voucher Section Breakup','tds_on_voucher_section_break_up','execute',null),

('exchange__select','Select Exchange','exchange','select',null),
('exchange_adjustment__select','Select Exchange Adjustment','exchange_adjustment','select',null),

('voucher__select','Select Voucher','voucher','select',null),
('create_voucher__execute','Create Voucher','create_voucher','execute',null),
('update_voucher__execute','Update Voucher','update_voucher','execute',null),
('delete_voucher__execute','Delete Voucher','delete_voucher','execute',null),
('approve_voucher__execute','Approve Voucher','approve_voucher','execute',null),

('goods_inward_note__select','Select Goods Inward Note','goods_inward_note','select',null),
('create_goods_inward_note__execute','Create Goods Inward Note','create_goods_inward_note','execute',null),
('update_goods_inward_note__execute','Update Goods Inward Note','update_goods_inward_note','execute',null),
('delete_goods_inward_note__execute','Delete Goods Inward Note','delete_goods_inward_note','execute',null),

('gift_voucher__select','Select Gift Voucher','gift_voucher','select',null),
('create_gift_voucher__execute','Create Gift Voucher','create_gift_voucher','execute',null),
('update_gift_voucher__execute','Update Gift Voucher','update_gift_voucher','execute',null),
('delete_gift_voucher__execute','Delete Gift Voucher','delete_gift_voucher','execute',null),

('purchase_bill_inv_item__select','Select Purchase Bill Inventory Item','purchase_bill_inv_item','select',null),
('purchase_bill__select','Select Purchase Bill','purchase_bill','select',null),
('create_purchase_bill__execute','Create Purchase Bill','create_purchase_bill','execute',null),
('update_purchase_bill__execute','Update Purchase Bill','update_purchase_bill','execute',null),
('delete_purchase_bill__execute','Delete Purchase Bill','delete_purchase_bill','execute',null),

('debit_note_inv_item__select','Select Debit Note Inventory Item','debit_note_inv_item','select',null),
('debit_note__select','Select Debit Note','debit_note','select',null),
('create_debit_note__execute','Create Debit Note','create_debit_note','execute',null),
('update_debit_note__execute','Update Debit Note','update_debit_note','execute',null),
('delete_debit_note__execute','Delete Debit Note','delete_debit_note','execute',null),

('sale_bill_inv_item__select','Select Sale Bill Inventory Item','sale_bill_inv_item','select',null),
('sale_bill__select','Select Sale Bill','sale_bill','select',null),
('create_sale_bill__execute','Create Sale Bill','create_sale_bill','execute',null),
('update_sale_bill__execute','Update Sale Bill','update_sale_bill','execute',null),
('delete_sale_bill__execute','Delete Sale Bill','delete_sale_bill','execute',null),

('credit_note_inv_item__select','Select Credit Note Inventory Item','credit_note_inv_item','select',null),
('credit_note__select','Select Credit Note','credit_note','select',null),
('create_credit_note__execute','Create Credit Note','create_credit_note','execute',null),
('update_credit_note__execute','Update Credit Note','update_credit_note','execute',null),
('delete_credit_note__execute','Delete Credit Note','delete_credit_note','execute',null),

('personal_use_purchase_inv_item__select','Select Personal Use Purchase Inventory Item','personal_use_purchase_inv_item','select',null),
('personal_use_purchase__select','Select Personal Use Purchase','personal_use_purchase','select',null),
('create_personal_use_purchase__execute','Create Personal Use Purchase','create_personal_use_purchase','execute',null),
('update_personal_use_purchase__execute','Update Personal Use Purchase','update_personal_use_purchase','execute',null),
('delete_personal_use_purchase__execute','Delete Personal Use Purchase','delete_personal_use_purchase','execute',null),

('stock_adjustment_inv_item__select','Select Stock Adjustment Inventory Item','stock_adjustment_inv_item','select',null),
('stock_adjustment__select','Select Stock Adjustment','stock_adjustment','select',null),
('create_stock_adjustment__execute','Create Stock Adjustment','create_stock_adjustment','execute',null),
('update_stock_adjustment__execute','Update Stock Adjustment','update_stock_adjustment','execute',null),
('delete_stock_adjustment__execute','Delete Stock Adjustment','delete_stock_adjustment','execute',null),

('stock_deduction_inv_item__select','Select Stock Deduction Inventory Item','stock_deduction_inv_item','select',null),
('stock_deduction__select','Select Stock Deduction','stock_deduction','select',null),
('create_stock_deduction__execute','Create Stock Deduction','create_stock_deduction','execute',null),
('update_stock_deduction__execute','Update Stock Deduction','update_stock_deduction','execute',null),
('delete_stock_deduction__execute','Delete Stock Deduction','delete_stock_deduction','execute',null),

('stock_addition_inv_item__select','Select Stock Addition Inventory Item','stock_addition_inv_item','select',null),
('stock_addition__select','Select Stock Addition','stock_addition','select',null),
('create_stock_addition__execute','Create Stock Addition','create_stock_addition','execute',null),
('update_stock_addition__execute','Update Stock Addition','update_stock_addition','execute',null),
('delete_stock_addition__execute','Delete Stock Addition','delete_stock_addition','execute',null),

('material_conversion_inv_item__select','Select Material Conversion Inventory Item','material_conversion_inv_item','select',null),
('material_conversion__select','Select Material Conversion','material_conversion','select',null),
('create_material_conversion__execute','Create Material Conversion','create_material_conversion','execute',null),
('update_material_conversion__execute','Update Material Conversion','update_material_conversion','execute',null),
('delete_material_conversion__execute','Delete Material Conversion','delete_material_conversion','execute',null),

('customer_advance__select','Select Customer Advance','customer_advance','select',null),
('create_customer_advance__execute','Create Customer Advance','create_customer_advance','execute',null),
('update_customer_advance__execute','Update Customer Advance','update_customer_advance','execute',null),
('delete_customer_advance__execute','Delete Customer Advance','delete_customer_advance','execute',null),

('vendor_bill_map__select','Select Vendor Bill Map','vendor_bill_map','select',null),
('vendor_bill_map__insert','Insert Vendor Bill Map','vendor_bill_map','insert',null),
('vendor_bill_map__update','Update Vendor Bill Map','vendor_bill_map','update','{"start_row", "name", "unit", "qty", "mrp", "rate", "free", "batch_no", "expiry",
    "expiry_format", "discount"}'),
('vendor_bill_map__delete','Delete Vendor Bill Map','vendor_bill_map','delete',null),

('vendor_item_map__select','Select Vendor Item Map','vendor_item_map','select',null),
('vendor_item_map__insert','Insert Vendor Item Map','vendor_item_map','insert','{"vendor_id", "inventory_id", "vendor_inventory"}'),
('vendor_item_map__update','Update Vendor Item Map','vendor_item_map','update','{"vendor_inventory"}'),
('vendor_item_map__delete','Delete Vendor Item Map','vendor_item_map','delete',null),

('purchase_register_detail__select','Select Purchase Register Detail','purchase_register_detail','select',null),
('sale_register_detail__select','Select Sale Register Detail','sale_register_detail','select',null),
('scheduled_drug_report__select','Select Scheduled Drug Report','scheduled_drug_report','select',null),
('pos_counter_register__select','Select POS Counter Register','pos_counter_register','select',null),
('pos_counter_summary__execute','POS Counter Summary','pos_counter_summary','execute',null),

('account_book_detail__execute','Account Book Detail','account_book_detail','execute',null),
('account_closing__execute','Account Closing','account_closing','execute',null),
('account_book_group__execute','Account Book Group','account_book_group','execute',null),

('pharma_salt__select','Select Pharma Salt','pharma_salt','select',null),
('pharma_salt__insert','Insert Pharma Salt','pharma_salt','insert','{"name", "drug_category"}'),
('pharma_salt__update','Update Pharma Salt','pharma_salt','update','{"name", "drug_category"}'),
('pharma_salt__delete','Delete Pharma Salt','pharma_salt','delete',null),

('pos_counter_transaction__select','Select POS Counter Transaction','pos_counter_transaction','select',null),
('pos_counter_transaction_breakup__select','Select POS Counter Transaction Breakup','pos_counter_transaction_breakup','select',null),
('pos_counter_session__select','Select POS Counter Session','pos_counter_session','select',null),
('close_pos_session__execute','Close POS Counter Session','close_pos_session','execute',null),

('account_pending__select','Account Pending','account_pending','select',null),
('voucher_register_detail__select','Voucher Register Detail','voucher_register_detail','select',null),
('voucher_register_summary__execute','Voucher Register Summary','voucher_register_summary','execute',null),

('ac_txn__select','Select Account Transaction','ac_txn','select','{"id", "account_id", "credit", "debit", "is_default"}');



