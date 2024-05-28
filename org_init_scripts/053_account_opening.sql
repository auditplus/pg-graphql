create table if not exists account_opening
(
    account          int   not null,
    branch           int   not null,
    credit           float not null default 0,
    debit            float not null default 0,
    bill_allocations jsonb,
    primary key (account, branch)
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
        delete from bill_allocation where account = acc_op.account and branch = acc_op.branch and voucher is null;
        delete
        from ac_txn
        where ac_txn.branch = acc_op.branch
          and ac_txn.account = acc_op.account
          and is_opening = true;
        delete from account_opening where account = acc_op.account and branch = acc_op.branch;
        return false;
    end if;

    select * into acc from account where id = acc_op.account;
    select * into agnt from account where id = acc.agent;
    select * into br from branch where id = acc_op.branch;
    select bill_allocations into old_ba from account_opening where account = acc_op.account and branch = acc_op.branch;
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
    where account = acc_op.account
      and branch = acc_op.branch
      and is_opening = true
    returning id into ac_txn_id;
    if not FOUND then
        insert into ac_txn (id, date, eff_date, account, account_name, account_type, branch, branch_name, is_opening)
        values (gen_random_uuid(), op_date, op_date, acc_op.account, acc.name, acc.account_type, acc_op.branch, br.name,
                true)
        returning id into ac_txn_id;
    end if;
    if acc.account_type in ('SUNDRY_CREDITOR', 'SUNDRY_DEBTOR', 'CURRENT_LIABILITY') then
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
                insert into bill_allocation (id, ac_txn, date, eff_date, account, branch, amount, pending,
                                             ref_type, ref_no, account_name, account_type, branch_name,
                                             agent, agent_name)
                values ((j ->> 'id')::uuid, ac_txn_id, op_date, coalesce((j ->> 'eff_date')::date, op_date),
                        acc_op.account, acc_op.branch, (j ->> 'amount')::float, p_id,
                        (j ->> 'ref_type')::typ_pending_ref_type, (j ->> 'ref_no')::text, acc.name, acc.account_type,
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
        delete from bill_allocation where account = acc_op.account and branch = acc_op.branch and voucher is null;
    end if;

    insert into account_opening (account, branch, credit, debit, bill_allocations)
    values (acc_op.account, acc_op.branch, acc_op.credit, acc_op.debit, acc_op.bill_allocations)
    on conflict (account,branch) do update
        set credit           = excluded.credit,
            debit            = excluded.debit,
            bill_allocations = excluded.bill_allocations;
    return true;
end;
$$ language plpgsql security definer;