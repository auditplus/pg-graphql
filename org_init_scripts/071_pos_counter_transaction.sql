create table if not exists pos_counter_transaction
(
    voucher_id        int   not null primary key,
    pos_counter_id    int   not null,
    date              date  not null,
    branch_id         int   not null,
    branch_name       text  not null,
    bill_amount       float not null,
    particulars       text  not null,
    voucher_no        text  not null,
    voucher_type_id   int   not null,
    base_voucher_type text  not null,
    voucher_mode      text  not null,
    session_id        int,
    settlement_id     int,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type)),
    constraint voucher_mode_invalid check (check_voucher_mode(voucher_mode))
);