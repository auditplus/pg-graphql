create table if not exists permission
(
    id          text not null primary key,
    fields      text[]
);