create table if not exists personal_use_purchase
(
    id                int                   not null generated always as identity primary key,
    voucher           int                   not null,
    date              date                  not null,
    eff_date          date,
    branch            int                   not null,
    branch_gst        json                  not null,
    warehouse         int                   not null,
    branch_name       text                  not null,
    base_voucher_type typ_base_voucher_type not null,
    voucher_type      int                   not null,
    voucher_no        text                  not null,
    voucher_prefix    text                  not null,
    voucher_fy        int                   not null,
    voucher_seq       int                   not null,
    ref_no            text,
    description       text,
    expense_account   int,
    ac_trns           jsonb,
    amount            float,
    created_at        timestamp             not null default current_timestamp,
    updated_at        timestamp             not null default current_timestamp
);
--##
create function create_personal_use_purchase(
    date date,
    branch int,
    branch_gst json,
    warehouse int,
    voucher_type int,
    inv_items jsonb,
    ac_trns jsonb,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    expense_account int default null,
    amount float default null,
    unique_session uuid default gen_random_uuid()
)
    returns personal_use_purchase as
$$
declare
    v_personal_use_purchase personal_use_purchase;
    v_voucher               voucher;
    item                    personal_use_purchase_inv_item;
    items                   personal_use_purchase_inv_item[] := (select array_agg(x)
                                                                 from jsonb_populate_recordset(
                                                                              null::personal_use_purchase_inv_item,
                                                                              create_personal_use_purchase.inv_items) as x);
    inv                     inventory;
    bat                     batch;
    div                     division;
    war                     warehouse;
    loose                   int;
begin
    select *
    into v_voucher
    from
        create_voucher(date := create_personal_use_purchase.date, branch := create_personal_use_purchase.branch,
                       branch_gst := create_personal_use_purchase.branch_gst,
                       voucher_type := create_personal_use_purchase.voucher_type,
                       ref_no := create_personal_use_purchase.ref_no,
                       description := create_personal_use_purchase.description, mode := 'INVENTORY',
                       amount := create_personal_use_purchase.amount, ac_trns := create_personal_use_purchase.ac_trns,
                       eff_date := create_personal_use_purchase.eff_date,
                       unique_session := create_personal_use_purchase.unique_session
        );
    if v_voucher.base_voucher_type != 'PERSONAL_USE_PURCHASE' then
        raise exception 'Allowed only PERSONAL_USE_PURCHASE voucher type';
    end if;
    select * into war from warehouse where id = create_personal_use_purchase.warehouse;
    insert into personal_use_purchase (voucher, date, eff_date, branch, branch_name, branch_gst, warehouse,
                                       base_voucher_type, voucher_type, voucher_prefix, voucher_fy, voucher_seq,
                                       voucher_no, ref_no, description, ac_trns, amount, expense_account)
    values (v_voucher.id, create_personal_use_purchase.date, create_personal_use_purchase.eff_date,
            create_personal_use_purchase.branch, v_voucher.branch_name, create_personal_use_purchase.branch_gst,
            create_personal_use_purchase.warehouse, v_voucher.base_voucher_type,
            create_personal_use_purchase.voucher_type, v_voucher.voucher_prefix, v_voucher.voucher_fy,
            v_voucher.voucher_seq, v_voucher.voucher_no, create_personal_use_purchase.ref_no,
            create_personal_use_purchase.description, create_personal_use_purchase.ac_trns,
            create_personal_use_purchase.amount, create_personal_use_purchase.expense_account)
    returning * into v_personal_use_purchase;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select *
            into bat
            from get_batch(v_bat := item.batch, v_inv := item.inventory, v_br := v_voucher.branch,
                           v_war := v_personal_use_purchase.warehouse);
            select * into div from division where id = inv.division;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, inventory_hsn, manufacturer, manufacturer_name,
                                inward, outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    item.batch, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name, inv.hsn_code,
                    inv.manufacturer, inv.manufacturer_name, -(item.qty * item.unit_conv * loose),
                    0, item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_personal_use_purchase.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type, v_voucher.base_voucher_type, bat.category1, bat.category1_name,
                    bat.category2, bat.category2_name, bat.category3, bat.category3_name, bat.category4,
                    bat.category4_name, bat.category5, bat.category5_name, bat.category6, bat.category6_name,
                    bat.category7, bat.category7_name, bat.category8, bat.category8_name, bat.category9,
                    bat.category9_name, bat.category10, bat.category10_name, v_personal_use_purchase.warehouse,
                    war.name);
            insert into personal_use_purchase_inv_item (id, personal_use_purchase, batch, inventory, unit, unit_conv,
                                                        gst_tax, qty, cost, is_loose_qty, hsn_code, cess_on_qty,
                                                        cess_on_val, taxable_amount, asset_amount, cgst_amount,
                                                        sgst_amount, igst_amount, cess_amount)
            values (item.id, v_personal_use_purchase.id, item.batch, item.inventory, item.unit, item.unit_conv,
                    item.gst_tax, item.qty, item.cost, item.is_loose_qty, item.hsn_code, item.cess_on_qty,
                    item.cess_on_val, item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount,
                    item.igst_amount, item.cess_amount);
        end loop;
    return v_personal_use_purchase;
