create view pos_counter_register
as
select row_number() over () as row_id,
       t.voucher_id,
       t.pos_counter_id,
       t.branch_id,
       t.branch_name,
       t.date,
       t.amount,
       t.particular,
       t.voucher_no,
       t.voucher_type_id,
       t.base_voucher_type,
       b.account_id,
       b.account_name,
       b.credit,
       b.debit,
       t.settlement_id,
       s.from_date,
       s.to_date,
       s.opening,
       s.closing
from pos_counter_transaction as t
         left join pos_counter_transaction_breakup as b on t.voucher_id = b.voucher_id
         left join pos_counter_settlement as s on t.settlement_id = s.id;
--##
comment on view pos_counter_register is e'@graphql({"primary_key_columns": ["row_id"]})';