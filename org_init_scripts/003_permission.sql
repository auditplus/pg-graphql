-- create table if not exists permission
-- (
--     id   text not null primary key,
--     name text not null,
--     uri  text not null,
--     tag  text not null,
--     req  text[]
-- );
--##
create table if not exists permission
(
    id          int  not null generated always as identity primary key,
    name        text not null,
    resource    text not null,
    action      text not null,
    fields      text[]
);