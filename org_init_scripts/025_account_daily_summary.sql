create table if not exists account_daily_summary
(
    date               date                not null,
    account_id         int              not null,
    credit             float               not null,
    debit              float               not null,
    account_name       text                not null,
    base_account_types text[] not null,
    branch_id          int              not null,
    branch_name        text                not null,
    primary key (account_id, branch_id, date)
);