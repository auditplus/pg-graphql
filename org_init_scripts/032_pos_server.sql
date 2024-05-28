create type typ_pos_mode as enum ('CASHIER', 'BILLING', 'NORMAL');
--##
create table if not exists pos_server
(
    id           int          not null generated always as identity primary key,
    name         text         not null unique,
    branch       int          not null,
    mode         typ_pos_mode not null,
    registration json,
    is_active    boolean      not null default true,
    created_at   timestamp    not null default current_timestamp,
    updated_at   timestamp    not null default current_timestamp
);
--##
create trigger sync_pos_server_updated_at
    before update
    on pos_server
    for each row
execute procedure sync_updated_at();