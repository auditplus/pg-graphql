create table if not exists bank_txn
(
    id                  uuid                not null primary key,
    sno                 smallint            not null,
    ac_txn_id           uuid                not null,
    date                date                not null,
    bank_date           date,
    inst_date           date,
    inst_no             text,
    in_favour_of        text,
    is_memo             boolean                      default false,
    amount              float               not null default 0.0,
    credit              float               not null generated always as (case when amount < 0 then abs(amount) else 0 end) stored,
    debit               float               not null generated always as (case when amount > 0 then amount else 0 end) stored,
    account_id          int                 not null,
    account_name        text                not null,
    base_account_types  text[]              not null,
    alt_account_id      int,
    alt_account_name    text,
    particulars         text,
    bank_beneficiary_id int,
    branch_id           int                 not null,
    branch_name         text                not null,
    voucher_id          int                 not null,
    voucher_no          text                not null,
    txn_type            text                not null,
    base_voucher_type   text                not null,
    constraint txn_type_invalid check (check_bank_txn_type(txn_type)),
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type)),
    constraint base_account_types_invalid check (check_base_account_types(base_account_types))
);
--##
create view vw_bank_txn_condensed
as
select a.id,
       a.sno,
       a.ac_txn_id,
       a.amount,
       a.account_id,
       a.account_name,
       a.inst_no,
       a.inst_date,
       a.txn_type
from bank_txn a
order by a.sno;