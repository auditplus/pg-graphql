INSERT INTO account(name, account_type_id, alias_name, commission, bill_wise_detail,  due_based_on, due_days, credit_limit)
VALUES ('MainBranchAccount', 20, 'MBAc', 0, false, 'EFF_DATE', 0, 0);
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
