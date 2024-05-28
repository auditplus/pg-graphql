create table if not exists material_conversion
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
    amount            float,
    description       text,
    ac_trns           jsonb,
    created_at        timestamp             not null default current_timestamp,
    updated_at        timestamp             not null default current_timestamp
);
--##
create function create_material_conversion(
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
    returns material_conversion as
$$
declare
    v_material_conversion material_conversion;
    v_voucher             voucher;
    item                  material_conversion_inv_item;
    items                 material_conversion_inv_item[] := (select array_agg(x)
                                                             from jsonb_populate_recordset(
                                                                          null::material_conversion_inv_item,
                                                                          create_material_conversion.inv_items) as x);
    inv                   inventory;
    bat                   batch;
    div                   division;
    war                   warehouse;
    loose                 int;
begin
    select *
    into v_voucher
    FROM
        create_voucher(date := create_material_conversion.date, branch := create_material_conversion.branch,
                       voucher_type := create_material_conversion.voucher_type,
                       ref_no := create_material_conversion.ref_no,
                       description := create_material_conversion.description, mode := 'INVENTORY',
                       amount := create_material_conversion.amount, ac_trns := create_material_conversion.ac_trns,
                       eff_date := create_material_conversion.eff_date,
                       unique_session := create_material_conversion.unique_session
        );
    if v_voucher.base_voucher_type != 'MATERIAL_CONVERSION' then
        raise exception 'Allowed only MATERIAL_CONVERSION voucher type';
    end if;
    select * into war from warehouse where id = create_material_conversion.warehouse;
    insert into material_conversion (voucher, date, eff_date, branch, branch_name, warehouse, base_voucher_type,
                                     voucher_type, voucher_no, voucher_prefix, voucher_fy, voucher_seq, ref_no,
                                     description, ac_trns, amount)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch, v_voucher.branch_name,
            create_material_conversion.warehouse, v_voucher.base_voucher_type, v_voucher.voucher_type,
            v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq,
            v_voucher.ref_no, v_voucher.description, create_material_conversion.ac_trns,
            create_material_conversion.amount)
    returning * into v_material_conversion;
    foreach item in array items
        loop
            select *
            into inv
            from inventory
            where id = item.target_inventory;
            if not FOUND then
                raise exception 'Invalid target inventory';
            end if;
            select * into div from division where id = inv.division;
            if not FOUND then
                raise exception 'internal err for target inventory division';
            end if;
            insert into batch (inventory, inventory_name, branch, branch_name, division, division_name, txn_id,
                               batch_no, expiry, entry_date, mrp, s_rate, nlc, cost, unit_id, unit_conv, manufacturer,
                               manufacturer_name, category1, category2, category3, category4, category5, category6,
                               category7, category8, category9, category10, voucher, voucher_no, ref_no, warehouse,
                               warehouse_name, entry_type, inventory_voucher_id, loose_qty, label_qty)
            values (item.target_inventory, inv.name, v_material_conversion.branch, v_material_conversion.branch_name,
                    div.id, div.name, item.target_id, item.target_batch_no, item.target_expiry,
                    v_material_conversion.date, item.target_mrp, item.target_s_rate, item.target_nlc, item.target_cost,
                    item.target_unit, item.target_unit_conv, inv.manufacturer, inv.manufacturer_name,
                    (item.target_category ->> 'category1')::int, (item.target_category ->> 'category2')::int,
                    (item.target_category ->> 'category3')::int, (item.target_category ->> 'category4')::int,
                    (item.target_category ->> 'category5')::int, (item.target_category ->> 'category6')::int,
                    (item.target_category ->> 'category7')::int, (item.target_category ->> 'category8')::int,
                    (item.target_category ->> 'category9')::int, (item.target_category ->> 'category10')::int,
                    v_material_conversion.voucher, v_material_conversion.voucher_no, v_material_conversion.ref_no,
                    v_material_conversion.warehouse, war.name, 'MATERIAL_CONVERSION', v_material_conversion.id,
                    inv.loose_qty, item.target_qty * item.target_unit_conv)
            returning * into bat;
            if item.target_is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch, branch_name, division, division_name, batch, inventory,
                                inventory_name, manufacturer, manufacturer_name, inward,
                                reorder_inventory, nlc, category1, category1_name, category2, category2_name,
                                category3, category3_name, category4, category4_name, category5, category5_name,
                                category6, category6_name, category7, category7_name, category8, category8_name,
                                category9, category9_name, category10, category10_name, voucher, voucher_no,
                                voucher_type, base_voucher_type, ref_no, inventory_voucher_id, warehouse,
                                warehouse_name)
            values (item.target_id, v_material_conversion.date, v_material_conversion.branch,
                    v_material_conversion.branch_name, div.id, div.name, bat.id, item.target_inventory, inv.name,
                    inv.manufacturer, inv.manufacturer_name,
                    item.target_qty * item.target_unit_conv * loose, coalesce(inv.reorder_inventory, inv.id),
                    item.target_nlc, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, v_material_conversion.voucher, v_material_conversion.voucher_no,
                    v_material_conversion.voucher_type, v_material_conversion.base_voucher_type,
                    v_material_conversion.ref_no, v_material_conversion.id, war.id, war.name);
            select *
            into bat
            from get_batch(v_bat := item.source_batch, v_inv := item.source_inventory, v_br := v_voucher.branch,
                           v_war := war.id);
            select * into inv from inventory where id = item.source_inventory;
            if not FOUND then
                raise exception 'Invalid source inventory';
            end if;
            select * into div from division where id = inv.division;
            if not FOUND then
                raise exception 'internal err for source inventory division';
            end if;
            if item.source_is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch, branch_name, division, division_name, batch, reorder_inventory,
                                inventory, inventory_name, manufacturer, manufacturer_name, outward,
                                category1, category2, category3, category4, category5, category6, category7, category8,
                                category9, category10, category1_name, category2_name, category3_name, category4_name,
                                category5_name, category6_name, category7_name, category8_name, category9_name,
                                category10_name, voucher, voucher_no, voucher_type, base_voucher_type,
                                inventory_voucher_id, warehouse, warehouse_name)
            values (item.source_id, v_material_conversion.date, v_material_conversion.branch,
                    v_material_conversion.branch_name, div.id, div.name, item.source_batch,
                    coalesce(inv.reorder_inventory, inv.id), item.source_inventory, inv.name,
                    inv.manufacturer, inv.manufacturer_name, item.source_qty * item.source_unit_conv * loose,
                    bat.category1, bat.category2, bat.category3, bat.category4, bat.category5, bat.category6,
                    bat.category7, bat.category8, bat.category9, bat.category10, bat.category1_name,
                    bat.category2_name, bat.category3_name, bat.category4_name, bat.category5_name, bat.category6_name,
                    bat.category7_name, bat.category8_name, bat.category9_name, bat.category10_name,
                    v_material_conversion.voucher, v_material_conversion.voucher_no, v_material_conversion.voucher_type,
                    v_material_conversion.base_voucher_type, v_material_conversion.id, war.id, war.name);
            insert into material_conversion_inv_item(target_id, source_id, material_conversion, source_batch,
                                                     source_inventory, source_unit, source_unit_conv, source_qty,
                                                     source_is_loose_qty, source_asset_amount,
                                                     target_inventory, target_unit, target_unit_conv, target_qty,
                                                     target_is_loose_qty, target_gst_tax, target_cost,
                                                     target_asset_amount, target_mrp, target_nlc, target_s_rate,
                                                     target_batch_no, target_expiry, target_category, qty_conv)
            values (item.target_id, item.source_id, v_material_conversion.id, item.source_batch,
                    item.source_inventory, item.source_unit, item.source_unit_conv, item.source_qty,
                    item.source_is_loose_qty, item.source_asset_amount, item.target_inventory,
                    item.target_unit, item.target_unit_conv, item.target_qty, item.target_is_loose_qty,
                    item.target_gst_tax, item.target_cost, item.target_asset_amount,
                    item.target_mrp, item.target_nlc, item.target_s_rate, item.target_batch_no, item.target_expiry,
                    item.target_category, item.qty_conv);
        end loop;
    return v_material_conversion;
