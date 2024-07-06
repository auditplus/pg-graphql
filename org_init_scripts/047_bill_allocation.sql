create table if not exists bill_allocation
(
    id                 uuid             not null primary key,
    ac_txn_id          uuid             not null,
    date               date             not null,
    eff_date           date             not null,
    is_memo            boolean          not null default false,
    account_id         int           not null,
    account_name       text             not null,
    base_account_types text[]           not null,
    agent_id           int,
    agent_name         text,
    branch_id          int           not null,
    branch_name        text             not null,
    amount             float            not null,
    pending            uuid,
    ref_type           text not null,
    is_approved        boolean,
    base_voucher_type  text,
    voucher_mode       text,
    ref_no             text,
    voucher_no         text,
    voucher_id         int,
    updated_at         timestamp        not null default current_timestamp,
    constraint amount_ne_zero check (amount <> 0),
    constraint ref_type_invalid check (check_pending_ref_type(ref_type)),
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type)),
    constraint voucher_mode_invalid check (check_voucher_mode(voucher_mode))
    constraint base_account_types_invalid check (check_base_account_types(base_account_types))
);
--##
create trigger sync_bill_allocation_updated_at
    before update
    on bill_allocation
    for each row
execute procedure sync_updated_at();
--##
create function del_on_bill_allc()
    returns trigger as
$$
begin
    if old.ref_type = 'NEW' then
        update bill_allocation
        set ref_type = 'NEW',
            pending  = gen_random_uuid()
        where pending = old.pending
          and ref_type = 'ADJ';
    end if;
    return old;
end;
$$ language plpgsql security definer;
--##
create trigger del_bill_allc
    after delete
    on bill_allocation
    for each row
execute procedure del_on_bill_allc();