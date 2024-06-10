create table if not exists pos_counter
(
    id   int  not null generated always as identity primary key,
    name text not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_pos_counter_updated_at
    before update
    on pos_counter
    for each row
execute procedure sync_updated_at();
