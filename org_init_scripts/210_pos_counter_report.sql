create view pos_counter_register
as
select row_number() over () as row_id,
       t.voucher_id,
       t.pos_counter_id,
       t.branch_id,
       t.branch_name,
       t.date,
       t.bill_amount,
       t.particular,
       t.voucher_no,
       t.voucher_type_id,
       t.base_voucher_type,
       t.settlement_id,
       b.account_id,
       b.account_name,
       b.debit,
       b.credit,
       (b.debit-b.credit) as amount,
       s.from_date,
       s.to_date,
       s.opening,
       s.closing
from pos_counter_transaction as t
    left join pos_counter_transaction_breakup as b on t.voucher_id = b.voucher_id
    left join pos_counter_settlement as s on t.settlement_id = s.id;
--##
comment on view pos_counter_register is e'@graphql({"primary_key_columns": ["row_id"]})';
--##
create function pos_counter_summary(
    from_date date,
    to_date date,
    pos_counters int[] default '{}'::int[],
    accounts int[] default '{}'::int[],
    base_voucher_types text[] default '{}'::text[],
    settlement_id int default null,
    bill_amount float default null,
    amount float default null
)
returns json
as
$$
declare
    res json;
begin
    select json_agg(x.*) into res
    from (
        select json_build_object('credit',sum(credit),'debit',sum(debit)) as data
        from pos_counter_register as pcr
        where (date between pos_counter_summary.from_date and pos_counter_summary.to_date)
        and (case when pos_counter_summary.amount is not null then pcr.amount=abs(pos_counter_summary.amount) else true end)
        and (case when pos_counter_summary.settlement_id is not null then pcr.settlement_id=pos_counter_summary.settlement_id else true end)
        and (case when pos_counter_summary.bill_amount is not null then pcr.bill_amount=pos_counter_summary.bill_amount else true end)
        and (case when (array_length(pos_counters, 1) > 0) then pos_counter_id = any(pos_counters) else true end)
        and (case when (array_length(accounts, 1) > 0) then account_id = any(accounts) else true end)
        and (case when (array_length(base_voucher_types, 1) > 0) then base_voucher_type = any(base_voucher_types) else true end)
    ) x;
    return res;
end;
$$ language plpgsql immutable security definer;
