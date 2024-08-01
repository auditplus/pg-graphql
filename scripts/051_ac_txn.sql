create table if not exists ac_txn
(
    id                 uuid                not null primary key,
    sno                smallint            not null,
    date               date                not null,
    eff_date           date,
    is_opening         boolean                      default false,
    is_memo            boolean                      default false,
    is_default         boolean,
    account_id         int                 not null,
    credit             float               not null default 0.0,
    debit              float               not null default 0.0,
    account_name       text                not null,
    base_account_types text[]              not null,
    branch_id          int                 not null,
    branch_name        text                not null,
    alt_account_id     int,
    alt_account_name   text,
    ref_no             text,
    inst_no            text,
    voucher_id         int,
    voucher_no         text,
    voucher_prefix     text,
    voucher_fy         int,
    voucher_seq        int,
    voucher_type_id    int,
    base_voucher_type  text,
    voucher_mode       text,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type)),
    constraint voucher_mode_invalid check (check_voucher_mode(voucher_mode)),
    constraint base_account_types_invalid check (check_base_account_types(base_account_types))
);
--##
create view vw_ac_txn
as
select a.id,
       a.credit,
       a.debit,
       a.is_default,
       a.sno,
       a.voucher_id,
       (select row_to_json(vw_account_condensed.*) from vw_account_condensed where id = a.account_id)
                                                                                      as account,
       (select jsonb_agg(row_to_json(b.*)) from vw_acc_cat_txn b where b.ac_txn_id = a.id)
                                                                                      as category_allocations,
       (select jsonb_agg(row_to_json(c.*)) from vw_bill_allocation_condensed c where c.ac_txn_id = a.id)
                                                                                      as bill_allocations,
       (select jsonb_agg(row_to_json(d.*)) from vw_bank_txn_condensed d where d.ac_txn_id = a.id)
                                                                                      as bank_allocations,
       (select row_to_json(e.*) from vw_gst_txn_condensed e where e.ac_txn_id = a.id) as gst_info
from ac_txn a
order by a.sno;
--##
create view vw_account_opening as
select a.account_id,
       a.branch_id,
       a.credit,
       a.debit,
       (select jsonb_agg(row_to_json(c.*)) from vw_bill_allocation_condensed c where c.ac_txn_id = a.id)
                                                                                       as bill_allocations,
       (select row_to_json(c.*) from vw_branch_condensed c where c.id = a.branch_id)   as branch,
       (select row_to_json(d.*) from vw_account_condensed d where d.id = a.account_id) as account
from ac_txn a
where a.is_opening;
--##
create function get_account_opening(account_id int, branch_id int)
    returns setof vw_account_opening
as
$$
begin
    return query select a.* from vw_account_opening a where (a.account_id, a.branch_id) = ($1, $2);
end
$$ language plpgsql security definer;
--##
create function tgf_insert_on_ac_txn()
    returns trigger as
$$
begin
    if new.is_memo = false then
        insert into account_daily_summary
        (date, branch_id, branch_name, account_id, account_name, base_account_types, credit, debit)
        values (new.date, new.branch_id, new.branch_name, new.account_id, new.account_name, new.base_account_types,
                new.credit, new.debit)
        on conflict (branch_id, date, account_id) do update
            set account_name = excluded.account_name,
                branch_name  = excluded.branch_name,
                credit       = account_daily_summary.credit + excluded.credit,
                debit        = account_daily_summary.debit + excluded.debit;
    end if;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger tg_create_ac_txn
    after insert
    on ac_txn
    for each row
execute procedure tgf_insert_on_ac_txn();
--##
create function tgf_update_on_ac_txn()
    returns trigger as
$$
begin
    if new.is_memo = false then
        if new.date = old.date then
            insert into account_daily_summary
            (date, branch_id, branch_name, account_id, account_name, base_account_types, credit, debit)
            values (new.date, new.branch_id, new.branch_name, new.account_id, new.account_name, new.base_account_types,
                    new.credit, new.debit)
            on conflict (branch_id, date, account_id)
                do update
                set account_name = excluded.account_name,
                    branch_name  = excluded.branch_name,
                    credit       = account_daily_summary.credit + (new.credit - old.credit),
                    debit        = account_daily_summary.debit + (new.debit - old.debit);
        else
            insert into account_daily_summary
            (date, branch_id, branch_name, account_id, account_name, base_account_types, credit, debit)
            values (new.date, new.branch_id, new.branch_name, new.account_id, new.account_name, new.base_account_types,
                    new.credit, new.debit)
            on conflict (branch_id, date, account_id)
                do update
                set account_name = excluded.account_name,
                    branch_name  = excluded.branch_name,
                    credit       = account_daily_summary.credit + excluded.credit,
                    debit        = account_daily_summary.debit + excluded.debit;
            insert into account_daily_summary
            (date, branch_id, branch_name, account_id, account_name, base_account_types, credit, debit)
            values (old.date, new.branch_id, new.branch_name, new.account_id, new.account_name, new.base_account_types,
                    new.credit, new.debit)
            on conflict (branch_id, date, account_id)
                do update
                set account_name = excluded.account_name,
                    branch_name  = excluded.branch_name,
                    credit       = account_daily_summary.credit - excluded.credit,
                    debit        = account_daily_summary.debit - excluded.debit;
        end if;
    end if;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger tg_update_ac_txn
    after update
    on ac_txn
    for each row
execute procedure tgf_update_on_ac_txn();
--##
create function tgf_delete_on_ac_txn()
    returns trigger as
$$
begin
    if old.is_memo = false then
        insert into account_daily_summary
        (date, branch_id, branch_name, account_id, account_name, base_account_types, credit, debit)
        values (old.date, old.branch_id, old.branch_name, old.account_id, old.account_name, old.base_account_types,
                old.credit, old.debit)
        on conflict (branch_id, date, account_id)
            do update
            set account_name = excluded.account_name,
                branch_name  = excluded.branch_name,
                credit       = account_daily_summary.credit - excluded.credit,
                debit        = account_daily_summary.debit - excluded.debit;
    end if;
    return old;
end
$$ language plpgsql security definer;
--##
create trigger tg_delete_ac_txn
    before delete
    on ac_txn
    for each row
execute procedure tgf_delete_on_ac_txn();
