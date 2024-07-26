create table if not exists unit
(
    id          int       not null generated always as identity primary key,
    name        text      not null,
    uqc_id      text      not null,
    symbol      text      not null,
    precision   smallint  not null,
    conversions jsonb not null default '[]'::jsonb,
    created_at  timestamp not null default current_timestamp,
    updated_at  timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint symbol_min_length check (char_length(trim(symbol)) > 0),
    constraint precision_invalid check (precision between 0 and 4)
);
--##
create trigger sync_unit_updated_at
    before update
    on unit
    for each row
execute procedure sync_updated_at();
