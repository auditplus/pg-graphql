create table if not exists pos_counter_transaction_breakup
(
    voucher_id    int   not null,
    account_id    int   not null,
    account_name  text  not null,
    credit        float not null default 0,
    debit         float not null default 0,
    primary key (voucher_id, account_id)
);