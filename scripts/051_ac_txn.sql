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
