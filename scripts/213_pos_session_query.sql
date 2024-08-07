create function pos_current_session_transacted_accounts(counter_code text)
    returns table
            (
                account_id         int,
                account_name       text,
                base_account_types text[]
            )
as
$$
begin
    return query
        (with a as (select pt.account_id
                    from pos_counter_transaction_breakup pt
                    where session_id is null
                      and pos_counter_code = $1
                    group by pt.account_id
                    having sum(amount) > 0)
         select b.id, b.name, b.base_account_types
         from a
                  left join account b on b.id = a.account_id);
end;
$$ language plpgsql immutable
                    security definer;
--##
create function pos_session_breakup_summary(session_ids int[])
    returns table
            (
                account_id   int,
                account_name text,
                credit       float,
                debit        float,
                amount       float
            )
as
$$
begin
    return query
        select a.account_id,
               min(a.account_name),
               round(sum(a.credit)::numeric, 2)::float,
               round(sum(a.debit)::numeric, 2)::float,
               round(sum(a.amount)::numeric, 2)::float
        from pos_counter_transaction_breakup a
        where a.session_id = any ($1)
        group by a.account_id
        having sum(a.amount) > 0;
end;
$$ language plpgsql immutable
                    security definer;
--##
create function pos_session_transaction_summary(session_ids int[])
    returns table
            (
                base_voucher_type text,
                particulars       text,
                from_date         date,
                to_date           date,
                voucher_count     int,
                bill_amount       float
            )
as
$$
begin
    return query
        select a.base_voucher_type::text,
               a.particulars,
               min(a.date)         as from_date,
               max(a.date)         as to_date,
               count(a.voucher_id) as voucher_count,
               sum(a.bill_amount)  as bill_amount
        from pos_counter_transaction a
        where a.session_id = any ($1)
        group by a.base_voucher_type, a.particulars;
end;
$$ language plpgsql immutable
                    security definer;