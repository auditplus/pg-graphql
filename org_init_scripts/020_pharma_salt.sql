create type typ_drug_category as enum ('SCHEDULE_H', 'SCHEDULE_H1', 'NARCOTICS');
--##
create table if not exists pharma_salt
(
    id            int       not null generated always as identity primary key,
    name          text      not null,
    drug_category typ_drug_category,
    created_at    timestamp not null default current_timestamp,
    updated_at    timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_pharma_salt_updated_at
    before update
    on pharma_salt
    for each row
execute procedure sync_updated_at();