create table if not exists stock_adjustment
(
    id                int                   not null generated always as identity primary key,
    voucher           int                   not null,
    date              date                  not null,
    eff_date          date,
    branch            int                   not null,
    branch_name       text                  not null,
    warehouse         int                   not null,
    base_voucher_type typ_base_voucher_type not null,
    voucher_type      int                   not null,
    voucher_no        text                  not null,
    voucher_prefix    text                  not null,
    voucher_fy        int                   not null,
    voucher_seq       int                   not null,
    ref_no            text,
    description       text,
    ac_trns           jsonb,
    amount            float,
    created_at        timestamp             not null default current_timestamp,
    updated_at        timestamp             not null default current_timestamp
);
--##
create function create_stock_adjustment(
    date date,
    branch int,
    warehouse int,
    voucher_type int,
    inv_items jsonb,
    ac_trns jsonb,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null,
    unique_session uuid default gen_random_uuid()
)
    returns stock_adjustment as
$$
declare
    v_stock_adjustment stock_adjustment;
    v_voucher          voucher;
    item               stock_adjustment_inv_item;
    items              stock_adjustment_inv_item[] := (select array_agg(x)
                                                       from jsonb_populate_recordset(
                                                                    null::stock_adjustment_inv_item,
                                                                    create_stock_adjustment.inv_items) as x);
    inv                inventory;
    bat                batch;
    div                division;
    war                warehouse;
    loose              int;
    inw                float                       := 0.0;
    outw               float                       := 0.0;
begin
    select *
    into v_voucher
    FROM
        create_voucher(date := create_stock_adjustment.date, branch := create_stock_adjustment.branch,
                       voucher_type := create_stock_adjustment.voucher_type, ref_no := create_stock_adjustment.ref_no,
                       description := create_stock_adjustment.description, mode := 'INVENTORY',
                       amount := create_stock_adjustment.amount, ac_trns := create_stock_adjustment.ac_trns,
                       eff_date := create_stock_adjustment.eff_date,
                       unique_session := create_stock_adjustment.unique_session
        );
    if v_voucher.base_voucher_type != 'STOCK_ADJUSTMENT' then
        raise exception 'Allowed only STOCK_ADJUSTMENT voucher type';
    end if;
    select * into war from warehouse where id = create_stock_adjustment.warehouse;
    insert into stock_adjustment (voucher, date, eff_date, branch, branch_name, warehouse, base_voucher_type,
                                  voucher_type, voucher_no, voucher_prefix, voucher_fy, voucher_seq, ref_no,
                                  description, ac_trns, amount)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch, v_voucher.branch_name,
            create_stock_adjustment.warehouse, v_voucher.base_voucher_type, v_voucher.voucher_type,
            v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq,
            v_voucher.ref_no, v_voucher.description, create_stock_adjustment.ac_trns, create_stock_adjustment.amount)
    returning * into v_stock_adjustment;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            select *
            into bat
            from get_batch(v_bat := item.batch, v_inv := item.inventory, v_br := v_voucher.branch,
                           v_war := v_stock_adjustment.warehouse);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            if item.qty > 0 then
                inw := item.qty * item.unit_conv * loose;
            else
                outw := abs(item.qty) * item.unit_conv * loose;
            end if;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, manufacturer, manufacturer_name, asset_amount,
                                ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type, base_voucher_type,
                                category1, category1_name, category2, category2_name, category3, category3_name,
                                category4, category4_name, category5, category5_name, category6, category6_name,
                                category7, category7_name, category8, category8_name, category9, category9_name,
                                category10, category10_name, warehouse, warehouse_name, inward, outward)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    item.batch, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name,
                    inv.manufacturer, inv.manufacturer_name, item.asset_amount, v_voucher.ref_no, v_stock_adjustment.id,
                    v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type, v_voucher.base_voucher_type,
                    bat.category1, bat.category1_name, bat.category2, bat.category2_name, bat.category3,
                    bat.category3_name, bat.category4, bat.category4_name, bat.category5, bat.category5_name,
                    bat.category6, bat.category6_name, bat.category7, bat.category7_name, bat.category8,
                    bat.category8_name, bat.category9, bat.category9_name, bat.category10, bat.category10_name,
                    v_stock_adjustment.warehouse, war.name, inw, outw);
            insert into stock_adjustment_inv_item (id, stock_adjustment, batch, inventory, unit, unit_conv, qty, cost,
                                                   is_loose_qty, asset_amount)
            values (item.id, v_stock_adjustment.id, item.batch, item.inventory, item.unit, item.unit_conv, item.qty,
                    item.cost, item.is_loose_qty, item.asset_amount);
        end loop;
    return v_stock_adjustment;
