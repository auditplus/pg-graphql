create view voucher_register_detail
as
select id,
       date,
       ref_no,
       voucher_type_id,
       base_voucher_type,
       mode,
       voucher_no,
       branch_id,
       branch_name
from voucher;