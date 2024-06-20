create function pos_settlement_breakup_summary(settlement_id int)
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
                      where a.settlement_id = $1
                      group by a.account_id)
            select jsonb_agg(jsonb_build_object('account_id', b.account_id, 'account_name', b.account_name, 'credit',
                                                b.credit, 'debit', b.debit, 'amount', b.amount))
            from b);
end;
$$ language plpgsql immutable
                    security definer;
--##
create function pos_settlement_transaction_summary(settlement_id int)
    returns jsonb as
$$
begin
    return (with b as
                     (select a.base_voucher_type,
                             min(a.date)        as from_date,
                             max(a.date)        as to_date,
                             sum(a.bill_amount) as bill_amount
                      from pos_counter_transaction a
                      where a.settlement_id = $1
                      group by a.base_voucher_type)
            select jsonb_agg(jsonb_build_object('base_voucher_type', b.base_voucher_type, 'from_date', b.from_date,
                                                'to_date', b.to_date, 'bill_amount', b.bill_amount))
            from b);
end;
$$ language plpgsql immutable
                    security definer;