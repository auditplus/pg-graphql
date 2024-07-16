create table if not exists material_conversion
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
    amount            float,
    description       text,
    created_at        timestamp not null default current_timestamp,
    updated_at        timestamp not null default current_timestamp,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create function create_material_conversion(input_data json, unique_session uuid default null)
    returns material_conversion as
$$
declare
    v_material_conversion material_conversion;
    v_voucher             voucher;
    item                  material_conversion_inv_item;
    items                 material_conversion_inv_item[] := (select array_agg(x)
                                                             from jsonb_populate_recordset(
                                                                          null::material_conversion_inv_item,
                                                                          ($1 ->> 'inv_items')::jsonb) as x);
    inv                   inventory;
    bat                   batch;
    div                   division;
    war                   warehouse                      := (select warehouse
                                                             from warehouse
                                                             where id = ($1 ->> 'warehouse_id')::int);
    loose                 int;
begin
    $1 = jsonb_set($1::jsonb, '{mode}', '"INVENTORY"');
    select * into v_voucher from create_voucher($1, $2);
    if v_voucher.base_voucher_type != 'MATERIAL_CONVERSION' then
        raise exception 'Allowed only MATERIAL_CONVERSION voucher type';
    end if;
    insert into material_conversion (voucher_id, date, eff_date, branch_id, branch_name, warehouse_id,
                                     base_voucher_type, voucher_type_id, voucher_no, voucher_prefix, voucher_fy,
                                     voucher_seq, ref_no, description, amount)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name, war.id,
            v_voucher.base_voucher_type, v_voucher.voucher_type_id, v_voucher.voucher_no, v_voucher.voucher_prefix,
            v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.ref_no, v_voucher.description, v_voucher.amount)
    returning * into v_material_conversion;
    foreach item in array items
        loop
            insert into material_conversion_inv_item(target_id, source_id, sno, material_conversion_id, source_batch_id,
                                                     source_inventory_id, source_unit_id, source_unit_conv, source_qty,
                                                     source_is_loose_qty, source_asset_amount, target_inventory_id,
                                                     target_unit_id, target_unit_conv, target_qty, target_is_loose_qty,
                                                     target_gst_tax_id, target_cost, target_asset_amount, target_mrp,
                                                     target_nlc, target_s_rate, target_batch_no, target_expiry,
                                                     qty_conv, target_category1_id, target_category2_id,
                                                     target_category3_id, target_category4_id, target_category5_id,
                                                     target_category6_id, target_category7_id, target_category8_id,
                                                     target_category9_id, target_category10_id)
            values (coalesce(item.target_id, gen_random_uuid()), coalesce(item.source_id, gen_random_uuid()), item.sno,
                    v_material_conversion.id, item.source_batch_id, item.source_inventory_id, item.source_unit_id,
                    item.source_unit_conv, item.source_qty, item.source_is_loose_qty, item.source_asset_amount,
                    item.target_inventory_id, item.target_unit_id, item.target_unit_conv, item.target_qty,
                    item.target_is_loose_qty, item.target_gst_tax_id, item.target_cost, item.target_asset_amount,
                    item.target_mrp, item.target_nlc, item.target_s_rate, item.target_batch_no, item.target_expiry,
                    item.qty_conv, item.target_category1_id, item.target_category2_id, item.target_category3_id,
                    item.target_category4_id, item.target_category5_id, item.target_category6_id,
                    item.target_category7_id, item.target_category8_id, item.target_category9_id,
                    item.target_category10_id)
            returning * into item;
            select *
            into inv
            from inventory
            where id = item.target_inventory_id;
            if not FOUND then
                raise exception 'Invalid target inventory';
            end if;
            select * into div from division where id = inv.division_id;
            if not FOUND then
                raise exception 'internal err for target inventory division';
            end if;
            insert into batch (inventory_id, reorder_inventory_id, inventory_name, branch_id, branch_name, division_id,
                               division_name, txn_id, sno, batch_no, expiry, entry_date, mrp, s_rate, nlc, cost,
                               unit_id, unit_conv, manufacturer_id, manufacturer_name, category1_id, category2_id,
                               category3_id, category4_id, category5_id, category6_id, category7_id, category8_id,
                               category9_id, category10_id, voucher_id, voucher_no, ref_no, warehouse_id,
                               warehouse_name, entry_type, inventory_voucher_id, loose_qty, label_qty)
            values (item.target_inventory_id, coalesce(inv.reorder_inventory_id, inv.id), inv.name,
                    v_material_conversion.branch_id, v_material_conversion.branch_name, div.id, div.name,
                    item.target_id, item.sno, item.target_batch_no, item.target_expiry, v_material_conversion.date,
                    item.target_mrp, item.target_s_rate, item.target_nlc, item.target_cost, item.target_unit_id,
                    item.target_unit_conv, inv.manufacturer_id, inv.manufacturer_name, item.target_category1_id,
                    item.target_category2_id, item.target_category3_id, item.target_category4_id,
                    item.target_category5_id, item.target_category6_id, item.target_category7_id,
                    item.target_category8_id, item.target_category9_id, item.target_category10_id,
                    v_material_conversion.voucher_id, v_material_conversion.voucher_no, v_material_conversion.ref_no,
                    v_material_conversion.warehouse_id, war.name, 'MATERIAL_CONVERSION', v_material_conversion.id,
                    inv.loose_qty, item.target_qty * item.target_unit_conv)
            returning * into bat;
            if item.target_is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch_id, branch_name, division_id, division_name, batch_id, inventory_id,
                                inventory_name, manufacturer_id, manufacturer_name, inward, reorder_inventory_id, nlc,
                                category1_id, category1_name, category2_id, category2_name, category3_id,
                                category3_name, category4_id, category4_name, category5_id, category5_name,
                                category6_id, category6_name, category7_id, category7_name, category8_id,
                                category8_name, category9_id, category9_name, category10_id, category10_name,
                                voucher_id, voucher_no, voucher_type_id, base_voucher_type, ref_no,
                                inventory_voucher_id, warehouse_id, warehouse_name)
            values (item.target_id, v_material_conversion.date, v_material_conversion.branch_id,
                    v_material_conversion.branch_name, div.id, div.name, bat.id, item.target_inventory_id, inv.name,
                    inv.manufacturer_id, inv.manufacturer_name, item.target_qty * item.target_unit_conv * loose,
                    coalesce(inv.reorder_inventory_id, inv.id), item.target_nlc, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_material_conversion.voucher_id,
                    v_material_conversion.voucher_no, v_material_conversion.voucher_type_id,
                    v_material_conversion.base_voucher_type, v_material_conversion.ref_no, v_material_conversion.id,
                    war.id, war.name);
            select *
            into bat
            from get_batch(batch := item.source_batch_id, inventory := item.source_inventory_id,
                           branch := v_voucher.branch_id, warehouse := war.id);
            select * into inv from inventory where id = item.source_inventory_id;
            if not FOUND then
                raise exception 'Invalid source inventory';
            end if;
            select * into div from division where id = inv.division_id;
            if not FOUND then
                raise exception 'internal err for source inventory division';
            end if;
            if item.source_is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch_id, branch_name, division_id, division_name, batch_id,
                                reorder_inventory_id, inventory_id, inventory_name, manufacturer_id, manufacturer_name,
                                outward, category1_id, category2_id, category3_id, category4_id, category5_id,
                                category6_id, category7_id, category8_id, category9_id, category10_id, category1_name,
                                category2_name, category3_name, category4_name, category5_name, category6_name,
                                category7_name, category8_name, category9_name, category10_name, voucher_id, voucher_no,
                                voucher_type_id, base_voucher_type, inventory_voucher_id, warehouse_id, warehouse_name)
            values (item.source_id, v_material_conversion.date, v_material_conversion.branch_id,
                    v_material_conversion.branch_name, div.id, div.name, item.source_batch_id,
                    coalesce(inv.reorder_inventory_id, inv.id), item.source_inventory_id, inv.name, inv.manufacturer_id,
                    inv.manufacturer_name, item.source_qty * item.source_unit_conv * loose, bat.category1_id,
                    bat.category2_id, bat.category3_id, bat.category4_id, bat.category5_id, bat.category6_id,
                    bat.category7_id, bat.category8_id, bat.category9_id, bat.category10_id, bat.category1_name,
                    bat.category2_name, bat.category3_name, bat.category4_name, bat.category5_name, bat.category6_name,
                    bat.category7_name, bat.category8_name, bat.category9_name, bat.category10_name,
                    v_material_conversion.voucher_id, v_material_conversion.voucher_no,
                    v_material_conversion.voucher_type_id, v_material_conversion.base_voucher_type,
                    v_material_conversion.id, war.id, war.name);
        end loop;
    return v_material_conversion;
