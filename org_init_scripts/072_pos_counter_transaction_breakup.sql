create table if not exists pos_counter_transaction_breakup
(
    voucher_id     int   not null,
    account_id     int   not null,
    account_name   text  not null,
    pos_counter_id int   not null,
    credit         float not null default 0,
    debit          float not null default 0,
    amount         float not null generated always as (debit - credit) stored,
    session_id     int,
    settlement_id  int,
    primary key (voucher_id, account_id)
);
--##
create function apply_pos_counter_txn(voucher, json)
    returns bool as
$$
declare
    acc   account;
    item  pos_counter_transaction_breakup;
    items pos_counter_transaction_breakup[] := (select array_agg(x)
                                                from jsonb_populate_recordset(
                                                             null::pos_counter_transaction_breakup,
                                                             ($2 ->> 'breakup')::jsonb) as x);
begin
    insert into pos_counter_transaction (voucher_id, pos_counter_id, date, branch_id, branch_name, bill_amount,
                                         voucher_no, voucher_type_id, base_voucher_type, particulars)
    values ($1.id, $1.pos_counter_id, $1.date, $1.branch_id, $1.branch_name, ($2 ->> 'amount')::float, $1.voucher_no,
            $1.voucher_type_id, $1.base_voucher_type, ($2 ->> 'particulars')::text);
    foreach item in array items
        loop
            select * into acc from account where id = item.account_id;
            insert into pos_counter_transaction_breakup (voucher_id, account_id, account_name, credit, debit, pos_counter_id)
            values ($1.id, acc.id, acc.name, item.credit, item.debit, $1.pos_counter_id);
        end loop;
    return true;
end;
$$ language plpgsql security definer;
--##
create function update_pos_counter_txn(voucher, json)
    returns bool as
$$
declare
    v_session_id int;
    acc          account;
    item         pos_counter_transaction_breakup;
    items        pos_counter_transaction_breakup[] := (select array_agg(x)
                                                       from jsonb_populate_recordset(
                                                                    null::pos_counter_transaction_breakup,
                                                                    ($2 ->> 'breakup')::jsonb) as x);
begin
    update pos_counter_transaction
    set bill_amount = ($2 ->> 'amount')::float,
        date        = $1.date,
        particulars = ($2 ->> 'particulars')::text
    where voucher_id = $1.id
      and settlement_id is null
    returning session_id into v_session_id;
    if FOUND then
        delete from pos_counter_transaction_breakup where voucher_id = $1.id;
        foreach item in array items
            loop
                select * into acc from account where id = item.account_id;
                insert into pos_counter_transaction_breakup (voucher_id, account_id, account_name, credit, debit,
                                                             pos_counter_id, session_id)
                values ($1.id, acc.id, acc.name, item.credit, item.debit, $1.pos_counter_id, v_session_id);
            end loop;
    end if;
    return true;
end;
$$ language plpgsql security definer;