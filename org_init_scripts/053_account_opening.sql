create table if not exists account_opening
(
    account_id       int   not null,
    branch_id        int   not null,
    credit           float not null default 0,
    debit            float not null default 0,
    bill_allocations jsonb,
    primary key (account_id, branch_id)
);
--##
create function set_account_opening(acc_open json)
    returns boolean as
$$
declare
    acc_op     account_opening := (select json_populate_record(
                                                  null::account_opening,
                                                  $1));
    op_date    date            := (select book_begin - 1
                                   from organization
                                   limit 1);
    acc        account;
    agnt       account;
    br         branch;
    old_ba     jsonb;
    j          json;
    p_id       uuid;
    ac_txn_id  uuid;
    ex_ids     uuid[];
    new_ids    uuid[];
    missed_ids uuid[];
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
    select bill_allocations
    into old_ba
    from account_opening
    where account_id = acc_op.account_id
      and branch_id = acc_op.branch_id;
    select array_agg(x ->> 'id')::uuid[] into ex_ids from jsonb_array_elements(old_ba::jsonb) x;
    select array_agg(x ->> 'id')::uuid[] into new_ids from jsonb_array_elements(acc_op.bill_allocations::jsonb) x;
    select array_agg(item)
    into missed_ids
    from (select *
          from unnest(ex_ids) item
          except
          select *
          from unnest(new_ids));
    delete from bill_allocation where id = any (missed_ids);

    update ac_txn
    set credit = acc_op.credit,
        debit  = acc_op.debit
    where account_id = acc_op.account_id
      and branch_id = acc_op.branch_id
      and is_opening = true
    returning id into ac_txn_id;
    if not FOUND then
        insert into ac_txn (id, date, eff_date, account_id, account_name, account_type_id, branch_id, branch_name,
                            is_opening)
        values (gen_random_uuid(), op_date, op_date, acc_op.account_id, acc.name, acc.account_type_id, acc_op.branch_id,
                br.name, true)
        returning id into ac_txn_id;
    end if;
    if acc.account_type_id in ('SUNDRY_CREDITOR', 'SUNDRY_DEBTOR', 'CURRENT_LIABILITY') then
        for j in select jsonb_array_elements(acc_op.bill_allocations)
            loop
                if (j ->> 'ref_type')::typ_pending_ref_type = 'NEW' then
                    p_id = coalesce((j ->> 'pending')::uuid, gen_random_uuid());
                end if;
                if (j ->> 'ref_type')::typ_pending_ref_type = 'ADJ' then
                    raise exception 'ADJ ref not allowed in opening';
                end if;
                if (j ->> 'ref_type')::typ_pending_ref_type = 'ON_ACC' and (j ->> 'pending')::uuid is not null then
                    raise exception 'ON_ACC ref pending id not allowed';
                end if;
                insert into bill_allocation (id, ac_txn_id, date, eff_date, account_id, branch_id, amount, pending,
                                             ref_type, ref_no, account_name, account_type_id, branch_name, agent_id,
                                             agent_name)
                values ((j ->> 'id')::uuid, ac_txn_id, op_date, coalesce((j ->> 'eff_date')::date, op_date),
                        acc_op.account_id, acc_op.branch_id, (j ->> 'amount')::float, p_id,
                        (j ->> 'ref_type')::typ_pending_ref_type, (j ->> 'ref_no')::text, acc.name, acc.account_type_id,
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
        where account_id = acc_op.account_id and branch_id = acc_op.branch_id and voucher_id is null;
    end if;

    insert into account_opening (account_id, branch_id, credit, debit, bill_allocations)
    values (acc_op.account_id, acc_op.branch_id, acc_op.credit, acc_op.debit, acc_op.bill_allocations)
    on conflict (account_id,branch_id) do update
        set credit           = excluded.credit,
            debit            = excluded.debit,
            bill_allocations = excluded.bill_allocations;
    return true;
end;
$$ language plpgsql security definer;