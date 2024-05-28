create table if not exists desktop_client
(
    id           int       not null generated always as identity primary key,
    name         text      not null,
    access       boolean,
    branch       int[],
    registration json,
    created_at   timestamp not null default current_timestamp,
    updated_at   timestamp not null default current_timestamp
);
--##
create trigger sync_desktop_client_updated_at
    before update
    on desktop_client
    for each row
execute procedure sync_updated_at();