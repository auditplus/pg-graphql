create table if not exists branch
(
    id                  int       not null generated always as identity primary key,
    name                text      not null,
    mobile              text,
    alternate_mobile    text,
    email               text,
    telephone           text,
    contact_person      text,
    address             text,
    city                text,
    pincode             text,
    state_id            text,
    country_id          text,
    gst_registration_id int,
    voucher_no_prefix   text      not null,
    misc                json,
    members             int[]     not null default array[]::int[],
    account_id          int       not null unique,
    created_at          timestamp not null default current_timestamp,
    updated_at          timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint voucher_no_prefix_invalid check (voucher_no_prefix ~ '^[A-Z]+$' and
                                                char_length(voucher_no_prefix) between 2 and 3)
);
--##
create trigger sync_branch_updated_at
    before update
    on branch
    for each row
execute procedure sync_updated_at();
