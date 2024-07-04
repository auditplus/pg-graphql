create table if not exists voucher_numbering
(
    branch_id       bigint not null,
    f_year_id       bigint not null,
    voucher_type_id bigint not null,
    seq             bigint not null,
    primary key (branch_id, f_year_id, voucher_type_id)
);