create table if not exists account_type
(
    id                text    not null primary key,
    name              text    not null,
    allow_account     boolean not null default false,
    allow_sub_account boolean not null default false,
    parent_id         text references account_type,
    description       text
);