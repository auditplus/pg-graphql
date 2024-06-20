create function pos_current_session_transacted_accounts(counter_id int) returns jsonb as
$$
begin
    return (with a as (select distinct (account_id) as acc_id
                       from pos_counter_transaction_breakup
                       where session_id is null
                         and pos_counter_id = $1)
            select jsonb_agg(jsonb_build_object('account_id', a.acc_id, 'account_name', b.name))
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