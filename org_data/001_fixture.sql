INSERT INTO account(name, account_type_id, contact_type, alias_name, bill_wise_detail, due_based_on)
VALUES ('MainBranchAccount', 20, N'ACCOUNT'::typ_contact_type, 'MBAc', false, 'EFF_DATE'::typ_due_based_on);
--##
INSERT INTO gst_registration(reg_type, gst_no, state_id)
VALUES ('REGULAR','33AAICR8359N1ZN','33');
--##
INSERT INTO branch(name, telephone, address, city,pincode,state_id,voucher_no_prefix,account_id)
VALUES ('MainBranch','044-61234700', '118B, GNT Road, Padiyanallur, Redhills','Chennai','600052',33,'MB',101);
--##
INSERT INTO unit (name, uqc_id, symbol, precision, conversions)
VALUES ('PCS', 'PCS', 'PCS', 0, '[{"unitId":1, "conversion": 1}]'::jsonb);
--##
INSERT INTO division (name) VALUES
('DEFAULT'),('FURNITURES'),('VESSELS'),('SAREE'),('KIDS'),('LADIES'),('FOOTWEARS'),
('GENTS'),('GIFT AND TOYS'),('SUPERMARKET'),('ELECTRONICS'),('CANTEEN'),
('VEGETABLE AND FRUIT'),('SILK SAREE'),('SUITING &  SHIRTING'),('COSMETICS'),
('MOBILE&WATCHES'),('SMALL APPLIANCE'),('BIG APPLIANCE');
--##
UPDATE category SET category='BRAND', active=true WHERE id = 'INV_CAT1';
--##
UPDATE category SET category='CATEGORY', active=true WHERE id = 'INV_CAT2';
--##
UPDATE category SET category='SUB CATEGORY', active=true WHERE id = 'INV_CAT3';
--##
UPDATE category SET category='SPL SUB CATEGORY', active=true WHERE id = 'INV_CAT4';
--##--UNDER SUNDRY_CREDITOR(19)
INSERT INTO account_type(name, parent_id) values ('Trade Creditors',19);
--##
INSERT INTO account_type(name, parent_id) values ('Creditors for Expenses',19);
--##
INSERT INTO account_type(name, parent_id) values ('Creditors for Assets',19);
--##
INSERT INTO account_type(name, parent_id) values ('CREDITORS FOR CONSTRUCTIONS',19);
--##
INSERT INTO account_type(name, parent_id) values ('Other Creditors',19);
--##--UNDER INDIRECT_EXPENSE(7)
INSERT INTO account_type(name, parent_id) values ('TRANSFER EXPENSES',7);
--##
INSERT INTO account_type(name, parent_id) values ('Office and Administrative Expenses',7);
--##
INSERT INTO account_type(name, parent_id) values ('FINANCIAL EXPENSES',7);
--##
INSERT INTO account_type(name, parent_id) values ('Employee Benefit Expenses.',7);
--##
INSERT INTO account_type(name, parent_id) values ('Insurance Expenses',7);
--##
INSERT INTO account_type(name, parent_id) values ('Repairs & Maintenance',7);
--##
INSERT INTO account_type(name, parent_id) values ('Selling and distribution Expenses',7);
--##
INSERT INTO account_type(name, parent_id) values ('Electrical Charges',7);
--##
INSERT INTO account_type(name, parent_id) values ('LEGAL EXPENSES',7);
--##
INSERT INTO account_type(name, parent_id) values ('CONSTRUCTION EXPENSES',7);
--##--UNDER CURRENT_LIABILITY(2)
INSERT INTO account_type(name, parent_id) values ('STATUTORY REMITTANCE',2);
--##
INSERT INTO account_type(name, parent_id) values ('UNSECURED LOAN',2);
--##
INSERT INTO account_type(name, parent_id) values ('WORKING CAPITAL DEMAND LOAN',2);
--##
INSERT INTO account_type(name, parent_id) values ('advance from customers',2);
--##--UNDER FIXED_ASSET(9)
INSERT INTO account_type(name, parent_id) values ('PLANT AND MECHINERY',9);
--##
INSERT INTO account_type(name, parent_id) values ('FURNITURE & FITTINGS',9);
--##
INSERT INTO account_type(name, parent_id) values ('Electrical & Fittings',9);
--##
INSERT INTO account_type(name, parent_id) values ('Computers & Computer Accessories',9);
--##
INSERT INTO account_type(name, parent_id) values ('VEHICLES',9);
--##
INSERT INTO account_type(name, parent_id) values ('BUILDING',9);
--##
INSERT INTO account_type(name, parent_id) values ('STP',9);
--##
INSERT INTO account_type(name, parent_id) values ('118B, G.N.T. ROAD, BUILDING',9);
--##
INSERT INTO account_type(name, parent_id) values ('INTERIORS',9);
--##--UNDER CURRENT_ASSET(1)
INSERT INTO account_type(name, parent_id) values ('OTHER CURRENT ASSETS',1);
--##
INSERT INTO account_type(name, parent_id) values ('PRE-OPERATIVE EXPENSES',1);
--##
INSERT INTO account_type(name, parent_id) values ('SECURITY DEPOSIT FOR SUPPLIERS',1);
--##--UNDER DIRECT_EXPENSE(6)
INSERT INTO account_type(name, parent_id) values ('FREIGHT',6);
--##--UNDER CURRENT_LIABILITY(2)-MAIN GROUP NAME
INSERT INTO account_type(name, parent_id) values ('CAPITAL ACCOUNT',2);
--##
INSERT INTO account_type(name, parent_id) values ('SECURED LOANS',2);
--##
INSERT INTO account_type(name, parent_id) values ('LOANS (LIABILITIES)',2);
--##
INSERT INTO account_type(name, parent_id) values ('SHARE CAPITAL',2);
--##
INSERT INTO account_type(name, parent_id) values ('OUTSTANDING LIABILITIES',2);
--##--UNDER CURRENT_ASSET(1)-MAIN GROUP NAME
INSERT INTO account_type(name, parent_id) values ('DEPOSITS',1);
--##
INSERT INTO account_type(name, parent_id) values ('LOANS & ADVANCES',1);
--##
INSERT INTO account_type(name, parent_id) values ('PLANT & MACHINERY',1);
--##--UNDER INDIRECT_EXPENSE(7)-MAIN GROUP NAME
INSERT INTO account_type(name, parent_id) values ('SELLING & DISTRIBUTION EXPENSES',7);
