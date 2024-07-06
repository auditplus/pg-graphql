create table if not exists approval_log
(
    member_id         int               not null,
    member_name       text              not null,
    voucher_id        int               not null,
    base_voucher_type text              not null,
    voucher_type_id   int               not null,
    voucher_no        text              not null,
    approval_state    smallint          not null,
    approved_at       timestamp         not null default current_timestamp,
    description       text,
    primary key (member_id, voucher_id, base_voucher_type, approval_state),
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);