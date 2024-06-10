create table if not exists bank_beneficiary
(
    id                  int       not null generated always as identity primary key,
    account_no          text      not null,
    bank_name           text,
    branch_name         text,
    ifs_code            text,
    account_type        text,
    account_holder_name text,
    created_at          timestamp not null default current_timestamp,
    updated_at          timestamp not null default current_timestamp,
    constraint account_no_min_length check (char_length(trim(account_no)) > 0)
);
--##
create trigger sync_bank_beneficiary_updated_at
    before update
    on bank_beneficiary
    for each row
execute procedure sync_updated_at();