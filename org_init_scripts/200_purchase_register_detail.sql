create view purchase_register_detail
as
select id,
       date,
       branch_id,
       branch_name,
       vendor_id,
       vendor_name,
       voucher_id,
       voucher_no,
       voucher_type_id,
       base_voucher_type::text as base_voucher_type,
       ref_no,
       purchase_mode::text     as purchase_mode,
       amount
from purchase_bill
union all
select id,
       date,
       branch_id,
       branch_name,
       vendor_id,
       vendor_name,
       voucher_id,
       voucher_no,
       voucher_type_id,
       base_voucher_type::text as base_voucher_type,
       ref_no,
       purchase_mode::text     as purchase_mode,
       (amount * -1)           as amount
from debit_note;
--##
comment on view purchase_register_detail is e'@graphql({"primary_key_columns": ["voucher_id"]})';