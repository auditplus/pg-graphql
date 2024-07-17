create table if not exists stock_adjustment
(
    id                int       not null generated always as identity primary key,
    voucher_id        int       not null,
    date              date      not null,
    eff_date          date,
    branch_id         int       not null,
    branch_name       text      not null,
    warehouse_id      int       not null,
    base_voucher_type text      not null,
    voucher_type_id   int       not null,
    voucher_no        text      not null,
    voucher_prefix    text      not null,
    voucher_fy        int       not null,
    voucher_seq       int       not null,
    ref_no            text,
    description       text,
    amount            float,
    created_at        timestamp not null default current_timestamp,
    updated_at        timestamp not null default current_timestamp,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create function create_stock_adjustment(input_data json, unique_session uuid default null)
    returns stock_adjustment as
$$
declare
    v_stock_adjustment stock_adjustment;
    v_voucher          voucher;
    item               stock_adjustment_inv_item;
    items              stock_adjustment_inv_item[] := (select array_agg(x)
                                                       from jsonb_populate_recordset(
                                                                    null::stock_adjustment_inv_item,
                                                                    ($1 ->> 'inv_items')::jsonb) as x);
    inv                inventory;
    bat                batch;
    div                division;
    war                warehouse                   := (select warehouse
                                                       from warehouse
                                                       where id = ($1 ->> 'warehouse_id')::int);
    loose              int;
    inw                float;
    outw               float;
begin
    $1 = jsonb_set($1::jsonb, '{mode}', '"INVENTORY"');
    select * into v_voucher from create_voucher($1, $2);
    if v_voucher.base_voucher_type != 'STOCK_ADJUSTMENT' then
        raise exception 'Allowed only STOCK_ADJUSTMENT voucher type';
    end if;
    insert into stock_adjustment (voucher_id, date, eff_date, branch_id, branch_name, warehouse_id, base_voucher_type,
                                  voucher_type_id, voucher_no, voucher_prefix, voucher_fy, voucher_seq, ref_no,
                                  description, amount)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name, war.id,
            v_voucher.base_voucher_type, v_voucher.voucher_type_id, v_voucher.voucher_no, v_voucher.voucher_prefix,
            v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.ref_no, v_voucher.description, v_voucher.amount)
    returning * into v_stock_adjustment;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select * into div from division where id = inv.division_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_voucher.branch_id,
                           warehouse := v_stock_adjustment.warehouse_id);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into stock_adjustment_inv_item (id, sno, stock_adjustment_id, batch_id, inventory_id, unit_id,
                                                   unit_conv, qty, cost, is_loose_qty, asset_amount)
            values (coalesce(item.id, gen_random_uuid()), item.sno, v_stock_adjustment.id, item.batch_id,
                    item.inventory_id, item.unit_id, item.unit_conv, item.qty, item.cost, item.is_loose_qty,
                    item.asset_amount)
            returning * into item;
            if item.qty > 0 then
                inw := item.qty * item.unit_conv * loose;
                outw := 0;
            else
                outw := abs(item.qty) * item.unit_conv * loose;
                inw := 0.0;
            end if;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, manufacturer_id, manufacturer_name, asset_amount,
                                ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, inward, outward)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.manufacturer_id, inv.manufacturer_name, item.asset_amount, v_voucher.ref_no,
                    v_stock_adjustment.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type_id,
                    v_voucher.base_voucher_type, bat.category1_id, bat.category1_name, bat.category2_id,
                    bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id, bat.category4_name,
                    bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name, bat.category7_id,
                    bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id, bat.category9_name,
                    bat.category10_id, bat.category10_name, v_stock_adjustment.warehouse_id, war.name, inw, outw);
        end loop;
    return v_stock_adjustment;
end;
$$ language plpgsql security definer;
--##
create function update_stock_adjustment(v_id int, input_data json)
    returns stock_adjustment as
$$
declare
    v_stock_adjustment stock_adjustment;
    v_voucher          voucher;
    item               stock_adjustment_inv_item;
    items              stock_adjustment_inv_item[] := (select array_agg(x)
                                                       from jsonb_populate_recordset(
                                                                    null::stock_adjustment_inv_item,
                                                                    ($2 ->> 'inv_items')::jsonb) as x);
    inv                inventory;
    bat                batch;
    div                division;
    war                warehouse;
    loose              int;
    missed_items_ids   uuid[];
    inw                float;
    outw               float;
