create table if not exists pos_counter_transaction
(
    voucher_id        int                   not null primary key,
    pos_counter_id    int                   not null,
    date              date                  not null,
    branch_id         int                   not null,
    branch_name       text                  not null,
    bill_amount       float                 not null,
    particulars       text                  not null,
    voucher_no        text                  not null,
    voucher_type_id   int                   not null,
    base_voucher_type typ_base_voucher_type not null,
    voucher_mode      typ_voucher_mode      not null,
    session_id        int,
    settlement_id     int
);