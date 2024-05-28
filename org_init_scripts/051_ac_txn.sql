create table if not exists ac_txn
(
    id                uuid  not null primary key,
    date              date  not null,
    eff_date          date,
    is_opening        boolean default false,
    is_memo           boolean default false,
    account           int   not null,
    credit            float not null default 0.0,
    debit             float not null default 0.0,
    account_name      text  not null,
    account_type      text  not null,
    branch            int   not null,
    branch_name       text  not null,
    alt_account       int,
    alt_account_name  text,
    ref_no            text,
    inst_no           text,
    voucher           int,
    voucher_no        text,
    voucher_prefix    text,
    voucher_fy        int,
    voucher_seq       int,
    voucher_type      int,
    base_voucher_type typ_base_voucher_type,
    voucher_mode      typ_voucher_mode
);
--##
create function insert_on_ac_txn()
    returns trigger as
$$
begin
    if new.is_memo = false then
        insert into account_daily_summary (date,
                                           branch,
                                           branch_name,
                                           account,
                                           account_name,
                                           account_type,
                                           credit,
                                           debit)
        values (new.date,
                new.branch,
                new.branch_name,
                new.account,
                new.account_name,
                new.account_type,
                new.credit,
                new.debit)
        on conflict (branch, date, account) do update
            set account_name = excluded.account_name,
                branch_name  = excluded.branch_name,
                credit       = account_daily_summary.credit + excluded.credit,
                debit        = account_daily_summary.debit + excluded.debit;
    end if;
    return new;
end;
$$ language plpgsql;
--##
create trigger create_ac_txn
    after insert
    on ac_txn
    for each row
execute procedure insert_on_ac_txn();
--##
create function update_on_ac_txn()
    returns trigger as
$$
begin
    if new.is_memo = false then
        if new.date = old.date then
            insert into account_daily_summary
            (date, branch, branch_name, account, account_name, account_type, credit, debit)
            values (new.date,
                    new.branch,
                    new.branch_name,
                    new.account,
                    new.account_name,
                    new.account_type,
                    new.credit,
                    new.debit)
            on conflict (branch, date, account)
                do update
                set account_name = excluded.account_name,
                    branch_name  = excluded.branch_name,
                    credit       = account_daily_summary.credit + (new.credit - old.credit),
                    debit        = account_daily_summary.debit + (new.debit - old.debit);
        else
            insert into account_daily_summary
            (date, branch, branch_name, account, account_name, account_type, credit, debit)
            values (new.date,
                    new.branch,
                    new.branch_name,
                    new.account,
                    new.account_name,
                    new.account_type,
                    new.credit,
                    new.debit)
            on conflict (branch, date, account)
                do update
                set account_name = excluded.account_name,
                    branch_name  = excluded.branch_name,
                    credit       = account_daily_summary.credit + excluded.credit,
                    debit        = account_daily_summary.debit + excluded.debit;
            insert into account_daily_summary (date,
                                               branch,
                                               branch_name,
                                               account,
                                               account_name,
                                               account_type,
                                               credit,
                                               debit)
            values (old.date,
                    new.branch,
                    new.branch_name,
                    new.account,
                    new.account_name,
                    new.account_type,
                    new.credit,
                    new.debit)
            on conflict (branch, date, account)
                do update
                set account_name = excluded.account_name,
                    branch_name  = excluded.branch_name,
                    credit       = account_daily_summary.credit - excluded.credit,
                    debit        = account_daily_summary.debit - excluded.debit;
        end if;
    end if;
    return new;
end;
$$ language plpgsql;
--##
create trigger update_ac_txn
    after update
    on ac_txn
    for each row
execute procedure update_on_ac_txn();
--##
create function delete_on_ac_txn()
    returns trigger as
$$
begin
    if old.is_memo = false then
        insert into account_daily_summary (date,
                                           branch,
                                           branch_name,
                                           account,
                                           account_name,
                                           account_type,
                                           credit,
                                           debit)
        values (old.date,
                old.branch,
                old.branch_name,
                old.account,
                old.account_name,
                old.account_type,
                old.credit,
                old.debit)
        on conflict (branch, date, account)
            do update
            set account_name = excluded.account_name,
                branch_name  = excluded.branch_name,
                credit       = account_daily_summary.credit - excluded.credit,
                debit        = account_daily_summary.debit - excluded.debit;
    end if;
    return old;
end
$$ language plpgsql;
--##
create trigger delete_ac_txn
    before delete
    on ac_txn
    for each row
execute procedure delete_on_ac_txn();
