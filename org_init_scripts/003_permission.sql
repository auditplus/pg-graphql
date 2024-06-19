create table if not exists permission
(
    id          int  not null generated always as identity primary key,
    name        text not null,
    resource    text not null,
    action      text not null,
    fields      text[],
    unique (resource, action)
);