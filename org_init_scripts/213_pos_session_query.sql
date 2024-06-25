create function pos_current_session_transacted_accounts(counter_id int)
    returns table
            (
                account_id         int,
                account_name       text,
                base_account_types text[]
            )
as
$$
begin
    return query (with a as (select distinct (pt.account_id) as acc_id
                             from pos_counter_transaction_breakup pt
                             where session_id is null
                               and pos_counter_id = $1)
                  select b.id, b.name, b.base_account_types
                  from a
                           left join account b on b.id = a.acc_id);
end;
$$ language plpgsql immutable
                    security definer;
--##
create function pos_session_breakup_summary(session_ids int[])
    returns jsonb as
$$
begin
    return (with b as
                     (select a.account_id,
                             min(a.account_name) as account_name,
                             sum(a.credit)       as credit,
                             sum(a.debit)        as debit,
                             sum(a.amount)       as amount
                      from pos_counter_transaction_breakup a
                      where a.session_id = any ($1)
                      group by a.account_id)
            select jsonb_agg(jsonb_build_object('account_id', b.account_id, 'account_name', b.account_name, 'credit',
                                                b.credit, 'debit', b.debit, 'amount', b.amount))
            from b);
end;
$$ language plpgsql immutable
                    security definer;
--##
create function pos_session_transaction_summary(session_ids int[])
    returns jsonb as
$$
begin
    return (with b as
                     (select a.base_voucher_type,
                             min(a.date)         as from_date,
                             max(a.date)         as to_date,
                             count(a.voucher_id) as voucher_count,
                             sum(a.bill_amount)  as bill_amount
                      from pos_counter_transaction a
                      where a.session_id = any ($1)
                      group by a.base_voucher_type)
            select jsonb_agg(jsonb_build_object('base_voucher_type', b.base_voucher_type, 'from_date', b.from_date,
                                                'to_date', b.to_date, 'bill_amount', b.bill_amount, 'voucher_count',
                                                b.voucher_count))
            from b);
end;
$$ language plpgsql immutable
                    security definer;