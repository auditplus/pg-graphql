create table if not exists bank
(
    id          bigserial not null primary key,
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
create trigger sync_bank_updated_at
    before update
    on bank
    for each row
execute procedure sync_updated_at();