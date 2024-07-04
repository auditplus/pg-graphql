create table if not exists account_daily_summary
(
    date               date                not null,
    account_id         bigint              not null,
    credit             float               not null,
    debit              float               not null,
    account_name       text                not null,
    base_account_types base_account_type[] not null,
    branch_id          bigint              not null,
    branch_name        text                not null,
    primary key (account_id, branch_id, date)
);