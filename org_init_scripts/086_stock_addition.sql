create table if not exists stock_addition
(
    id                int                   not null generated always as identity primary key,
    voucher           int                   not null,
    date              date                  not null,
    eff_date          date,
    branch            int                   not null,
    branch_name       text                  not null,
    warehouse         int                   not null,
    alt_branch        int,
    alt_warehouse     int,
    deduction_id      int,
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
create function create_stock_addition(
    date date,
    branch int,
    warehouse int,
    voucher_type int,
    inv_items jsonb,
    ac_trns jsonb,
    alt_branch int default null,
    alt_warehouse int default null,
    deduction_id int default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null,
    unique_session uuid default gen_random_uuid()
)
    returns stock_addition as
$$
declare
    v_stock_addition stock_addition;
    v_voucher        voucher;
    item             stock_addition_inv_item;
    items            stock_addition_inv_item[] := (select array_agg(x)
                                                   from jsonb_populate_recordset(
                                                                null::stock_addition_inv_item,
                                                                create_stock_addition.inv_items) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    loose            int;
begin
    if (create_stock_addition.branch = create_stock_addition.alt_branch) and
       (create_stock_addition.warehouse = create_stock_addition.alt_warehouse) then
        raise exception 'Same branch / warehouse not allowed';
    end if;
    if create_stock_addition.deduction_id is not null then
        update stock_deduction
        set approved = true
        where id = create_stock_addition.deduction_id
          and approved = false
          and stock_deduction.branch = create_stock_addition.alt_branch;
        if not FOUND then
            raise exception 'stock deduction voucher not found or already approved';
        end if;
    end if;
    select *
    into v_voucher
    FROM
        create_voucher(date := create_stock_addition.date, branch := create_stock_addition.branch,
                       voucher_type := create_stock_addition.voucher_type, ref_no := create_stock_addition.ref_no,
                       description := create_stock_addition.description, mode := 'INVENTORY',
                       amount := create_stock_addition.amount, ac_trns := create_stock_addition.ac_trns,
                       eff_date := create_stock_addition.eff_date,
                       unique_session := create_stock_addition.unique_session
        );
    if v_voucher.base_voucher_type != 'STOCK_ADDITION' then
        raise exception 'Allowed only STOCK_ADDITION voucher type';
    end if;
    select * into war from warehouse where id = create_stock_addition.warehouse;
    insert into stock_addition (voucher, date, eff_date, branch, branch_name, warehouse, alt_branch, alt_warehouse,
                                base_voucher_type, voucher_type, voucher_no, voucher_prefix, voucher_fy,
                                voucher_seq, ref_no, description, ac_trns, amount)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch, v_voucher.branch_name,
            create_stock_addition.warehouse, create_stock_addition.alt_branch, create_stock_addition.alt_warehouse,
            v_voucher.base_voucher_type, v_voucher.voucher_type,
            v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq,
            v_voucher.ref_no, v_voucher.description, create_stock_addition.ac_trns, create_stock_addition.amount)
    returning * into v_stock_addition;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into batch (txn_id, inventory, inventory_name, branch, branch_name, warehouse, warehouse_name,
                               division, division_name, entry_type, batch_no, inventory_voucher_id, expiry, entry_date,
                               mrp, s_rate, nlc, cost, unit_id, unit_conv, ref_no, manufacturer, manufacturer_name,
                               voucher, voucher_no, category1, category2, category3, category4, category5, category6,
                               category7, category8, category9, category10, barcode, loose_qty, label_qty)
            values (item.id, item.inventory, inv.name, create_stock_addition.branch,
                    v_stock_addition.branch_name, create_stock_addition.warehouse, war.name, div.id, div.name,
                    'STOCK_ADDITION', item.batch_no, v_stock_addition.id, item.expiry, v_stock_addition.date, item.mrp,
                    item.s_rate, item.nlc, item.cost, item.unit, item.unit_conv, v_stock_addition.ref_no,
                    inv.manufacturer, inv.manufacturer_name, v_stock_addition.voucher, v_stock_addition.voucher_no,
                    (item.category ->> 'category1')::int, (item.category ->> 'category2')::int,
                    (item.category ->> 'category3')::int, (item.category ->> 'category4')::int,
                    (item.category ->> 'category5')::int, (item.category ->> 'category6')::int,
                    (item.category ->> 'category7')::int, (item.category ->> 'category8')::int,
                    (item.category ->> 'category9')::int, (item.category ->> 'category10')::int, item.barcode,
                    inv.loose_qty, item.qty * item.unit_conv)
            returning * into bat;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, manufacturer, manufacturer_name,
                                asset_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name, inward, nlc)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    bat.id, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name,
                    inv.manufacturer, inv.manufacturer_name, item.asset_amount, v_voucher.ref_no, v_stock_addition.id,
                    v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type, v_voucher.base_voucher_type,
                    bat.category1, bat.category1_name, bat.category2, bat.category2_name, bat.category3,
                    bat.category3_name, bat.category4, bat.category4_name, bat.category5, bat.category5_name,
                    bat.category6, bat.category6_name, bat.category7, bat.category7_name, bat.category8,
                    bat.category8_name, bat.category9, bat.category9_name, bat.category10, bat.category10_name,
                    v_stock_addition.warehouse, war.name, item.qty * item.unit_conv * loose, item.nlc);
            insert into stock_addition_inv_item (id, stock_addition, inventory, unit, unit_conv, qty, cost,
                                                 barcode, is_loose_qty, asset_amount, mrp, s_rate, batch_no, expiry,
                                                 category, landing_cost)
            values (item.id, v_stock_addition.id, item.inventory, item.unit, item.unit_conv, item.qty, item.cost,
                    coalesce(item.barcode, bat.id::text), item.is_loose_qty, item.asset_amount, item.mrp,
                    item.s_rate, item.batch_no, item.expiry, item.category, item.landing_cost);
        end loop;
    return v_stock_addition;
