create table if not exists unit
(
    id          int       not null generated always as identity primary key,
    name        text      not null,
    uqc         text      not null,
    symbol      text      not null,
    precision   smallint  not null,
    conversions jsonb,
    created_at  timestamp not null default current_timestamp,
    updated_at  timestamp not null default current_timestamp
);
--##
create trigger sync_unit_updated_at
    before update
    on unit
    for each row
execute procedure sync_updated_at();