end;
$$ language plpgsql security definer;
--##
create function update_stock_adjustment(
    v_id int,
    date date,
    inv_items jsonb,
    ac_trns jsonb,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null
)
    returns stock_adjustment AS
$$
declare
    v_stock_adjustment stock_adjustment;
    v_voucher          voucher;
    item               stock_adjustment_inv_item;
    items              stock_adjustment_inv_item[] := (select array_agg(x)
                                                       from jsonb_populate_recordset(
                                                                    null::stock_adjustment_inv_item,
                                                                    update_stock_adjustment.inv_items) as x);
    inv                inventory;
    bat                batch;
    div                division;
    war                warehouse;
    loose              int;
    missed_items_ids   uuid[];
    inw                float                       := 0.0;
    outw               float                       := 0.0;
begin
    update stock_adjustment
    set date        = update_stock_adjustment.date,
        eff_date    = update_stock_adjustment.eff_date,
        ref_no      = update_stock_adjustment.ref_no,
        description = update_stock_adjustment.description,
        amount      = update_stock_adjustment.amount,
        ac_trns     = update_stock_adjustment.ac_trns,
        updated_at  = current_timestamp
    where id = $1
    returning * into v_stock_adjustment;
    if not FOUND then
        raise exception 'stock_adjustment not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_id := v_stock_adjustment.voucher, date := v_stock_adjustment.date,
                       ref_no := v_stock_adjustment.ref_no, description := v_stock_adjustment.description,
                       amount := v_stock_adjustment.amount, ac_trns := v_stock_adjustment.ac_trns,
                       eff_date := v_stock_adjustment.eff_date
        );
    select array_agg(id)
    into missed_items_ids
    from ((select id, inventory, batch
           from stock_adjustment_inv_item
           where stock_adjustment = update_stock_adjustment.v_id)
          except
          (select id, inventory, batch
           from unnest(items)));
    delete from stock_adjustment_inv_item where id = any (missed_items_ids);
    select * into war from warehouse where id = v_stock_adjustment.warehouse;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            select *
            into bat
            from get_batch(v_bat := item.batch, v_inv := item.inventory, v_br := v_stock_adjustment.branch,
                           v_war := v_stock_adjustment.warehouse);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            if item.qty > 0 then
                inw := item.qty * item.unit_conv * loose;
            else
                outw := item.qty * -1 * item.unit_conv * loose;
            end if;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, manufacturer, manufacturer_name, outward,
                                asset_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name, inward, outward)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    item.batch, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name,
                    inv.manufacturer, inv.manufacturer_name, item.qty * item.unit_conv * loose, item.asset_amount,
                    v_voucher.ref_no, v_stock_adjustment.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type,
                    v_voucher.base_voucher_type, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, v_stock_adjustment.warehouse, war.name, inw, outw)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    outward           = excluded.outward,
                    inward            = excluded.inward,
                    asset_amount      = excluded.asset_amount,
                    manufacturer      = excluded.manufacturer,
                    manufacturer_name = excluded.manufacturer_name,
                    category1         = excluded.category1,
                    category2         = excluded.category2,
                    category3         = excluded.category3,
                    category4         = excluded.category4,
                    category5         = excluded.category5,
                    category6         = excluded.category6,
                    category7         = excluded.category7,
                    category8         = excluded.category8,
                    category9         = excluded.category9,
                    category10        = excluded.category10,
                    category1_name    = excluded.category1_name,
                    category2_name    = excluded.category2_name,
                    category3_name    = excluded.category3_name,
                    category4_name    = excluded.category4_name,
                    category5_name    = excluded.category5_name,
                    category6_name    = excluded.category6_name,
                    category7_name    = excluded.category7_name,
                    category8_name    = excluded.category8_name,
                    category9_name    = excluded.category9_name,
                    category10_name   = excluded.category10_name,
                    ref_no            = excluded.ref_no;
            insert into stock_adjustment_inv_item (id, stock_adjustment, batch, inventory, unit, unit_conv, qty, cost,
                                                   is_loose_qty, asset_amount)
            values (item.id, v_stock_adjustment.id, item.batch, item.inventory, item.unit, item.unit_conv, item.qty,
                    item.cost, item.is_loose_qty, item.asset_amount)
            on conflict (id) do update
                set unit         = excluded.unit,
                    unit_conv    = excluded.unit_conv,
                    qty          = excluded.qty,
                    is_loose_qty = excluded.is_loose_qty,
                    cost         = excluded.cost,
                    asset_amount = excluded.asset_amount;
        end loop;
    return v_stock_adjustment;
end;
$$ language plpgsql security definer;
--##
create function delete_stock_adjustment(v_id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from stock_adjustment where id = $1 returning voucher into voucher_id;
    delete from voucher where id = voucher_id;
    if not FOUND then
        raise exception 'Invalid stock_adjustment';
    end if;
end;
$$ language plpgsql security definer;