create table if not exists country
(
    id      text not null primary key,
    name    text not null,
    country text references country
);