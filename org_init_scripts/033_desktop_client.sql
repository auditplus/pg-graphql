create table if not exists desktop_client
(
    id           int       not null generated always as identity primary key,
    name         text      not null
        constraint desktop_client_name_min_length check (char_length(trim(name)) > 0),
    access       boolean,
    branches     int[],
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
--##
create or replace function branches(desktop_client)
    returns setof branch as
$$
begin
    return query
    select * from branch where id = any($1.branches);
end
$$ language plpgsql immutable;