create domain pos_mode as text
    check (value in ('CASHIER', 'BILLING', 'NORMAL'));
--##
create table if not exists pos_server
(
    id           int       not null generated always as identity primary key,
    name         text      not null unique,
    branch_id    int    not null,
    mode         pos_mode  not null,
    registration json,
    is_active    boolean   not null default true,
    created_at   timestamp not null default current_timestamp,
    updated_at   timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_pos_server_updated_at
    before update
    on pos_server
    for each row
execute procedure sync_updated_at();