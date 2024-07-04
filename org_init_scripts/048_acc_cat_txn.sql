create table if not exists acc_cat_txn
(
    id                 uuid              not null primary key,
    ac_txn_id          uuid              not null,
    date               date              not null,
    account_id         bigint            not null,
    account_name       text              not null,
    base_account_types text[]            not null,
    branch_id          bigint            not null,
    branch_name        text              not null,
    amount             float             not null default 0.0,
    credit             float             not null generated always as (case when amount < 0 then abs(amount) else 0 end) stored,
    debit              float             not null generated always as (case when amount > 0 then amount else 0 end) stored,
    voucher_id         bigint            not null,
    voucher_no         text              not null,
    voucher_type_id    bigint            not null,
    base_voucher_type  base_voucher_type not null,
    voucher_mode       voucher_mode,
    is_memo            boolean                    default false,
    ref_no             text,
    category1_id       bigint,
    category1_name     text,
    category2_id       bigint,
    category2_name     text,
    category3_id       bigint,
    category3_name     text,
    category4_id       bigint,
    category4_name     text,
    category5_id       bigint,
    category5_name     text
);
--##
create function fn_fill_acc_cat_names()
    returns trigger as
$$
begin
    if new.category1_id is not null then
        select name
        into new.category1_name
        from category_option
        where id = new.category1_id
          and category_id = 'ACC_CAT1';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 1';
        end if;
    end if;
    if new.category2_id is not null then
        select name
        into new.category2_name
        from category_option
        where id = new.category2_id
          and category_id = 'ACC_CAT2';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 2';
        end if;
    end if;
    if new.category3_id is not null then
        select name
        into new.category3_name
        from category_option
        where id = new.category3_id
          and category_id = 'ACC_CAT3';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 3';
        end if;
    end if;
    if new.category4_id is not null then
        select name
        into new.category4_name
        from category_option
        where id = new.category4_id
          and category_id = 'ACC_CAT4';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 4';
        end if;
    end if;
    if new.category5_id is not null then
        select name
        into new.category5_name
        from category_option
        where id = new.category5_id
          and category_id = 'ACC_CAT5';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 5';
        end if;
    end if;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger trig_fill_acc_cat_names
    before insert or update
    on acc_cat_txn
    for each row
execute procedure fn_fill_acc_cat_names();