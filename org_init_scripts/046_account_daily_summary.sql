create table if not exists account_daily_summary
(
    date         date  not null,
    account      int   not null,
    credit       float not null,
    debit        float not null,
    account_name text  not null,
    account_type text  not null,
    branch       int   not null,
    branch_name  text  not null,
    primary key (account, branch, date)
);