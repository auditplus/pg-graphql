create table if not exists permission
(
    id   text not null primary key,
    name text not null,
    uri  text not null,
    tag  text not null,
    req  text[]
);