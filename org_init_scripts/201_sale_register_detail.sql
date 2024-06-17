create view sale_register_detail
as
select id,
       date,
       branch_id,
       branch_name,
       voucher_type_id,
       base_voucher_type,
       voucher_id,
       voucher_no,
       customer_id,
       customer_name,
       ref_no,
       amount,
       cash_amount,
       credit_amount,
       bank_amount,
       eft_amount,
       gift_voucher_amount
from sale_bill
union all
select id,
       date,
       branch_id,
       branch_name,
       voucher_type_id,
       base_voucher_type,
       voucher_id,
       voucher_no,
       customer_id,
       customer_name,
       ref_no,
       (amount * -1),
       (cash_amount * -1),
       (credit_amount * -1),
       (bank_amount * -1),
       0::float,
       0::float
from credit_note;
--##
comment on view sale_register_detail is e'@graphql({"primary_key_columns": ["voucher_id"]})';
