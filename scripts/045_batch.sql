create table if not exists batch
(
    id                   int       not null generated always as identity primary key,
    sno                  smallint  not null,
    inventory_id         int       not null,
    barcode              text      not null,
    inventory_name       text      not null,
    reorder_inventory_id int       not null,
    inventory_hsn        text,
    branch_id            int       not null,
    branch_name          text      not null,
    warehouse_id         int       not null,
    warehouse_name       text      not null,
    division_id          int       not null,
    division_name        text      not null,
    txn_id               uuid      not null unique,
    entry_type           text      not null,
    batch_no             text,
    inventory_voucher_id int,
    expiry               date,
    entry_date           date      not null,
    mrp                  float,
    s_rate               float,
    p_rate               float,
    landing_cost         float,
    nlc                  float     not null default 0,
    cost                 float     not null default 0,
    label_qty            float     not null,
    inward               float     not null default 0,
    outward              float     not null default 0,
    closing              float     not null generated always as (inward - outward) stored,
    loose_qty            int       not null default 1,
    unit_id              int       not null,
    unit_name            text      not null,
    unit_conv            float,
    ref_no               text,
    manufacturer_id      int,
    manufacturer_name    text,
    vendor_id            int,
    vendor_name          text,
    voucher_id           int,
    voucher_no           text,
    category1_id         int,
    category1_name       text,
    category2_id         int,
    category2_name       text,
    category3_id         int,
    category3_name       text,
    category4_id         int,
    category4_name       text,
    category5_id         int,
    category5_name       text,
    category6_id         int,
    category6_name       text,
    category7_id         int,
    category7_name       text,
    category8_id         int,
    category8_name       text,
    category9_id         int,
    category9_name       text,
    category10_id        int,
    category10_name      text,
    created_at           timestamp not null default current_timestamp,
    updated_at           timestamp not null default current_timestamp,
    constraint mrp_precision check (scale(mrp::numeric) <= 4),
    constraint s_rate_precision check (scale(s_rate::numeric) <= 4),
    constraint p_rate_precision check (scale(p_rate::numeric) <= 4),
    constraint landing_cost_precision check (scale(landing_cost::numeric) <= 4),
    constraint nlc_precision check (scale(nlc::numeric) <= 4),
    constraint cost_precision check (scale(cost::numeric) <= 4),
    constraint entry_type_invalid check (check_batch_entry_type(entry_type))
);
--##
create view vw_batch_condensed
as
select a.id,
       a.txn_id,
       a.inventory_id,
       a.inventory_name,
       a.batch_no,
       a.mrp,
       a.s_rate,
       a.nlc,
       a.landing_cost,
       a.loose_qty,
       a.p_rate,
       a.closing,
       a.cost,
       a.expiry,
       (select *
        from fetch_categories(json_build_object('category1', a.category1_id, 'category2', a.category2_id, 'category3',
                                                a.category3_id, 'category4', a.category4_id, 'category5',
                                                a.category5_id, 'category6', a.category6_id, 'category7',
                                                a.category7_id, 'category8', a.category8_id, 'category9',
                                                a.category9_id, 'category10', a.category10_id
                              ))) as categories
from batch a;
--##
create function get_batch(batch int, inventory int, branch int, warehouse int)
    returns setof batch AS
$$
begin
    return query select * from batch where id = $1 and inventory_id = $2 and branch_id = $3 and warehouse_id = $4;
    if not found then
        raise exception 'Invalid batch';
    end if;
end;
$$ language plpgsql security definer;
--##
create function tgf_before_batch_event()
    returns trigger as
$$
begin
    select name into new.unit_name from unit where id = new.unit_id;
    if new.category1_id is not null then
        select name
        into new.category1_name
        from category_option
        where id = new.category1_id
          and category_id = 'INV_CAT1';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 1';
        end if;
    else
        new.category1_name = null;
    end if;
    if new.category2_id is not null then
        select name
        into new.category2_name
        from category_option
        where id = new.category2_id
          and category_id = 'INV_CAT2';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 2';
        end if;
    else
        new.category2_name = null;
    end if;
    if new.category3_id is not null then
        select name
        into new.category3_name
        from category_option
        where id = new.category3_id
          and category_id = 'INV_CAT3';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 3';
        end if;
    else
        new.category3_name = null;
    end if;
    if new.category4_id is not null then
        select name
        into new.category4_name
        from category_option
        where id = new.category4_id
          and category_id = 'INV_CAT4';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 4';
        end if;
    else
        new.category4_name = null;
    end if;
    if new.category5_id is not null then
        select name
        into new.category5_name
        from category_option
        where id = new.category5_id
          and category_id = 'INV_CAT5';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 5';
        end if;
    else
        new.category5_name = null;
    end if;
    if new.category6_id is not null then
        select name
        into new.category6_name
        from category_option
        where id = new.category6_id
          and category_id = 'INV_CAT6';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 6';
        end if;
    else
        new.category6_name = null;
    end if;
    if new.category7_id is not null then
        select name
        into new.category7_name
        from category_option
        where id = new.category7_id
          and category_id = 'INV_CAT7';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 7';
        end if;
    else
        new.category7_name = null;
    end if;
    if new.category8_id is not null then
        select name
        into new.category8_name
        from category_option
        where id = new.category8_id
          and category_id = 'INV_CAT8';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 8';
        end if;
    else
        new.category8_name = null;
    end if;
    if new.category9_id is not null then
        select name
        into new.category9_name
        from category_option
        where id = new.category9_id
          and category_id = 'INV_CAT9';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 9';
        end if;
    else
        new.category9_name = null;
    end if;
    if new.category10_id is not null then
        select name
        into new.category10_name
        from category_option
        where id = new.category10_id
          and category_id = 'INV_CAT10';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 10';
        end if;
    else
        new.category10_name = null;
    end if;
    if (TG_OP = 'INSERT') then
        new.barcode = coalesce(new.barcode, new.id::text);
    end if;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql security definer;
--##
create function tgf_after_batch_event()
    returns trigger as
$$
declare
    inv inventory := (select inventory from inventory where id = old.inventory_id);
    stk float;
begin
    if tg_op = 'UPDATE' and not inv.allow_negative_stock and new.closing < 0 then
        raise exception 'Insufficient  Stock';
    end if;
    select sum(closing)
    into stk
    from batch
    where branch_id = old.branch_id
      and inventory_id = old.inventory_id;
    insert into inventory_branch_detail(branch_id, inventory_id, stock)
    values (old.branch_id, old.inventory_id, coalesce(stk, 0.0))
    on conflict (branch_id, inventory_id) do update
        set stock = excluded.stock;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger tg_before_batch
    before insert or update
    on batch
    for each row
execute procedure tgf_before_batch_event();
--##
create trigger tg_after_batch
    after update or delete
    on batch
    for each row
execute procedure tgf_after_batch_event();
