create view voucher_register_detail
as
select
    voucher.id as id,
    date,
    (ac_trns[0]->>'account')::int as account,
    account.name as account_name,
    ref_no,
    voucher_type,
    base_voucher_type::text as base_voucher_type,
    mode::text as mode,
    voucher_no,
    coalesce((ac_trns[0]->>'debit')::float,amount,0) as debit,
    coalesce((ac_trns[0]->>'credit')::float,0) as credit,
    branch,
    branch_name
from
    voucher
left join account on ((ac_trns[0]->>'account')::int) = account.id;