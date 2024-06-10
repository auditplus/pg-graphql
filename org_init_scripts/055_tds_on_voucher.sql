create table if not exists tds_on_voucher
(
    id                       uuid                  not null primary key,
    date                     date                  not null,
    eff_date                 date                  not null,
    party_account_id         int                   not null,
    party_name               text                  not null,
    tds_account_id           int                   not null,
    tds_nature_of_payment_id int                   not null,
    tds_deductee_type_id     text                  not null,
    branch_id                int                   not null,
    branch_name              text                  not null,
    amount                   float                 not null,
    tds_amount               float                 not null,
    tds_ratio                float                 not null,
    base_voucher_type        typ_base_voucher_type not null,
    voucher_no               text                  not null,
    tds_section              text                  not null,
    voucher_id               int                   not null,
    pan_no                   text,
    ref_no                   text,
    constraint pan_no_invalid check (pan_no ~ '^[a-zA-Z]{5}[0-9]{4}[a-zA-Z]$')
);