end;
$$ language plpgsql security definer;
--##
create function update_material_conversion(v_id int, input_data json)
    returns material_conversion as
$$
declare
    v_material_conversion material_conversion;
    v_voucher             voucher;
    item                  material_conversion_inv_item;
    items                 material_conversion_inv_item[] := (select array_agg(x)
                                                             from jsonb_populate_recordset(
                                                                          null::material_conversion_inv_item,
                                                                          ($2 ->> 'inv_items')::jsonb) as x);
    inv                   inventory;
    bat                   batch;
    div                   division;
    war                   warehouse;
    loose                 int;
    missed_tar_txn_ids    uuid[];
    missed_src_txn_ids    uuid[];
begin
    update stock_addition
    set date        = ($2 ->> 'date')::date,
        eff_date    = ($2 ->> 'eff_date')::date,
        ref_no      = ($2 ->> 'ref_no')::text,
        description = ($2 ->> 'description')::text,
        amount      = ($2 ->> 'amount')::float,
        updated_at  = current_timestamp
    where id = $1
    returning * into v_material_conversion;
    if not FOUND then
        raise exception 'material_conversion not found';
    end if;
    select array_agg(z.target_id)
    into missed_tar_txn_ids
    from ((select target_id, target_inventory_id
           from material_conversion_inv_item
           where material_conversion_inv_item = $1)
          except
          (select target_id, target_inventory_id
           from unnest(items))) as z;
    select array_agg(z.source_id)
    into missed_src_txn_ids
    from ((select source_id, source_batch_id, source_inventory_id
           from material_conversion_inv_item
           where material_conversion_inv_item = $1)
          except
          (select source_id, source_batch_id, source_inventory_id
           from unnest(items))) as z;
    delete
    from material_conversion_inv_item
    where target_id = any (missed_tar_txn_ids)
       or source_id = any (missed_src_txn_ids);
    select * into v_voucher from update_voucher(v_material_conversion.voucher_id, $2);
    select * into war from warehouse where id = update_material_conversion.warehouse_id;
    foreach item in array items
        loop
            select *
            into inv
            from inventory
            where id = item.target_inventory_id;
            if not FOUND then
                raise exception 'Invalid target inventory';
            end if;
            select * into div from division where id = inv.division_id;
            if not FOUND then
                raise exception 'internal err for target inventory division';
            end if;
            insert into material_conversion_inv_item(target_id, source_id, sno, material_conversion_id, source_batch_id,
                                                     source_inventory_id, source_unit_id, source_unit_conv, source_qty,
                                                     source_is_loose_qty, source_asset_amount, target_inventory_id,
                                                     target_unit_id, target_unit_conv, target_qty, target_is_loose_qty,
                                                     target_gst_tax_id, target_cost, target_asset_amount, target_mrp,
                                                     target_nlc, target_s_rate, target_batch_no, target_expiry,
                                                     qty_conv, target_category1_id, target_category2_id,
                                                     target_category3_id, target_category4_id, target_category5_id,
                                                     target_category6_id, target_category7_id, target_category8_id,
                                                     target_category9_id, target_category10_id)
            values (coalesce(item.target_id, gen_random_uuid()), coalesce(item.source_id, gen_random_uuid()), item.sno,
                    v_material_conversion.id, item.source_batch_id, item.source_inventory_id, item.source_unit_id,
                    item.source_unit_conv, item.source_qty, item.source_is_loose_qty, item.source_asset_amount,
                    item.target_inventory_id, item.target_unit_id, item.target_unit_conv, item.target_qty,
                    item.target_is_loose_qty, item.target_gst_tax_id, item.target_cost, item.target_asset_amount,
                    item.target_mrp, item.target_nlc, item.target_s_rate, item.target_batch_no, item.target_expiry,
                    item.qty_conv, item.target_category1_id, item.target_category2_id, item.target_category3_id,
                    item.target_category4_id, item.target_category5_id, item.target_category6_id,
                    item.target_category7_id, item.target_category8_id, item.target_category9_id,
                    item.target_category10_id)
            on conflict (source_id, target_id) do update
                set source_unit_id       = excluded.source_unit_id,
                    qty_conv             = excluded.qty_conv,
                    sno                  = excluded.sno,
                    source_unit_conv     = excluded.source_unit_conv,
                    source_qty           = excluded.source_qty,
                    source_is_loose_qty  = excluded.source_is_loose_qty,
                    source_asset_amount  = excluded.source_asset_amount,
                    target_unit_id       = excluded.target_unit_id,
                    target_unit_conv     = excluded.target_unit_conv,
                    target_qty           = excluded.target_qty,
                    target_is_loose_qty  = excluded.target_is_loose_qty,
                    target_gst_tax_id    = excluded.target_gst_tax_id,
                    target_cost          = excluded.target_cost,
                    target_asset_amount  = excluded.target_asset_amount,
                    target_mrp           = excluded.target_mrp,
                    target_nlc           = excluded.target_nlc,
                    target_s_rate        = excluded.target_s_rate,
                    target_batch_no      = excluded.target_batch_no,
                    target_expiry        = excluded.target_expiry,
                    target_category1_id  = excluded.target_category1_id,
                    target_category2_id  = excluded.target_category2_id,
                    target_category3_id  = excluded.target_category3_id,
                    target_category4_id  = excluded.target_category4_id,
                    target_category5_id  = excluded.target_category5_id,
                    target_category6_id  = excluded.target_category6_id,
                    target_category7_id  = excluded.target_category7_id,
                    target_category8_id  = excluded.target_category8_id,
                    target_category9_id  = excluded.target_category9_id,
                    target_category10_id = excluded.target_category10_id
            returning * into item;
            insert into batch (inventory_id, reorder_inventory_id, inventory_name, branch_id, branch_name, division_id,
                               division_name, txn_id, sno, batch_no, expiry, entry_date, mrp, s_rate, nlc, cost,
                               unit_id, unit_conv, manufacturer_id, manufacturer_name, category1_id, category2_id,
                               category3_id, category4_id, category5_id, category6_id, category7_id, category8_id,
                               category9_id, category10_id, voucher_id, voucher_no, ref_no, warehouse_id,
                               warehouse_name, entry_type, inventory_voucher_id, loose_qty, label_qty)
            values (item.target_inventory_id, coalesce(inv.reorder_inventory_id, inv.id), inv.name,
                    v_material_conversion.branch_id, v_material_conversion.branch_name, div.id, div.name,
                    item.target_id, item.sno, item.target_batch_no, item.target_expiry, v_material_conversion.date,
                    item.target_mrp, item.target_s_rate, item.target_nlc, item.target_cost, item.target_unit_id,
                    item.target_unit_conv, inv.manufacturer_id, inv.manufacturer_name, item.target_category1_id,
                    item.target_category2_id, item.target_category3_id, item.target_category4_id,
                    item.target_category5_id, item.target_category6_id, item.target_category7_id,
                    item.target_category8_id, item.target_category9_id, item.target_category10_id,
                    v_material_conversion.voucher_id, v_material_conversion.voucher_no, v_material_conversion.ref_no,
                    v_material_conversion.warehouse_id, war.name, 'MATERIAL_CONVERSION', v_material_conversion.id,
                    inv.loose_qty, item.target_qty * item.target_unit_conv)
            on conflict (txn_id) do update
                set inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    label_qty         = excluded.label_qty,
                    batch_no          = excluded.batch_no,
                    sno               = excluded.sno,
                    expiry            = excluded.expiry,
                    entry_date        = excluded.entry_date,
                    mrp               = excluded.mrp,
                    s_rate            = excluded.s_rate,
                    nlc               = excluded.nlc,
                    cost              = excluded.cost,
                    unit_conv         = excluded.unit_conv,
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
                    ref_no            = excluded.ref_no
            returning * into bat;
            if item.target_is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch_id, branch_name, division_id, division_name, batch_id, inventory_id,
                                inventory_name, manufacturer_id, manufacturer_name, inward, reorder_inventory_id, nlc,
                                category1_id, category1_name, category2_id, category2_name, category3_id,
                                category3_name, category4_id, category4_name, category5_id, category5_name,
                                category6_id, category6_name, category7_id, category7_name, category8_id,
                                category8_name, category9_id, category9_name, category10_id, category10_name,
                                voucher_id, voucher_no, voucher_type_id, base_voucher_type, ref_no,
                                inventory_voucher_id, warehouse_id, warehouse_name)
            values (item.target_id, v_material_conversion.date, v_material_conversion.branch_id,
                    v_material_conversion.branch_name, div.id, div.name, bat.id, item.target_inventory_id, inv.name,
                    inv.manufacturer_id, inv.manufacturer_name, item.target_qty * item.target_unit_conv * loose,
                    coalesce(inv.reorder_inventory_id, inv.id), item.target_nlc, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_material_conversion.voucher_id,
                    v_material_conversion.voucher_no, v_material_conversion.voucher_type_id,
                    v_material_conversion.base_voucher_type, v_material_conversion.ref_no, v_material_conversion.id,
                    war.id, war.name)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    inward            = excluded.inward,
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
            select *
            into bat
            from get_batch(batch := item.source_batch_id, inventory := item.source_inventory_id,
                           branch := v_voucher.branch_id, warehouse := war.id);
            select * into inv from inventory where id = item.source_inventory_id;
            if not FOUND then
                raise exception 'Invalid source inventory';
            end if;
            select * into div from division where id = inv.division_id;
            if not FOUND then
                raise exception 'internal err for source inventory division';
            end if;
            if item.source_is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch_id, branch_name, division_id, division_name, batch_id,
                                reorder_inventory_id, inventory_id, inventory_name, manufacturer_id, manufacturer_name,
                                outward, category1_id, category2_id, category3_id, category4_id, category5_id,
                                category6_id, category7_id, category8_id, category9_id, category10_id, category1_name,
                                category2_name, category3_name, category4_name, category5_name, category6_name,
                                category7_name, category8_name, category9_name, category10_name, voucher_id, voucher_no,
                                voucher_type_id, base_voucher_type, inventory_voucher_id, warehouse_id, warehouse_name)
            values (item.source_id, v_material_conversion.date, v_material_conversion.branch_id,
                    v_material_conversion.branch_name, div.id, div.name, item.source_batch_id,
                    coalesce(inv.reorder_inventory_id, inv.id), item.source_inventory_id, inv.name, inv.manufacturer_id,
                    inv.manufacturer_name, item.source_qty * item.source_unit_conv * loose, bat.category1_id,
                    bat.category2_id, bat.category3_id, bat.category4_id, bat.category5_id, bat.category6_id,
                    bat.category7_id, bat.category8_id, bat.category9_id, bat.category10_id, bat.category1_name,
                    bat.category2_name, bat.category3_name, bat.category4_name, bat.category5_name, bat.category6_name,
                    bat.category7_name, bat.category8_name, bat.category9_name, bat.category10_name,
                    v_material_conversion.voucher_id, v_material_conversion.voucher_no,
                    v_material_conversion.voucher_type_id, v_material_conversion.base_voucher_type,
                    v_material_conversion.id, war.id, war.name)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    outward           = excluded.outward,
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
    return v_material_conversion;
end;
$$ language plpgsql security definer;
--##
create function delete_material_conversion(id int)
    returns void as
$$
declare
    v_id int;
begin
    delete from material_conversion where material_conversion.id = $1 returning voucher_id into v_id;
    delete from voucher where voucher.id = v_id;
    if not FOUND then
        raise exception 'Invalid material_conversion';
    end if;
end;
$$ language plpgsql security definer;