end;
$$ language plpgsql security definer;
--##
create function update_material_conversion(
    v_id int,
    date date,
    inv_items jsonb,
    ac_trns jsonb,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null
)
    returns material_conversion as
$$
declare
    v_material_conversion material_conversion;
    v_voucher             voucher;
    item                  material_conversion_inv_item;
    items                 material_conversion_inv_item[] := (select array_agg(x)
                                                             from jsonb_populate_recordset(
                                                                          null::material_conversion_inv_item,
                                                                          update_material_conversion.inv_items) as x);
    inv                   inventory;
    bat                   batch;
    div                   division;
    war                   warehouse;
    loose                 int;
    missed_tar_txn_ids    uuid[];
    missed_src_txn_ids    uuid[];
begin
    update stock_addition
    set date        = update_material_conversion.date,
        eff_date    = update_material_conversion.eff_date,
        ref_no      = update_material_conversion.ref_no,
        description = update_material_conversion.description,
        amount      = update_material_conversion.amount,
        ac_trns     = update_material_conversion.ac_trns,
        updated_at  = current_timestamp
    where id = $1
    returning * into v_material_conversion;
    if not FOUND then
        raise exception 'material_conversion not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_id := v_material_conversion.voucher, date := v_material_conversion.date,
                       ref_no := v_material_conversion.ref_no, description := v_material_conversion.description,
                       amount := v_material_conversion.amount, ac_trns := v_material_conversion.ac_trns,
                       eff_date := v_material_conversion.eff_date
        );
    select array_agg(target_id)
    into missed_tar_txn_ids
    from ((select target_id, target_inventory
           from material_conversion_inv_item
           where material_conversion_inv_item = $1)
          except
          (select target_id, target_inventory
           from unnest(items)));
    select array_agg(source_id)
    into missed_src_txn_ids
    from ((select source_id, source_batch, source_inventory
           from material_conversion_inv_item
           where material_conversion_inv_item = $1)
          except
          (select source_id, source_batch, source_inventory
           from unnest(items)));
    delete from material_conversion_inv_item where target_id = any (missed_tar_txn_ids);
    delete from material_conversion_inv_item where source_id = any (missed_src_txn_ids);
    select *
    into v_voucher
    FROM
        update_voucher(v_id := v_material_conversion.voucher, date := update_material_conversion.date,
                       ref_no := update_material_conversion.ref_no,
                       description := update_material_conversion.description,
                       amount := update_material_conversion.amount, ac_trns := update_material_conversion.ac_trns,
                       eff_date := update_material_conversion.eff_date
        );
    select * into war from warehouse where id = update_material_conversion.warehouse;
    foreach item in array items
        loop
            select *
            into inv
            from inventory
            where id = item.target_inventory;
            if not FOUND then
                raise exception 'Invalid target inventory';
            end if;
            select * into div from division where id = inv.division;
            if not FOUND then
                raise exception 'internal err for target inventory division';
            end if;
            insert into batch (inventory, inventory_name, branch, branch_name, division, division_name, txn_id,
                               batch_no, expiry, entry_date, mrp, s_rate, nlc, cost, unit_id, unit_conv, manufacturer,
                               manufacturer_name, category1, category2, category3, category4, category5, category6,
                               category7, category8, category9, category10, voucher, voucher_no, ref_no, warehouse,
                               warehouse_name, entry_type, inventory_voucher_id, loose_qty, label_qty)
            values (item.target_inventory, inv.name, v_material_conversion.branch,
                    v_material_conversion.branch_name, div.id, div.name, item.target_id, item.target_batch_no,
                    item.target_expiry, v_material_conversion.date, item.target_mrp, item.target_s_rate,
                    item.target_nlc, item.target_cost, item.target_unit, item.target_unit_conv, inv.manufacturer,
                    inv.manufacturer_name, (item.target_category ->> 'category1')::int,
                    (item.target_category ->> 'category2')::int, (item.target_category ->> 'category3')::int,
                    (item.target_category ->> 'category4')::int, (item.target_category ->> 'category5')::int,
                    (item.target_category ->> 'category6')::int, (item.target_category ->> 'category7')::int,
                    (item.target_category ->> 'category8')::int, (item.target_category ->> 'category9')::int,
                    (item.target_category ->> 'category10')::int, v_material_conversion.voucher,
                    v_material_conversion.voucher_no, v_material_conversion.ref_no, v_material_conversion.warehouse,
                    war.name, 'MATERIAL_CONVERSION', v_material_conversion.id, inv.loose_qty,
                    item.target_qty * item.target_unit_conv)
            on conflict (txn_id) do update
                set inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    label_qty         = excluded.label_qty,
                    batch_no          = excluded.batch_no,
                    expiry            = excluded.expiry,
                    entry_date        = excluded.entry_date,
                    mrp               = excluded.mrp,
                    s_rate            = excluded.s_rate,
                    nlc               = excluded.nlc,
                    cost              = excluded.cost,
                    unit_conv         = excluded.unit_conv,
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
                    ref_no            = excluded.ref_no
            returning * into bat;
            if item.target_is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch, branch_name, division, division_name, batch, inventory,
                                inventory_name, manufacturer, manufacturer_name, inward,
                                reorder_inventory, nlc, category1, category1_name, category2, category2_name,
                                category3, category3_name, category4, category4_name, category5, category5_name,
                                category6, category6_name, category7, category7_name, category8, category8_name,
                                category9, category9_name, category10, category10_name, voucher, voucher_no,
                                voucher_type, base_voucher_type, ref_no, inventory_voucher_id, warehouse,
                                warehouse_name)
            values (item.target_id, v_material_conversion.date, v_material_conversion.branch,
                    v_material_conversion.branch_name, div.id, div.name, bat.id, item.target_inventory, inv.name,
                    inv.manufacturer, inv.manufacturer_name,
                    item.target_qty * item.target_unit_conv * loose, coalesce(inv.reorder_inventory, inv.id),
                    item.target_nlc, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, v_material_conversion.voucher, v_material_conversion.voucher_no,
                    v_material_conversion.voucher_type, v_material_conversion.base_voucher_type,
                    v_material_conversion.ref_no, v_material_conversion.id, war.id, war.name)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    inward            = excluded.inward,
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
            select *
            into bat
            from get_batch(v_bat := item.source_batch, v_inv := item.source_inventory, v_br := v_voucher.branch,
                           v_war := war.id);
            select * into inv from inventory where id = item.source_inventory;
            if not FOUND then
                raise exception 'Invalid source inventory';
            end if;
            select * into div from division where id = inv.division;
            if not FOUND then
                raise exception 'internal err for source inventory division';
            end if;
            if item.source_is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch, branch_name, division, division_name, batch, reorder_inventory,
                                inventory, inventory_name, manufacturer, manufacturer_name, outward,
                                category1, category2, category3, category4, category5, category6, category7, category8,
                                category9, category10, category1_name, category2_name, category3_name, category4_name,
                                category5_name, category6_name, category7_name, category8_name, category9_name,
                                category10_name, voucher, voucher_no, voucher_type, base_voucher_type,
                                inventory_voucher_id, warehouse, warehouse_name)
            values (item.source_id, v_material_conversion.date, v_material_conversion.branch,
                    v_material_conversion.branch_name, div.id, div.name, item.source_batch,
                    coalesce(inv.reorder_inventory, inv.id), item.source_inventory, inv.name,
                    inv.manufacturer, inv.manufacturer_name, item.source_qty * item.source_unit_conv * loose,
                    bat.category1, bat.category2, bat.category3, bat.category4, bat.category5, bat.category6,
                    bat.category7, bat.category8, bat.category9, bat.category10, bat.category1_name,
                    bat.category2_name, bat.category3_name, bat.category4_name, bat.category5_name, bat.category6_name,
                    bat.category7_name, bat.category8_name, bat.category9_name, bat.category10_name,
                    v_material_conversion.voucher, v_material_conversion.voucher_no, v_material_conversion.voucher_type,
                    v_material_conversion.base_voucher_type, v_material_conversion.id, war.id, war.name)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    outward           = excluded.outward,
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
            insert into material_conversion_inv_item(target_id, source_id, material_conversion, source_batch,
                                                     source_inventory, source_unit, source_unit_conv, source_qty,
                                                     source_is_loose_qty, source_asset_amount,
                                                     target_inventory, target_unit, target_unit_conv, target_qty,
                                                     target_is_loose_qty, target_gst_tax, target_cost,
                                                     target_asset_amount, target_mrp, target_nlc, target_s_rate,
                                                     target_batch_no, target_expiry, target_category, qty_conv)
            values (item.target_id, item.source_id, v_material_conversion.id, item.source_batch,
                    item.source_inventory, item.source_unit, item.source_unit_conv, item.source_qty,
                    item.source_is_loose_qty, item.source_asset_amount, item.target_inventory,
                    item.target_unit, item.target_unit_conv, item.target_qty, item.target_is_loose_qty,
                    item.target_gst_tax, item.target_cost, item.target_asset_amount,
                    item.target_mrp, item.target_nlc, item.target_s_rate, item.target_batch_no, item.target_expiry,
                    item.target_category, item.qty_conv)
            on conflict (source_id, target_id) do update
                set source_unit         = excluded.source_unit,
                    qty_conv            = excluded.qty_conv,
                    source_unit_conv    = excluded.source_unit_conv,
                    source_qty          = excluded.source_qty,
                    source_is_loose_qty = excluded.source_is_loose_qty,
                    source_asset_amount = excluded.source_asset_amount,
                    target_unit         = excluded.target_unit,
                    target_unit_conv    = excluded.target_unit_conv,
                    target_qty          = excluded.target_qty,
                    target_is_loose_qty = excluded.target_is_loose_qty,
                    target_gst_tax      = excluded.target_gst_tax,
                    target_cost         = excluded.target_cost,
                    target_asset_amount = excluded.target_asset_amount,
                    target_mrp          = excluded.target_mrp,
                    target_nlc          = excluded.target_nlc,
                    target_s_rate       = excluded.target_s_rate,
                    target_batch_no     = excluded.target_batch_no,
                    target_expiry       = excluded.target_expiry,
                    target_category     = excluded.target_category;
        end loop;
    return v_material_conversion;
end;
$$ language plpgsql security definer;
--##
create function delete_material_conversion(v_id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from material_conversion where id = $1 returning voucher into voucher_id;
    delete from voucher where id = voucher_id;
    if not FOUND then
        raise exception 'Invalid material_conversion';
    end if;
end;
$$ language plpgsql security definer;
