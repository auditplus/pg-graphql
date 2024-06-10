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
       (amount * -1)                                                                  as amount,
       (case when cash_amount > 0 then (cash_amount * -1) else cash_amount end)       as cash_amount,
       (case when credit_amount > 0 then (credit_amount * -1) else credit_amount end) as credit_amount,
       (case when bank_amount > 0 then (bank_amount * -1) else bank_amount end)       as bank_amount,
       0::float                                                                       as eft_amount,
       0::float                                                                       as gift_voucher_amount
from credit_note;
--##
comment on view sale_register_detail is e'@graphql({"primary_key_columns": ["voucher_id"]})';