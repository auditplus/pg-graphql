create table if not exists debit_note
(
    id                int                   not null generated always as identity primary key,
    voucher           int                   not null,
    date              date                  not null,
    eff_date          date,
    branch            int                   not null,
    warehouse         int                   not null,
    purchase_bill     int,
    purchase_bill_no  text,
    branch_name       text                  not null,
    base_voucher_type typ_base_voucher_type not null,
    purchase_mode     typ_purchase_mode     not null default 'CASH',
    voucher_type      int                   not null,
    voucher_no        text                  not null,
    voucher_prefix    text                  not null,
    voucher_fy        int                   not null,
    voucher_seq       int                   not null,
    rcm               boolean               not null default false,
    ref_no            text,
    vendor            int,
    vendor_name       text,
    description       text,
    branch_gst        json                  not null,
    party_gst         json,
    party_account     int,
    party_name        text,
    ac_trns           jsonb,
    amount            float,
    discount_amount   float,
    rounded_off       float,
    created_at        timestamp             not null default current_timestamp,
    updated_at        timestamp             not null default current_timestamp
);
--##
create function create_debit_note(
    date date,
    branch int,
    warehouse int,
    voucher_type int,
    inv_items jsonb,
    ac_trns jsonb,
    branch_gst json,
    purchase_mode text,
    party_account int,
    party_gst json default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null,
    discount_amount float default null,
    rounded_off float default null,
    vendor int default null,
    purchase_bill int default null,
    purchase_bill_no text default null,
    rcm boolean default false,
    unique_session uuid default gen_random_uuid()
)
    returns debit_note AS
$$
declare
    v_debit_note debit_note;
    v_voucher    voucher;
    item         debit_note_inv_item;
    items        debit_note_inv_item[] := (select array_agg(x)
                                           from jsonb_populate_recordset(
                                                        null::debit_note_inv_item,
                                                        create_debit_note.inv_items) as x);
    inv          inventory;
    bat          batch;
    div          division;
    war          warehouse;
    ven          vendor;
    loose        int;
    v_purchase_mode typ_purchase_mode := create_debit_note.purchase_mode::typ_purchase_mode;
begin
    select *
    into v_voucher
    FROM
        create_voucher(date := create_debit_note.date, branch := create_debit_note.branch,
                       branch_gst := create_debit_note.branch_gst,
                       party_gst := create_debit_note.party_gst,
                       voucher_type := create_debit_note.voucher_type,
                       ref_no := create_debit_note.ref_no,
                       party := create_debit_note.party_account,
                       description := create_debit_note.description, mode := 'INVENTORY',
                       amount := create_debit_note.amount, ac_trns := create_debit_note.ac_trns,
                       eff_date := create_debit_note.eff_date, rcm := create_debit_note.rcm,
                       unique_session := create_debit_note.unique_session
        );
    if v_voucher.base_voucher_type != 'DEBIT_NOTE' then
        raise exception 'Allowed only SALE voucher type';
    end if;
    select * into war from warehouse where id = create_debit_note.warehouse;
    select * into ven from vendor where id = create_debit_note.vendor;
    insert into debit_note (voucher, date, eff_date, branch, branch_name, warehouse, base_voucher_type, voucher_type,
                            voucher_no, voucher_prefix, voucher_fy, voucher_seq, rcm, ref_no, purchase_bill,
                            purchase_bill_no, vendor, vendor_name, description, branch_gst, party_gst, purchase_mode,
                            ac_trns, amount, discount_amount, rounded_off, party_account)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch, v_voucher.branch_name,
            create_debit_note.warehouse, v_voucher.base_voucher_type, v_voucher.voucher_type, v_voucher.voucher_no,
            v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.rcm, v_voucher.ref_no,
            create_debit_note.purchase_bill, create_debit_note.purchase_bill_no, create_debit_note.vendor, ven.name,
            v_voucher.description, v_voucher.branch_gst, v_voucher.party_gst, v_purchase_mode,
            create_debit_note.ac_trns, create_debit_note.amount, create_debit_note.discount_amount,
            create_debit_note.rounded_off, create_debit_note.party_account)
    returning * into v_debit_note;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            select *
            into bat
            from get_batch(v_bat := item.batch, v_inv := item.inventory, v_br := v_voucher.branch,
                           v_war := v_debit_note.warehouse);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, inventory_hsn, manufacturer, manufacturer_name,
                                inward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name,
                                vendor, vendor_name)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    item.batch, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name, inv.hsn_code,
                    inv.manufacturer, inv.manufacturer_name, -(item.qty * item.unit_conv * loose), item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    v_voucher.ref_no, v_debit_note.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type,
                    v_voucher.base_voucher_type, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, v_debit_note.warehouse, war.name, ven.id, ven.name);
            insert into debit_note_inv_item (id, debit_note, batch, inventory, unit, unit_conv, gst_tax, qty,
                                             is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc1_mode,
                                             discount1, disc2_mode, discount2, taxable_amount, asset_amount,
                                             cgst_amount, sgst_amount, igst_amount, cess_amount)
            values (item.id, v_debit_note.id, item.batch, item.inventory, item.unit, item.unit_conv, item.gst_tax,
                    item.qty, item.is_loose_qty, item.rate, item.hsn_code, item.cess_on_qty, item.cess_on_val,
                    item.disc1_mode, item.discount1, item.disc2_mode, item.discount2, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount);
        end loop;
    return v_debit_note;
