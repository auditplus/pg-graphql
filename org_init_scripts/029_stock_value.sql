create table if not exists stock_value
(
    date      date not null,
    branch_id int  not null,
    value     float,
    primary key (date, branch_id)
);
