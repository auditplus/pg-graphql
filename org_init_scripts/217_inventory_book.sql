create view inventory_book
as
select id,
       inventory_id,
       date,
       customer_name as particular,
       ref_no,
       voucher_type_id,
       base_voucher_type,
       inventory_voucher_id,
       voucher_id,
       voucher_no,
       branch_id,
       branch_name,
       inward,
       outward
from inv_txn;
--##
comment on view inventory_book is e'@graphql({"primary_key_columns": ["id"]})';