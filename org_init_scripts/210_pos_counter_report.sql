create view pos_counter_register
as
select row_number() over () as row_id,
       txn.voucher_id,
       txn.pos_counter_code,
       txn.branch_id,
       txn.branch_name,
       txn.date,
       txn.bill_amount,
       txn.particulars,
       txn.voucher_no,
       txn.voucher_type_id,
       txn.base_voucher_type,
       txn.voucher_mode,
       brk.account_id,
       brk.account_name,
       brk.debit,
       brk.credit,
       brk.amount,
       ses.id               as session_id,
       sett.opening,
       sett.closing,
       sett.id              as settlement_id
from pos_counter_transaction as txn
         left join pos_counter_transaction_breakup as brk on txn.voucher_id = brk.voucher_id
         left join pos_counter_session as ses on txn.session_id = ses.id
         left join pos_counter_settlement as sett on ses.settlement_id = sett.id;
--##
create function pos_counter_summary(json)
    returns table
            (
                credit      float,
                debit       float,
                amount      float,
                bill_amount float
            )
as
$$
declare
    base_types   text[] := (select array_agg(j::text)
                            from json_array_elements_text(($1 ->> 'base_voucher_types')::json) as j);
    accounts     int[]  := (select array_agg(j::int)
                            from json_array_elements_text(($1 ->> 'accounts')::json) as j);
    pos_counters text[] := (select array_agg(j::text)
                            from json_array_elements_text(($1 ->> 'pos_counters')::json) as j);
    from_date    date   := ($1 ->> 'from_date')::date;
    to_date      date   := ($1 ->> 'to_date')::date;
begin
    return query
        select sum(pcr.credit),
               sum(pcr.debit),
               sum(pcr.amount),
               sum(pcr.bill_amount)
        from pos_counter_register as pcr
        where case
                  when (from_date is not null and to_date is not null) then pcr.date between from_date and to_date
                  else true end
          and case
                  when (array_length(pos_counters, 1) > 0) then pcr.pos_counter_code = any (pos_counters)
                  else true end
          and case when (array_length(accounts, 1) > 0) then pcr.account_id = any (accounts) else true end
          and case
                  when (array_length(base_types, 1) > 0) then pcr.base_voucher_type = any (base_types)
                  else true end
          and case
                  when ($1 ->> 'settlement_id')::int is not null then pcr.settlement_id = ($1 ->> 'settlement_id')::int
                  else true end
          and case
                  when ($1 ->> 'bill_amount')::float is not null then pcr.bill_amount = ($1 ->> 'bill_amount')::float
                  else true end
          and case
                  when ($1 ->> 'amount')::float is not null then pcr.amount = ($1 ->> 'amount')::float
                  else true end
          and case
                  when ($1 ->> 'session_id')::int is not null then pcr.session_id = ($1 ->> 'session_id')::int
                  else true end;
end;
$$ language plpgsql immutable
                    security definer;