create view purchase_register_detail
as
select
    id,
    date,
    branch,
    branch_name,
    vendor,
    vendor_name,
    voucher,
    voucher_no,
    voucher_type,
    base_voucher_type::text as base_voucher_type,
    ref_no,
    purchase_mode::text as purchase_mode,
    amount
from purchase_bill
union all
select
    id,
    date,
    branch,
    branch_name,
    vendor,
    vendor_name,
    voucher,
    voucher_no,
    voucher_type,
    base_voucher_type::text as base_voucher_type,
    ref_no,
    purchase_mode::text as purchase_mode,
    (amount * -1) as amount
from debit_note;

