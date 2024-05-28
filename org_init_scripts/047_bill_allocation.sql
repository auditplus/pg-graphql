create type typ_pending_ref_type as enum ('NEW', 'ADJ', 'ON_ACC');
--##
create table if not exists bill_allocation
(
    id                     uuid                 not null primary key,
    ac_txn                 uuid                 not null,
    date                   date                 not null,
    eff_date               date                 not null,
    is_memo                boolean              not null default false,
    account                int                  not null,
    account_name           text                 not null,
    account_type           text                 not null,
    agent                  int,
    agent_name             text,
    branch                 int                  not null,
    branch_name            text                 not null,
    amount                 float                not null,
    pending                uuid,
    ref_type               typ_pending_ref_type not null,
    is_approved            boolean,
    base_voucher_type      typ_base_voucher_type,
    voucher_mode           typ_voucher_mode,
    ref_no                 text,
    voucher_no             text,
    voucher                int,
    updated_at             timestamp            not null default current_timestamp
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
end ;
$$ language plpgsql;
--##
create trigger del_bill_allc
    after delete
    on bill_allocation
    for each row
execute procedure del_on_bill_allc();