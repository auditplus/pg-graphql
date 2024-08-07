create table if not exists acc_cat_txn
(
    id                 uuid              not null primary key,
    sno                smallint          not null,
    ac_txn_id          uuid              not null,
    date               date              not null,
    account_id         int               not null,
    account_name       text              not null,
    base_account_types text[]            not null,
    branch_id          int               not null,
    branch_name        text              not null,
    amount             float             not null default 0.0,
    credit             float             not null generated always as (case when amount < 0 then abs(amount) else 0 end) stored,
    debit              float             not null generated always as (case when amount > 0 then amount else 0 end) stored,
    voucher_id         int               not null,
    voucher_no         text              not null,
    voucher_type_id    int               not null,
    base_voucher_type  text              not null,
    voucher_mode       text,
    is_memo            boolean                    default false,
    ref_no             text,
    category1_id       int,
    category1_name     text,
    category2_id       int,
    category2_name     text,
    category3_id       int,
    category3_name     text,
    category4_id       int,
    category4_name     text,
    category5_id       int,
    category5_name     text,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type)),
    constraint voucher_mode_invalid check (check_voucher_mode(voucher_mode)),
    constraint base_account_types_invalid check (check_base_account_types(base_account_types))
);
--##
create view vw_acc_cat_txn
as
select a.id,
       a.sno,
       a.ac_txn_id,
       a.amount,
       (select *
        from fetch_categories(json_build_object('category1', a.category1_id, 'category2', a.category2_id, 'category3',
                                                a.category3_id, 'category4', a.category4_id, 'category5',
                                                a.category5_id))) as categories
from acc_cat_txn a
order by a.sno;
--##
create function tgf_fill_acc_cat_names()
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
    else
        new.category1_name = null;
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
    else
        new.category2_name = null;
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
    else
        new.category3_name = null;
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
    else
        new.category4_name = null;
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
    else
        new.category5_name = null;
    end if;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger tg_trig_fill_acc_cat_names
    before insert or update
    on acc_cat_txn
    for each row
execute procedure tgf_fill_acc_cat_names();