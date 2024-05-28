create table if not exists approval_log
(
    member            int                   not null,
    member_name       text                  not null,
    voucher           int                   not null,
    base_voucher_type typ_base_voucher_type not null,
    voucher_type      int                   not null,
    voucher_no        text                  not null,
    approval_state    smallint              not null,
    approved_at       timestamp             not null default current_timestamp,
    description       text,
    primary key (member, voucher, base_voucher_type, approval_state)
);