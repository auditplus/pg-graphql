create table if not exists gift_coupon
(
    id                      int       not null generated always as identity primary key,
    name                    text      not null,
    amount                  float     not null,
    active                  boolean   not null default true,
    gift_voucher_id         int       not null,
    gift_voucher_account_id int       not null,
    branch_id               int,
    valid_from              date,
    valid_to                date,
    created_at              timestamp not null default current_timestamp,
    updated_at              timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_gift_coupon_updated_at
    before update
    on gift_coupon
    for each row
execute procedure sync_updated_at();