create view stock_journal_detail
as
select id, date, branch, branch_name, ref_no, amount,
       voucher, voucher_no, voucher_type, base_voucher_type::text
from material_conversion
union all
select id, date, branch, branch_name, ref_no, amount,
       voucher, voucher_no, voucher_type, base_voucher_type::text
from stock_deduction
union all
select id, date, branch, branch_name, ref_no, amount,
       voucher, voucher_no, voucher_type, base_voucher_type::text
from stock_adjustment
union all
select id, date, branch, branch_name, ref_no, amount,
       voucher, voucher_no, voucher_type, base_voucher_type::text
from stock_addition;