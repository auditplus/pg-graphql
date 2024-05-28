create table if not exists acc_cat_txn
(
    id                uuid                  not null primary key,
    ac_txn            uuid                  not null,
    date              date                  not null,
    account           int                   not null,
    account_name      text                  not null,
    account_type      text                  not null,
    branch            int                   not null,
    branch_name       text                  not null,
    amount            float                 not null default 0.0,
    voucher           int                   not null,
    voucher_no        text                  not null,
    voucher_type      int                   not null,
    base_voucher_type typ_base_voucher_type not null,
    voucher_mode      typ_voucher_mode,
    is_memo           boolean                        default false,
    ref_no            text,
    category1         int,
    category1_name    text,
    category2         int,
    category2_name    text,
    category3         int,
    category3_name    text,
    category4         int,
    category4_name    text,
    category5         int,
    category5_name    text
);
--##
create function fn_fill_acc_cat_names()
    returns trigger as
$$
begin
    if new.category1 is not null then
        select name into new.category1_name from category_option where id = new.category1 and category = 'ACC_CAT1';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 1';
        end if;
    end if;
    if new.category2 is not null then
        select name into new.category2_name from category_option where id = new.category2 and category = 'ACC_CAT2';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 2';
        end if;
    end if;
    if new.category3 is not null then
        select name into new.category3_name from category_option where id = new.category3 and category = 'ACC_CAT3';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 3';
        end if;
    end if;
    if new.category4 is not null then
        select name into new.category4_name from category_option where id = new.category4 and category = 'ACC_CAT4';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 4';
        end if;
    end if;
    if new.category5 is not null then
        select name into new.category5_name from category_option where id = new.category5 and category = 'ACC_CAT5';
        if not FOUND then
            raise exception 'Invalid mapping found on account category 5';
        end if;
    end if;
    return new;
end;
$$ language plpgsql;
--##
create trigger trig_fill_acc_cat_names
    before insert or update
    on acc_cat_txn
    for each row
execute procedure fn_fill_acc_cat_names();