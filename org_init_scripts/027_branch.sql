create table if not exists branch
(
    id                int       not null generated always as identity primary key,
    name              text      not null,
    mobile            text,
    alternate_mobile  text,
    email             text,
    telephone         text,
    contact_person    text,
    address           text,
    city              text,
    pincode           text,
    state             text,
    country           text,
    gst_registration  int,
    voucher_no_prefix text      not null,
    misc              json,
    members           int[],
    account           int       not null UNIQUE,
    created_at        timestamp not null default current_timestamp,
    updated_at        timestamp not null default current_timestamp
);
--##
create trigger sync_branch_updated_at
    before update
    on branch
    for each row
execute procedure sync_updated_at();