begin
    update stock_adjustment
    set date        = ($2 ->> 'date')::date,
        eff_date    = ($2 ->> 'eff_date')::date,
        ref_no      = ($2 ->> 'ref_no')::text,
        description = ($2 ->> 'description')::text,
        amount      = ($2 ->> 'amount')::float,
        updated_at  = current_timestamp
    where id = $1
    returning * into v_stock_adjustment;
    if not FOUND then
        raise exception 'stock_adjustment not found';
    end if;
    select * into v_voucher from update_voucher(v_stock_adjustment.voucher_id, $2);
    select array_agg(x.id)
    into missed_items_ids
    from ((select id, inventory_id, batch_id
           from stock_adjustment_inv_item
           where stock_adjustment_id = $1)
          except
          (select id, inventory_id, batch_id
           from unnest(items))) x;
    delete from stock_adjustment_inv_item where id = any (missed_items_ids);
    select * into war from warehouse where id = v_stock_adjustment.warehouse_id;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select * into div from division where id = inv.division_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id,
                           branch := v_stock_adjustment.branch_id, warehouse := v_stock_adjustment.warehouse_id);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            if item.qty > 0 then
                inw := item.qty * item.unit_conv * loose;
                outw := 0;
            else
                outw := item.qty * -1 * item.unit_conv * loose;
                inw := 0.0;
            end if;
            insert into stock_adjustment_inv_item (id, sno, stock_adjustment_id, batch_id, inventory_id, unit_id,
                                                   unit_conv, qty, cost, is_loose_qty, asset_amount)
            values (coalesce(item.id, gen_random_uuid()), item.sno, v_stock_adjustment.id, item.batch_id,
                    item.inventory_id, item.unit_id, item.unit_conv, item.qty, item.cost, item.is_loose_qty,
                    item.asset_amount)
            on conflict (id) do update
                set unit_id      = excluded.unit_id,
                    unit_conv    = excluded.unit_conv,
                    sno          = excluded.sno,
                    qty          = excluded.qty,
                    is_loose_qty = excluded.is_loose_qty,
                    cost         = excluded.cost,
                    asset_amount = excluded.asset_amount
            returning * into item;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, manufacturer_id, manufacturer_name, asset_amount,
                                ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, inward, outward)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.manufacturer_id, inv.manufacturer_name, item.asset_amount, v_voucher.ref_no,
                    v_stock_adjustment.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type_id,
                    v_voucher.base_voucher_type, bat.category1_id, bat.category1_name, bat.category2_id,
                    bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id, bat.category4_name,
                    bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name, bat.category7_id,
                    bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id, bat.category9_name,
                    bat.category10_id, bat.category10_name, v_stock_adjustment.warehouse_id, war.name, inw, outw)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    outward           = excluded.outward,
                    inward            = excluded.inward,
                    asset_amount      = excluded.asset_amount,
                    manufacturer_id   = excluded.manufacturer_id,
                    manufacturer_name = excluded.manufacturer_name,
                    category1_id      = excluded.category1_id,
                    category2_id      = excluded.category2_id,
                    category3_id      = excluded.category3_id,
                    category4_id      = excluded.category4_id,
                    category5_id      = excluded.category5_id,
                    category6_id      = excluded.category6_id,
                    category7_id      = excluded.category7_id,
                    category8_id      = excluded.category8_id,
                    category9_id      = excluded.category9_id,
                    category10_id     = excluded.category10_id,
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
        end loop;
    return v_stock_adjustment;
end ;
$$ language plpgsql security definer;
--##
create function delete_stock_adjustment(id int)
    returns void as
$$
declare
    v_id int;
begin
    delete from stock_adjustment where stock_adjustment.id = $1 returning voucher_id into v_id;
    delete from voucher where voucher.id = v_id;
    if not FOUND then
        raise exception 'Invalid stock_adjustment';
    end if;
end;
$$ language plpgsql security definer;