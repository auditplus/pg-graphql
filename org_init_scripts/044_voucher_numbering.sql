create table if not exists voucher_numbering
(
    branch_id       int not null,
    f_year_id       int not null,
    voucher_type_id int not null,
    seq             int not null,
    primary key (branch_id, f_year_id, voucher_type_id)
);