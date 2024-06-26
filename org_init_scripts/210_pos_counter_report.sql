create view pos_counter_register
as
select row_number() over () as row_id,
       txn.voucher_id,
       txn.pos_counter_id,
       txn.branch_id,
       txn.branch_name,
       txn.date,
       txn.bill_amount,
       txn.particulars,
       txn.voucher_no,
       txn.voucher_type_id,
       txn.base_voucher_type,
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
comment on view pos_counter_register is e'@graphql({"primary_key_columns": ["row_id"],"foreign_keys": [
    {
      "local_name": "pos_counter_id",
      "local_columns": ["pos_counter_id"],
      "foreign_name": "posCounter",
      "foreign_schema": "public",
      "foreign_table": "pos_counter",
      "foreign_columns": ["id"]
    }
  ]})';
--##
create function pos_counter_summary(
    from_date date default null,
    to_date date default null,
    pos_counters int[] default null,
    accounts int[] default null,
    base_voucher_types text[] default null,
    settlement_id int default null,
    bill_amount float default null,
    amount float default null,
    session_id int default null
)
    returns json as
$$
begin
    return (select json_build_object('credit', sum(pcr.credit), 'debit', sum(pcr.debit), 'amount', sum(pcr.amount),
                                     'billAmount', sum(pcr.bill_amount)) as data
            from pos_counter_register as pcr
            where (case when ($1 is not null and $2 is not null) then pcr.date between $1 and $2 else true end)
              and (case when (array_length($3, 1) > 0) then pcr.pos_counter_id = any ($3) else true end)
              and (case when (array_length($4, 1) > 0) then pcr.account_id = any ($4) else true end)
              and (case
                       when (array_length($5, 1) > 0) then pcr.base_voucher_type = any ($5::typ_base_voucher_type[])
                       else true end)
              and (case when $6 is not null then pcr.settlement_id = $6 else true end)
              and (case when $7 is not null then pcr.bill_amount = $7 else true end)
              and (case when $8 is not null then pcr.amount = $8 else true end)
              and (case when $9 is not null then pcr.session_id = $9 else true end));
end;
$$ language plpgsql immutable
                    security definer;