end;
$$ language plpgsql security definer;
--##
create function update_debit_note(
    v_id int,
    date date,
    inv_items jsonb,
    ac_trns jsonb,
    party_gst json default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null,
    discount_amount float default null,
    rounded_off float default null,
    vendor int default null,
    rcm boolean default false
)
    returns debit_note AS
$$
declare
    v_debit_note     debit_note;
    v_voucher        voucher;
    item             debit_note_inv_item;
    items            debit_note_inv_item[] := (select array_agg(x)
                                               from jsonb_populate_recordset(
                                                            null::debit_note_inv_item,
                                                            update_debit_note.inv_items) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    ven              vendor;
    loose            int;
    missed_items_ids uuid[];
begin
    select * into ven from vendor where id = update_debit_note.vendor;
    update debit_note
    set date            = update_debit_note.date,
        eff_date        = update_debit_note.eff_date,
        ref_no          = update_debit_note.ref_no,
        description     = update_debit_note.description,
        amount          = update_debit_note.amount,
        ac_trns         = update_debit_note.ac_trns,
        vendor          = update_debit_note.vendor,
        vendor_name     = ven.name,
        party_gst       = update_debit_note.party_gst,
        discount_amount = update_debit_note.discount_amount,
        rounded_off     = update_debit_note.rounded_off,
        rcm             = update_debit_note.rcm,
        updated_at      = current_timestamp
    where id = $1
    returning * into v_debit_note;
    if not FOUND then
        raise exception 'Debit Note not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_id := v_debit_note.voucher, date := v_debit_note.date,
                       branch_gst := v_debit_note.branch_gst, party := v_debit_note.party_account,
                       party_gst := v_debit_note.party_gst, ref_no := v_debit_note.ref_no,
                       description := v_debit_note.description, amount := v_debit_note.amount,
                       ac_trns := v_debit_note.ac_trns, eff_date := v_debit_note.eff_date,
                       rcm := v_debit_note.rcm
        );
    select array_agg(id)
    into missed_items_ids
    from ((select id, inventory, batch
           from debit_note_inv_item
           where debit_note = update_debit_note.v_id)
          except
          (select id, inventory, batch
           from unnest(items)));
    delete from debit_note_inv_item where id = any (missed_items_ids);
    select * into war from warehouse where id = v_debit_note.warehouse;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            select *
            into bat
            from get_batch(v_bat := item.batch, v_inv := item.inventory, v_br := v_debit_note.branch,
                           v_war := v_debit_note.warehouse);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, inventory_hsn, manufacturer, manufacturer_name,
                                outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name,
                                vendor, vendor_name)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    item.batch, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name, inv.hsn_code,
                    inv.manufacturer, inv.manufacturer_name, item.qty * item.unit_conv * loose, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    v_voucher.ref_no, v_debit_note.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type,
                    v_voucher.base_voucher_type, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, v_debit_note.warehouse, war.name, v_debit_note.vendor, ven.name)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    outward           = excluded.outward,
                    taxable_amount    = excluded.taxable_amount,
                    sgst_amount       = excluded.sgst_amount,
                    cgst_amount       = excluded.cgst_amount,
                    igst_amount       = excluded.igst_amount,
                    cess_amount       = excluded.cess_amount,
                    asset_amount      = excluded.asset_amount,
                    manufacturer      = excluded.manufacturer,
                    manufacturer_name = excluded.manufacturer_name,
                    vendor            = excluded.vendor,
                    vendor_name       = excluded.vendor_name,
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
            insert into debit_note_inv_item (id, debit_note, batch, inventory, unit, unit_conv, gst_tax, qty,
                                             is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc1_mode,
                                             discount1, disc2_mode, discount2, taxable_amount, asset_amount,
                                             cgst_amount, sgst_amount, igst_amount, cess_amount)
            values (item.id, v_debit_note.id, item.batch, item.inventory, item.unit, item.unit_conv, item.gst_tax,
                    item.qty, item.is_loose_qty, item.rate, item.hsn_code, item.cess_on_qty, item.cess_on_val,
                    item.disc1_mode, item.discount1, item.disc2_mode, item.discount2, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount)
            on conflict (id) do update
                set unit           = excluded.unit,
                    unit_conv      = excluded.unit_conv,
                    gst_tax        = excluded.gst_tax,
                    qty            = excluded.qty,
                    is_loose_qty   = excluded.is_loose_qty,
                    rate           = excluded.rate,
                    hsn_code       = excluded.hsn_code,
                    disc1_mode     = excluded.disc1_mode,
                    discount1      = excluded.discount1,
                    disc2_mode     = excluded.disc2_mode,
                    discount2      = excluded.discount2,
                    cess_on_val    = excluded.cess_on_val,
                    cess_on_qty    = excluded.cess_on_qty,
                    taxable_amount = excluded.taxable_amount,
                    cgst_amount    = excluded.cgst_amount,
                    sgst_amount    = excluded.sgst_amount,
                    igst_amount    = excluded.igst_amount,
                    cess_amount    = excluded.cess_amount;
        end loop;
    return v_debit_note;
end;
$$ language plpgsql;
--##
create function delete_debit_note(v_id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from debit_note where id = $1 returning voucher into voucher_id;
    delete from voucher where id = voucher_id;
    if not FOUND then
        raise exception 'Invalid debit_note';
    end if;
end;
$$ language plpgsql;
