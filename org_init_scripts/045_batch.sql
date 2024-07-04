create domain batch_entry as text
    check (value in ('PURCHASE', 'STOCK_ADDITION', 'MATERIAL_CONVERSION', 'OPENING'));
--##
create table if not exists batch
(
    id                   bigserial   not null primary key,
    sno                  smallint,
    inventory_id         bigint      not null,
    barcode              text        not null,
    inventory_name       text        not null,
    reorder_inventory_id bigint      not null,
    inventory_hsn        text,
    branch_id            bigint      not null,
    branch_name          text        not null,
    warehouse_id         bigint      not null,
    warehouse_name       text        not null,
    division_id          bigint      not null,
    division_name        text        not null,
    txn_id               uuid        not null unique,
    entry_type           batch_entry not null,
    batch_no             text,
    inventory_voucher_id bigint,
    expiry               date,
    entry_date           date        not null,
    mrp                  float,
    s_rate               float,
    p_rate               float,
    landing_cost         float,
    nlc                  float       not null default 0,
    cost                 float       not null default 0,
    label_qty            float       not null,
    inward               float       not null default 0,
    outward              float       not null default 0,
    closing              float       not null generated always as (inward - outward) stored,
    loose_qty            int         not null default 1,
    unit_id              bigint      not null,
    unit_name            text        not null,
    unit_conv            float,
    ref_no               text,
    manufacturer_id      bigint,
    manufacturer_name    text,
    vendor_id            bigint,
    vendor_name          text,
    voucher_id           bigint,
    voucher_no           text,
    category1_id         bigint,
    category1_name       text,
    category2_id         bigint,
    category2_name       text,
    category3_id         bigint,
    category3_name       text,
    category4_id         bigint,
    category4_name       text,
    category5_id         bigint,
    category5_name       text,
    category6_id         bigint,
    category6_name       text,
    category7_id         bigint,
    category7_name       text,
    category8_id         bigint,
    category8_name       text,
    category9_id         bigint,
    category9_name       text,
    category10_id        bigint,
    category10_name      text,
    created_at           timestamp   not null default current_timestamp,
    updated_at           timestamp   not null default current_timestamp,
    constraint mrp_precision check (scale(mrp::numeric) <= 4),
    constraint s_rate_precision check (scale(s_rate::numeric) <= 4),
    constraint p_rate_precision check (scale(p_rate::numeric) <= 4),
    constraint landing_cost_precision check (scale(landing_cost::numeric) <= 4),
    constraint nlc_precision check (scale(nlc::numeric) <= 4),
    constraint cost_precision check (scale(cost::numeric) <= 4)
);
--##
create function get_batch(batch bigint, inventory bigint, branch bigint, warehouse bigint)
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
create function before_batch_event()
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
    end if;
    if (TG_OP = 'INSERT') then
        new.barcode = coalesce(new.barcode, new.id::text);
    end if;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql security definer;
--##
create function after_batch_event()
    returns trigger as
$$
declare
    inv inventory;
    stk float;
begin
    select * into inv from inventory where id = old.inventory_id;
    if tg_op = 'UPDATE' and inv.allow_negative_stock is false and (new.inward - new.outward < 0) then
        raise exception 'Insufficient  Stock';
    end if;
    select sum(inward - outward)
    into stk
    from batch
    where branch_id = old.branch_id
      and inventory_id = old.inventory_id;
    insert into inventory_branch_detail(branch_id, inventory_id, branch_name, inventory_name, stock,
                                        reorder_inventory_id)
    values (old.branch_id, old.inventory_id, old.branch_name, old.inventory_name, coalesce(stk, 0.0),
            coalesce(inv.reorder_inventory_id, inv.id))
    on conflict (branch_id, inventory_id) do update
        set inventory_name = excluded.inventory_name,
            branch_name    = excluded.branch_name,
            stock          = excluded.stock;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger before_batch
    before insert or update
    on batch
    for each row
execute procedure before_batch_event();
--##
create trigger after_batch
    after update or delete
    on batch
    for each row
execute procedure after_batch_event();