end;
$$ language plpgsql security definer;
--##
create function update_personal_use_purchase(
    v_id int,
    date date,
    inv_items jsonb,
    ac_trns jsonb,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    expense_account int default null,
    amount float default null
)
    returns personal_use_purchase as
$$
declare
    v_personal_use_purchase personal_use_purchase;
    v_voucher               voucher;
    item                    personal_use_purchase_inv_item;
    items                   personal_use_purchase_inv_item[] := (select array_agg(x)
                                                                 from jsonb_populate_recordset(
                                                                              null::personal_use_purchase_inv_item,
                                                                              update_personal_use_purchase.inv_items) x);
    inv                     inventory;
    bat                     batch;
    div                     division;
    war                     warehouse;
    missed_items_ids        uuid[];
    loose                   int;
begin
    update personal_use_purchase
    set date            = update_personal_use_purchase.date,
        eff_date        = update_personal_use_purchase.eff_date,
        ref_no          = update_personal_use_purchase.ref_no,
        description     = update_personal_use_purchase.description,
        amount          = update_personal_use_purchase.amount,
        ac_trns         = update_personal_use_purchase.ac_trns,
        expense_account = update_personal_use_purchase.expense_account,
        updated_at      = current_timestamp
    where id = $1
    returning * into v_personal_use_purchase;
    select *
    into v_voucher
    from
        update_voucher(v_id := v_personal_use_purchase.voucher, date := v_personal_use_purchase.date,
                       ref_no := v_personal_use_purchase.ref_no, description := v_personal_use_purchase.description,
                       amount := v_personal_use_purchase.amount, ac_trns := v_personal_use_purchase.ac_trns,
                       eff_date := v_personal_use_purchase.eff_date, branch_gst := v_personal_use_purchase.branch_gst);
    select * into war from warehouse where id = v_personal_use_purchase.warehouse;
    select array_agg(id)
    into missed_items_ids
    from ((select id, batch
           from personal_use_purchase_inv_item
           where personal_use_purchase = v_personal_use_purchase.id)
          except
          (select id, batch
           from unnest(items)));
    delete from personal_use_purchase_inv_item where id = ANY (missed_items_ids);
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select *
            into bat
            from get_batch(v_bat := item.batch, v_inv := item.inventory, v_br := v_voucher.branch,
                           v_war := v_personal_use_purchase.warehouse);
            select * into div from division where id = inv.division;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, inventory_hsn, manufacturer, manufacturer_name,
                                inward, outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    item.batch, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name, inv.hsn_code,
                    inv.manufacturer, inv.manufacturer_name, -(item.qty * item.unit_conv * loose),
                    0, item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_personal_use_purchase.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type, v_voucher.base_voucher_type, bat.category1, bat.category1_name,
                    bat.category2, bat.category2_name, bat.category3, bat.category3_name, bat.category4,
                    bat.category4_name, bat.category5, bat.category5_name, bat.category6, bat.category6_name,
                    bat.category7, bat.category7_name, bat.category8, bat.category8_name, bat.category9,
                    bat.category9_name, bat.category10, bat.category10_name, v_personal_use_purchase.warehouse,
                    war.name)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    warehouse_name    = excluded.warehouse_name,
                    division_name     = excluded.division_name,
                    inward            = excluded.inward,
                    taxable_amount    = excluded.taxable_amount,
                    sgst_amount       = excluded.sgst_amount,
                    cgst_amount       = excluded.cgst_amount,
                    igst_amount       = excluded.igst_amount,
                    cess_amount       = excluded.cess_amount,
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
            insert into personal_use_purchase_inv_item (id, personal_use_purchase, batch, inventory, unit, unit_conv,
                                                        gst_tax, qty, cost, is_loose_qty, hsn_code, cess_on_qty,
                                                        cess_on_val, taxable_amount, asset_amount, cgst_amount,
                                                        sgst_amount, igst_amount, cess_amount)
            values (item.id, v_personal_use_purchase.id, item.batch, item.inventory, item.unit, item.unit_conv,
                    item.gst_tax, item.qty, item.cost, item.is_loose_qty, item.hsn_code, item.cess_on_qty,
                    item.cess_on_val, item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount,
                    item.igst_amount, item.cess_amount)
            on conflict (id) do update
                set unit           = excluded.unit,
                    unit_conv      = excluded.unit_conv,
                    qty            = excluded.qty,
                    is_loose_qty   = excluded.is_loose_qty,
                    cost           = excluded.cost,
                    gst_tax        = excluded.gst_tax,
                    cess_on_val    = excluded.cess_on_val,
                    cess_on_qty    = excluded.cess_on_qty,
                    taxable_amount = excluded.taxable_amount,
                    cgst_amount    = excluded.cgst_amount,
                    sgst_amount    = excluded.sgst_amount,
                    igst_amount    = excluded.igst_amount,
                    cess_amount    = excluded.cess_amount;
        end loop;
    return v_personal_use_purchase;
end;
$$ language plpgsql security definer;
--##
create function delete_personal_use_purchase(v_id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from personal_use_purchase where id = $1 returning voucher into voucher_id;
    delete from voucher where id = voucher_id;
    if not FOUND then
        raise exception 'Invalid personal_use_purchase';
    end if;
end;
$$ language plpgsql security definer;