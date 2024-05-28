create type typ_batch_entry as enum ('PURCHASE', 'STOCK_ADDITION', 'MATERIAL_CONVERSION', 'OPENING');
--##
create table if not exists batch
(
    id                   int             not null generated always as identity primary key,
    sno                  smallint,
    inventory            int             not null,
    barcode              text            not null,
    inventory_name       text            not null,
    inventory_hsn        text,
    branch               int             not null,
    branch_name          text            not null,
    warehouse            int             not null,
    warehouse_name       text            not null,
    division             int             not null,
    division_name        text            not null,
    txn_id               uuid            not null unique,
    entry_type           typ_batch_entry not null,
    batch_no             text,
    inventory_voucher_id int,
    expiry               date,
    entry_date           date            not null,
    mrp                  numeric(11, 4),
    s_rate               numeric(11, 4),
    p_rate               numeric(11, 4),
    landing_cost         numeric(11, 4),
    nlc                  numeric(11, 4)  not null default 0,
    cost                 numeric(11, 4)  not null default 0,
    label_qty            float           not null,
    inward               float           not null default 0,
    outward              float           not null default 0,
    loose_qty            int             not null default 1,
    unit_id              int             not null,
    unit_conv            float,
    ref_no               text,
    manufacturer         int,
    manufacturer_name    text,
    vendor               int,
    vendor_name          text,
    voucher              int,
    voucher_no           text,
    category1            int,
    category1_name       text,
    category2            int,
    category2_name       text,
    category3            int,
    category3_name       text,
    category4            int,
    category4_name       text,
    category5            int,
    category5_name       text,
    category6            int,
    category6_name       text,
    category7            int,
    category7_name       text,
    category8            int,
    category8_name       text,
    category9            int,
    category9_name       text,
    category10           int,
    category10_name      text,
    created_at           timestamp       not null default current_timestamp,
    updated_at           timestamp       not null default current_timestamp
);
--##
create function get_batch(v_bat int, v_inv int, v_br int, v_war int)
    returns setof batch AS
$$
begin
    return query select * from batch where id = $1 and inventory = $2 and branch = $3 and warehouse = $4;
    if not found then
        raise exception 'Invalid batch';
    end if;
end;
$$ language plpgsql;
--##
create function before_batch_event()
    returns trigger as
$$
begin
    if new.category1 is not null then
        select name into new.category1_name from category_option where id = new.category1 and category = 'INV_CAT1';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 1';
        end if;
    end if;
    if new.category2 is not null then
        select name into new.category2_name from category_option where id = new.category2 and category = 'INV_CAT2';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 2';
        end if;
    end if;
    if new.category3 is not null then
        select name into new.category3_name from category_option where id = new.category3 and category = 'INV_CAT3';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 3';
        end if;
    end if;
    if new.category4 is not null then
        select name into new.category4_name from category_option where id = new.category4 and category = 'INV_CAT4';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 4';
        end if;
    end if;
    if new.category5 is not null then
        select name into new.category5_name from category_option where id = new.category5 and category = 'INV_CAT5';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 5';
        end if;
    end if;
    if new.category6 is not null then
        select name into new.category6_name from category_option where id = new.category6 and category = 'INV_CAT6';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 6';
        end if;
    end if;
    if new.category7 is not null then
        select name into new.category7_name from category_option where id = new.category7 and category = 'INV_CAT7';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 7';
        end if;
    end if;
    if new.category8 is not null then
        select name into new.category8_name from category_option where id = new.category8 and category = 'INV_CAT8';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 8';
        end if;
    end if;
    if new.category9 is not null then
        select name into new.category9_name from category_option where id = new.category9 and category = 'INV_CAT9';
        if not FOUND then
            raise exception 'Invalid mapping found on inventory category 9';
        end if;
    end if;
    if new.category10 is not null then
        select name into new.category10_name from category_option where id = new.category10 and category = 'INV_CAT10';
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
$$ language plpgsql;
--##
create function after_batch_event()
    returns trigger as
$$
declare
    inv inventory;
    stk float;
begin
    select * into inv from inventory where id = old.inventory;
    if tg_op = 'UPDATE' and inv.allow_negative_stock is false and (new.inward - new.outward < 0) then
        raise exception 'Insufficient  Stock';
    end if;
    select sum(inward - outward)
    into stk
    from batch
    where branch = old.branch
      and inventory = old.inventory;
    insert into inventory_branch_detail(branch, inventory, branch_name, inventory_name, stock, reorder_inventory)
    values (old.branch, old.inventory, old.branch_name, old.inventory_name, coalesce(stk, 0.0),
            coalesce(inv.reorder_inventory, inv.id))
    on conflict (branch, inventory) do update
        set inventory_name = excluded.inventory_name,
            branch_name    = excluded.branch_name,
            stock          = excluded.stock;
    return new;
end;
$$ language plpgsql;
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