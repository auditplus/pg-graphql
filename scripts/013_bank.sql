create table if not exists bank
(
    id          int       not null generated always as identity primary key,
    name        text      not null,
    short_name  text      not null,
    branch_name text,
    bsr_code    text,
    ifs_code    text,
    micr_code   text,
    created_at  timestamp not null default current_timestamp,
    updated_at  timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger tg_sync_bank_updated_at
    before update
    on bank
    for each row
execute procedure tgf_sync_updated_at();