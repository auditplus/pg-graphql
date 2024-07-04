create table if not exists desktop_client
(
    id           bigserial not null primary key,
    name         text      not null,
    access       boolean,
    branches     bigint[],
    registration json,
    created_at   timestamp not null default current_timestamp,
    updated_at   timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_desktop_client_updated_at
    before update
    on desktop_client
    for each row
execute procedure sync_updated_at();
