create type typ_bank_txn_type as enum ('RTGS', 'CHEQUE', 'NEFT', 'CASH', 'ATM', 'CARD', 'E_FUND_TRANSFER', 'OTHERS');
--##
create table if not exists bank_txn
(
    id                  uuid                  not null primary key,
    ac_txn_id           uuid                  not null,
    date                date                  not null,
    bank_date           date,
    inst_date           date,
    inst_no             text,
    in_favour_of        text,
    is_memo             boolean                        default false,
    amount              float                 not null default 0.0,
    credit              float                 not null generated always as (case when amount < 0 then abs(amount) else 0 end) stored,
    debit               float                 not null generated always as (case when amount > 0 then amount else 0 end) stored,
    account_id          int                   not null,
    account_name        text                  not null,
    base_account_types  text[]                not null,
    alt_account_id      int,
    alt_account_name    text,
    particulars         text,
    bank_beneficiary_id int,
    branch_id           int                   not null,
    branch_name         text                  not null,
    voucher_id          int                   not null,
    voucher_no          text                  not null,
    txn_type            typ_bank_txn_type     not null,
    base_voucher_type   typ_base_voucher_type not null
);