create function pos_settlement_breakup_summary(settlement_id int)
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
        where a.settlement_id = $1
        group by a.account_id;
end;
$$ language plpgsql immutable
                    security definer;
--##
create function pos_settlement_transaction_summary(settlement_id int)
    returns table
            (
                base_voucher_type text,
                particulars       text,
                from_date         date,
                to_date           date,
                voucher_count     bigint,
                bill_amount       float
            )
as
$$
begin
    return query
        select a.base_voucher_type::text,
               a.particulars,
               min(a.date),
               max(a.date),
               count(a.voucher_id),
               round(sum(a.bill_amount)::numeric, 2)::float
        from pos_counter_transaction a
        where a.settlement_id = $1
        group by a.base_voucher_type, a.particulars;
end;
$$ language plpgsql immutable
                    security definer;