create table if not exists voucher_numbering
(
    branch       int not null,
    f_year       int not null,
    voucher_type int not null,
    seq          int not null,
    primary key (branch, f_year, voucher_type)
);