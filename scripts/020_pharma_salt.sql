create table if not exists pharma_salt
(
    id            int       not null generated always as identity primary key,
    name          text      not null,
    drug_category text,
    created_at    timestamp not null default current_timestamp,
    updated_at    timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint drug_category_invalid check (check_drug_category(drug_category))
);
--##
create trigger sync_pharma_salt_updated_at
    before update
    on pharma_salt
    for each row
execute procedure sync_updated_at();