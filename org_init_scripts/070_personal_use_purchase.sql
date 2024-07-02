create table if not exists personal_use_purchase
(
    id                 int                   not null generated always as identity primary key,
    voucher_id         int                   not null,
    date               date                  not null,
    eff_date           date,
    branch_id          int                   not null,
    branch_gst         json                  not null,
    warehouse_id       int                   not null,
    branch_name        text                  not null,
    base_voucher_type  typ_base_voucher_type not null,
    voucher_type_id    int                   not null,
    voucher_no         text                  not null,
    voucher_prefix     text                  not null,
    voucher_fy         int                   not null,
    voucher_seq        int                   not null,
    ref_no             text,
    description        text,
    expense_account_id int,
    amount             float,
    created_at         timestamp             not null default current_timestamp,
    updated_at         timestamp             not null default current_timestamp
);
--##
create function create_personal_use_purchase(input_data json, unique_session uuid default null)
    returns personal_use_purchase as
$$
declare
    v_personal_use_purchase personal_use_purchase;
    v_voucher               voucher;
    item                    personal_use_purchase_inv_item;
    items                   personal_use_purchase_inv_item[] := (select array_agg(x)
                                                                 from jsonb_populate_recordset(
                                                                              null::personal_use_purchase_inv_item,
                                                                              ($1 ->> 'inv_items')::jsonb) as x);
    inv                     inventory;
    bat                     batch;
    div                     division;
    war                     warehouse                        := (select warehouse
                                                                 from warehouse
                                                                 where id = ($1 ->> 'warehouse_id')::int);
    loose                   int;
begin
    $1 = jsonb_set($1::jsonb, '{mode}', '"INVENTORY"');
    select * into v_voucher from create_voucher($1, $2);
    if v_voucher.base_voucher_type != 'PERSONAL_USE_PURCHASE' then
        raise exception 'Allowed only PERSONAL_USE_PURCHASE voucher type';
    end if;
    insert into personal_use_purchase (voucher_id, date, eff_date, branch_id, branch_name, branch_gst, warehouse_id,
                                       base_voucher_type, voucher_type_id, voucher_prefix, voucher_fy, voucher_seq,
                                       voucher_no, ref_no, description, amount, expense_account_id)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name,
            v_voucher.branch_gst, war.id, v_voucher.base_voucher_type, v_voucher.voucher_type_id,
            v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.voucher_no,
            v_voucher.ref_no, v_voucher.description, v_voucher.amount, ($1 ->> 'expense_account_id')::int)
    returning * into v_personal_use_purchase;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_voucher.branch_id,
                           warehouse := v_personal_use_purchase.warehouse_id);
            select * into div from division where id = inv.division_id;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into personal_use_purchase_inv_item (id, personal_use_purchase_id, batch_id, inventory_id, unit_id,
                                                        unit_conv, gst_tax_id, qty, cost, is_loose_qty, hsn_code,
                                                        cess_on_qty, cess_on_val, taxable_amount, asset_amount,
                                                        cgst_amount, sgst_amount, igst_amount, cess_amount)
            values (coalesce(item.id, gen_random_uuid()), v_personal_use_purchase.id, item.batch_id, item.inventory_id,
                    item.unit_id, item.unit_conv, item.gst_tax_id, item.qty, item.cost, item.is_loose_qty,
                    item.hsn_code, item.cess_on_qty, item.cess_on_val, item.taxable_amount, item.asset_amount,
                    item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount)
            returning * into item;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                inward, outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, -(item.qty * item.unit_conv * loose), 0,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_personal_use_purchase.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_personal_use_purchase.warehouse_id,
                    war.name);
        end loop;
    return v_personal_use_purchase;
end;
$$ language plpgsql security definer;
--##
create function update_personal_use_purchase(v_id int, input_data json)
    returns personal_use_purchase as
$$
declare
    v_personal_use_purchase personal_use_purchase;
    v_voucher               voucher;
    item                    personal_use_purchase_inv_item;
    items                   personal_use_purchase_inv_item[] := (select array_agg(x)
                                                                 from jsonb_populate_recordset(
                                                                              null::personal_use_purchase_inv_item,
                                                                              ($2 ->> 'inv_items')::jsonb) x);
    inv                     inventory;
    bat                     batch;
    div                     division;
    war                     warehouse;
    missed_items_ids        uuid[];
    loose                   int;
begin
    update personal_use_purchase
    set date               = ($2 ->> 'date')::date,
        eff_date           = ($2 ->> 'eff_date')::date,
        ref_no             = ($2 ->> 'ref_no')::text,
        description        = ($2 ->> 'description')::text,
        amount             = ($2 ->> 'amount')::float,
        expense_account_id = ($2 ->> 'expense_account_id')::int,
        updated_at         = current_timestamp
    where id = $1
    returning * into v_personal_use_purchase;
    if not FOUND then
        raise exception 'personal_use_purchase not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_personal_use_purchase.voucher_id, $2);
    select array_agg(id)
    into missed_items_ids
    from ((select id, batch_id
           from personal_use_purchase_inv_item
           where personal_use_purchase_id = v_personal_use_purchase.id)
          except
          (select id, batch_id
           from unnest(items)));
    delete from personal_use_purchase_inv_item where id = ANY (missed_items_ids);
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_voucher.branch_id,
                           warehouse := v_personal_use_purchase.warehouse_id);
            select * into div from division where id = inv.division_id;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into personal_use_purchase_inv_item (id, personal_use_purchase_id, batch_id, inventory_id, unit_id,
                                                        unit_conv, gst_tax_id, qty, cost, is_loose_qty, hsn_code,
                                                        cess_on_qty, cess_on_val, taxable_amount, asset_amount,
                                                        cgst_amount, sgst_amount, igst_amount, cess_amount)
            values (coalesce(item.id, gen_random_uuid()), v_personal_use_purchase.id, item.batch_id, item.inventory_id,
                    item.unit_id, item.unit_conv, item.gst_tax_id, item.qty, item.cost, item.is_loose_qty,
                    item.hsn_code, item.cess_on_qty, item.cess_on_val, item.taxable_amount, item.asset_amount,
                    item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount)
            on conflict (id) do update
                set unit_id        = excluded.unit_id,
                    unit_conv      = excluded.unit_conv,
                    qty            = excluded.qty,
                    is_loose_qty   = excluded.is_loose_qty,
                    cost           = excluded.cost,
                    gst_tax_id     = excluded.gst_tax_id,
                    cess_on_val    = excluded.cess_on_val,
                    cess_on_qty    = excluded.cess_on_qty,
                    taxable_amount = excluded.taxable_amount,
                    cgst_amount    = excluded.cgst_amount,
                    sgst_amount    = excluded.sgst_amount,
                    igst_amount    = excluded.igst_amount,
                    cess_amount    = excluded.cess_amount;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                inward, outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, -(item.qty * item.unit_conv * loose),
                    0, item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_personal_use_purchase.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_personal_use_purchase.warehouse_id,
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
    return v_personal_use_purchase;
end ;
$$ language plpgsql security definer;
--##
create function delete_personal_use_purchase(id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from personal_use_purchase where personal_use_purchase.id = $1 returning voucher_id into voucher_id;
    delete from voucher where voucher.id = voucher_id;
    if not FOUND then
        raise exception 'Invalid personal_use_purchase';
    end if;
end;
$$ language plpgsql security definer;