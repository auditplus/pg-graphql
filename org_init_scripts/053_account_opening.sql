create table if not exists account_opening
(
    account_id int   not null,
    branch_id  int   not null,
    credit     float not null default 0,
    debit      float not null default 0,
    primary key (account_id, branch_id)
);
--##
create function set_account_opening(input_data json)
    returns boolean as
$$
declare
    acc_op      account_opening   := (select json_populate_record(
                                                     null::account_opening,
                                                     json_convert_case($1::jsonb, 'snake_case')::json));
    ba          bill_allocation;
    input_ba    bill_allocation[] := (select array_agg(x)
                                      from jsonb_populate_recordset(
                                                   null::bill_allocation,
                                                   json_convert_case(($1 ->> 'billAllocations')::jsonb, 'snake_case')) as x);
    op_date     date              := (select book_begin - 1
                                      from organization
                                      limit 1);
    acc         account;
    agnt        account;
    br          branch;
    p_id        uuid;
    v_ac_txn_id uuid;
    missed_ids  uuid[];
begin
    if acc_op.credit = 0 and acc_op.debit = 0 then
        delete
        from bill_allocation
        where account_id = acc_op.account_id
          and branch_id = acc_op.branch_id
          and voucher_id is null;
        delete
        from ac_txn
        where ac_txn.branch_id = acc_op.branch_id
          and ac_txn.account_id = acc_op.account_id
          and is_opening = true;
        delete from account_opening where account_id = acc_op.account_id and branch_id = acc_op.branch_id;
        return false;
    end if;
    select * into acc from account where id = acc_op.account_id;
    select * into agnt from account where id = acc.agent_id;
    select * into br from branch where id = acc_op.branch_id;
    update ac_txn
    set credit = acc_op.credit,
        debit  = acc_op.debit
    where account_id = acc_op.account_id
      and branch_id = acc_op.branch_id
      and is_opening = true
    returning id into v_ac_txn_id;
    if not FOUND then
        insert into ac_txn (id, date, eff_date, account_id, account_name, base_account_types, branch_id, branch_name,
                            is_opening)
        values (gen_random_uuid(), op_date, op_date, acc_op.account_id, acc.name, acc.base_account_types,
                acc_op.branch_id,
                br.name, true)
        returning id into v_ac_txn_id;
    end if;
    select array_agg(id)
    into missed_ids
    from ((select id
           from bill_allocation
           where ac_txn_id = v_ac_txn_id)
          except
          (select id
           from unnest(input_ba)));
    delete from bill_allocation where id = any (missed_ids);
    if array ['SUNDRY_CREDITOR', 'SUNDRY_DEBTOR'] && acc.base_account_types and
       array_length(input_ba, 1) <= 0 then
        raise exception 'bill_allocations required for Sundry type';
    end if;
    if array ['SUNDRY_CREDITOR', 'SUNDRY_DEBTOR'] && acc.base_account_types then
        foreach ba in array input_ba
            loop
                if ba.ref_type = 'NEW' then
                    p_id = coalesce(ba.pending, gen_random_uuid());
                end if;
                if ba.ref_type = 'ADJ' then
                    raise exception 'ADJ ref not allowed in opening';
                end if;
                if ba.ref_type = 'ON_ACC' and ba.pending is not null then
                    raise exception 'ON_ACC ref pending id not allowed';
                end if;
                insert into bill_allocation (id, ac_txn_id, date, eff_date, account_id, branch_id, amount, pending,
                                             ref_type, ref_no, account_name, base_account_types, branch_name, agent_id,
                                             agent_name)
                values (coalesce(ba.id, gen_random_uuid()), v_ac_txn_id, op_date,
                        coalesce(ba.eff_date, op_date),
                        acc_op.account_id, acc_op.branch_id, ba.amount, p_id,
                        ba.ref_type, ba.ref_no, acc.name,
                        acc.base_account_types,
                        br.name, agnt.id, agnt.name)
                on conflict (id) do update
                    set amount       = excluded.amount,
                        eff_date     = excluded.eff_date,
                        agent_name   = excluded.agent_name,
                        account_name = excluded.account_name,
                        ref_type     = excluded.ref_type,
                        branch_name  = excluded.branch_name,
                        ref_no       = excluded.ref_no;
            end loop;
    else
        delete
        from bill_allocation
        where account_id = acc_op.account_id
          and branch_id = acc_op.branch_id
          and voucher_id is null;
    end if;
    insert into account_opening (account_id, branch_id, credit, debit)
    values (acc_op.account_id, acc_op.branch_id, acc_op.credit, acc_op.debit)
    on conflict (account_id,branch_id) do update
        set credit = excluded.credit,
            debit  = excluded.debit;
    return true;
end;
$$ language plpgsql security definer;