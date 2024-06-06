create table if not exists financial_year
(
    id       int  not null generated always as identity primary key,
    fy_start date not null,
    fy_end   date not null
);