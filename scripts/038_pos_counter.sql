create table if not exists pos_counter
(
    code        text      not null primary key,
    name        text      not null,
    branch_id   int       not null,
    created_at  timestamp not null default current_timestamp,
    updated_at  timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint code_invalid check ((code ~ '^[A-Z0-9_]*$') and (char_length(trim(code)) > 0))
);
--##
create trigger tg_sync_pos_counter_updated_at
    before update
    on pos_counter
    for each row
execute procedure tgf_sync_updated_at();
--##
create view vw_pos_counter_condensed as
select code, name
from pos_counter;

