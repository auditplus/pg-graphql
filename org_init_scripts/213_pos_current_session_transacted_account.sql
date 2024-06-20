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
create function pos_session_breakup_summary(counter_id int, ses_id int) returns jsonb as
$$
begin
    return (with a as
                     (select account_id,
                             min(account_name) as account_name,
                             sum(credit)       as credit,
                             sum(debit)        as debit,
                             sum(amount)       as amount
                      from pos_counter_transaction_breakup
                      where pos_counter_id = $1
                        and session_id = $2
                      group by account_id)
            select jsonb_agg(jsonb_build_object('account_id', a.account_id, 'account_name', a.account_name, 'credit',
                                                a.credit, 'debit', a.debit, 'amount', a.amount))
            from a);
end;
$$ language plpgsql immutable
                    security definer;