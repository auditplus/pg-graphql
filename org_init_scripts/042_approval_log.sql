create table if not exists approval_log
(
    member_id         bigint            not null,
    member_name       text              not null,
    voucher_id        bigint            not null,
    base_voucher_type base_voucher_type not null,
    voucher_type_id   bigint            not null,
    voucher_no        text              not null,
    approval_state    smallint          not null,
    approved_at       timestamp         not null default current_timestamp,
    description       text,
    primary key (member_id, voucher_id, base_voucher_type, approval_state)
);