end;
$$ language plpgsql security definer;
--##
create function update_stock_addition(
    v_id int,
    date date,
    inv_items jsonb,
    ac_trns jsonb,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null
)
    returns stock_addition AS
$$
declare
    v_stock_addition stock_addition;
    v_voucher        voucher;
    item             stock_addition_inv_item;
    items            stock_addition_inv_item[] := (select array_agg(x)
                                                   from jsonb_populate_recordset(
                                                                null::stock_addition_inv_item,
                                                                update_stock_addition.inv_items) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    loose            int;
    missed_items_ids uuid[];
begin
    update stock_addition
    set date        = update_stock_addition.date,
        eff_date    = update_stock_addition.eff_date,
        ref_no      = update_stock_addition.ref_no,
        description = update_stock_addition.description,
        amount      = update_stock_addition.amount,
        ac_trns     = update_stock_addition.ac_trns,
        updated_at  = current_timestamp
    where id = $1
    returning * into v_stock_addition;
    if not FOUND then
        raise exception 'stock_addition not found';
    end if;
    if v_stock_addition.deduction_id is not null then
        raise exception 'Approved voucher can not be updated';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_id := v_stock_addition.voucher, date := v_stock_addition.date,
                       ref_no := v_stock_addition.ref_no, description := v_stock_addition.description,
                       amount := v_stock_addition.amount, ac_trns := v_stock_addition.ac_trns,
                       eff_date := v_stock_addition.eff_date
        );
    select array_agg(id)
    into missed_items_ids
    from ((select id, inventory
           from stock_addition_inv_item
           where stock_addition = update_stock_addition.v_id)
          except
          (select id, inventory
           from unnest(items)));
    delete from stock_addition_inv_item where id = any (missed_items_ids);
    select * into war from warehouse where id = v_stock_addition.warehouse;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into batch (txn_id, inventory, inventory_name, branch, branch_name, warehouse, warehouse_name,
                               division, division_name, entry_type, batch_no, inventory_voucher_id, expiry, entry_date,
                               mrp, s_rate, nlc, cost, landing_cost, unit_id, unit_conv, ref_no, manufacturer,
                               manufacturer_name, voucher, voucher_no, category1, category2, category3, category4,
                               category5, category6, category7, category8, category9, category10, barcode, loose_qty,
                               label_qty)
            values (item.id, item.inventory, inv.name, v_stock_addition.branch, v_stock_addition.branch_name,
                    v_stock_addition.warehouse, war.name, div.id, div.name, 'STOCK_ADDITION', item.batch_no,
                    v_stock_addition.id, item.expiry, v_stock_addition.date, item.mrp, item.s_rate, item.nlc, item.cost,
                    item.landing_cost, item.unit, item.unit_conv, v_stock_addition.ref_no, inv.manufacturer,
                    inv.manufacturer_name, v_stock_addition.voucher, v_stock_addition.voucher_no,
                    (item.category ->> 'category1')::int, (item.category ->> 'category2')::int,
                    (item.category ->> 'category3')::int, (item.category ->> 'category4')::int,
                    (item.category ->> 'category5')::int, (item.category ->> 'category6')::int,
                    (item.category ->> 'category7')::int, (item.category ->> 'category8')::int,
                    (item.category ->> 'category9')::int, (item.category ->> 'category10')::int, item.barcode,
                    inv.loose_qty, item.qty * item.unit_conv)
            on conflict (txn_id) do update
                set inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    batch_no          = excluded.batch_no,
                    expiry            = excluded.expiry,
                    entry_date        = excluded.entry_date,
                    label_qty         = excluded.label_qty,
                    mrp               = excluded.mrp,
                    s_rate            = excluded.s_rate,
                    nlc               = excluded.nlc,
                    cost              = excluded.cost,
                    landing_cost      = excluded.landing_cost,
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
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, manufacturer, manufacturer_name,
                                inward, asset_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    bat.id, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name,
                    inv.manufacturer, inv.manufacturer_name, item.qty * item.unit_conv * loose, item.asset_amount,
                    v_voucher.ref_no, v_stock_addition.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type,
                    v_voucher.base_voucher_type, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, v_stock_addition.warehouse, war.name)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
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
            insert into stock_addition_inv_item (id, stock_addition, inventory, unit, unit_conv, qty, cost,
                                                 landing_cost, barcode, is_loose_qty, asset_amount, mrp, s_rate,
                                                 batch_no, expiry, category)
            values (item.id, v_stock_addition.id, item.inventory, item.unit, item.unit_conv, item.qty, item.cost,
                    item.landing_cost, coalesce(item.barcode, bat.id::text), item.is_loose_qty, item.asset_amount,
                    item.mrp, item.s_rate, item.batch_no, item.expiry, item.category)
            on conflict (id) do update
                set unit         = excluded.unit,
                    unit_conv    = excluded.unit_conv,
                    qty          = excluded.qty,
                    mrp          = excluded.mrp,
                    s_rate       = excluded.s_rate,
                    batch_no     = excluded.batch_no,
                    expiry       = excluded.expiry,
                    category     = excluded.category,
                    is_loose_qty = excluded.is_loose_qty,
                    cost         = excluded.cost,
                    asset_amount = excluded.asset_amount;
        end loop;
    return v_stock_addition;
end;
$$ language plpgsql security definer;
--##
create function delete_stock_addition(v_id int)
    returns void as
$$
declare
    v_stock_addition stock_addition;
begin
    delete from stock_addition where id = $1 returning * into v_stock_addition;
    if v_stock_addition.deduction_id is not null then
        raise exception 'Approved voucher can not be deleted';
    end if;
    delete from voucher where id = v_stock_addition.voucher;
    if not FOUND then
        raise exception 'Invalid stock_addition';
    end if;
end;
$$ language plpgsql security definer;