create table if not exists pos_counter_transaction
(
    voucher_id        bigint            not null primary key,
    pos_counter_id    bigint            not null,
    date              date              not null,
    branch_id         bigint            not null,
    branch_name       text              not null,
    bill_amount       float             not null,
    particulars       text              not null,
    voucher_no        text              not null,
    voucher_type_id   bigint            not null,
    base_voucher_type base_voucher_type not null,
    voucher_mode      voucher_mode      not null,
    session_id        bigint,
    settlement_id     bigint
);