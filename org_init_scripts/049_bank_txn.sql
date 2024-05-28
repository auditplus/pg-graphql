create type typ_bank_txn_type as enum ('RTGS', 'CHEQUE', 'NEFT', 'CASH', 'ATM', 'CARD', 'E_FUND_TRANSFER', 'OTHERS');
--##
create table if not exists bank_txn
(
    id                uuid                  not null primary key,
    ac_txn            uuid                  not null,
    date              date                  not null,
    bank_date         date,
    inst_date         date,
    inst_no           text,
    in_favour_of      text,
    is_memo           boolean default false,
    credit            float   default 0,
    debit             float   default 0,
    account           int                   not null,
    account_name      text                  not null,
    account_type      text                  not null,
    alt_account       int,
    alt_account_name  text,
    particulars       text,
    bank_beneficiary  int,
    branch            int                   not null,
    branch_name       text                  not null,
    voucher           int                   not null,
    voucher_no        text                  not null,
    txn_type          typ_bank_txn_type     not null,
    base_voucher_type typ_base_voucher_type not null
);