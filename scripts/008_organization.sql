create table if not exists organization
(
    name       text           not null primary key,
    full_name  text           not null,
    country    text           not null,
    book_begin date           not null,
    fp_code    int            not null,
    status     text           not null,
    owned_by   text           not null,
    gst_no     text,
    updated_at  timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint full_name_min_length check (char_length(trim(full_name)) > 0),
    constraint status_invalid check (check_org_status(status))
);
--##
create trigger sync_organization_updated_at
    before update
    on organization
    for each row
execute procedure sync_updated_at();