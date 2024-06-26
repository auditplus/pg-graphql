create table if not exists debit_note
(
    id                       int                   not null generated always as identity primary key,
    voucher_id               int                   not null,
    date                     date                  not null,
    eff_date                 date,
    branch_id                int                   not null,
    warehouse_id             int                   not null,
    purchase_bill_voucher_id int unique,
    purchase_bill_no         text,
    branch_name              text                  not null,
    base_voucher_type        typ_base_voucher_type not null,
    purchase_mode            typ_purchase_mode     not null default 'CASH',
    voucher_type_id          int                   not null,
    voucher_no               text                  not null,
    voucher_prefix           text                  not null,
    voucher_fy               int                   not null,
    voucher_seq              int                   not null,
    rcm                      boolean               not null default false,
    ref_no                   text,
    vendor_id                int,
    vendor_name              text,
    description              text,
    branch_gst               json                  not null,
    party_gst                json,
    party_account_id         int,
    party_name               text,
    amount                   float,
    discount_amount          float,
    rounded_off              float,
    created_at               timestamp             not null default current_timestamp,
    updated_at               timestamp             not null default current_timestamp
);
--##
create function create_debit_note(
    input_data json,
    unique_session uuid default null
)
    returns debit_note AS
$$
declare
    input        jsonb                 := json_convert_case($1::jsonb, 'snake_case');
    v_debit_note debit_note;
    v_voucher    voucher;
    item         debit_note_inv_item;
    items        debit_note_inv_item[] := (select array_agg(x)
                                           from jsonb_populate_recordset(
                                                        null::debit_note_inv_item,
                                                        (input ->> 'inv_items')::jsonb) as x);
    inv          inventory;
    bat          batch;
    div          division;
    war          warehouse             := (select warehouse
                                           from warehouse
                                           where id = (input ->> 'warehouse_id')::int);
    ven          account               := (select account
                                           from account
                                           where id = (input ->> 'vendor_id')::int
                                             and contact_type = 'VENDOR');
    loose        int;
begin
    input = jsonb_set(input, '{mode}', '"INVENTORY"');
    input = jsonb_set(input, '{rcm}', coalesce((input ->> 'rcm')::bool, false)::text::jsonb);
    select * into v_voucher from create_voucher(input::json, $2);
    if v_voucher.base_voucher_type != 'DEBIT_NOTE' then
        raise exception 'Allowed only SALE voucher type';
    end if;
    insert into debit_note (voucher_id, date, eff_date, branch_id, branch_name, warehouse_id, base_voucher_type,
                            voucher_type_id, voucher_no, voucher_prefix, voucher_fy, voucher_seq, rcm, ref_no,
                            purchase_bill_voucher_id, purchase_bill_no, vendor_id, vendor_name, description, branch_gst,
                            party_gst, purchase_mode, amount, discount_amount, rounded_off, party_account_id)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name, war.id,
            v_voucher.base_voucher_type, v_voucher.voucher_type_id, v_voucher.voucher_no, v_voucher.voucher_prefix,
            v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.rcm, v_voucher.ref_no,
            (input ->> 'purchase_bill_voucher_id')::int, (input ->> 'purchase_bill_no')::text, ven.id, ven.name,
            v_voucher.description, v_voucher.branch_gst, v_voucher.party_gst,
            (input ->> 'purchase_mode')::text::typ_purchase_mode, v_voucher.amount,
            (input ->> 'discount_amount')::float, (input ->> 'rounded_off')::float, (input ->> 'party_account_id')::int)
    returning * into v_debit_note;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select * into div from division where id = inv.division_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_voucher.branch_id,
                           warehouse := v_debit_note.warehouse_id);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into debit_note_inv_item (id, debit_note_id, batch_id, inventory_id, unit_id, unit_conv, gst_tax_id,
                                             qty, is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc1_mode,
                                             discount1, disc2_mode, discount2, taxable_amount, asset_amount,
                                             cgst_amount, sgst_amount, igst_amount, cess_amount)
            values (coalesce(item.id, gen_random_uuid()), v_debit_note.id, item.batch_id, item.inventory_id,
                    item.unit_id, item.unit_conv, item.gst_tax_id, item.qty, item.is_loose_qty, item.rate,
                    item.hsn_code, item.cess_on_qty, item.cess_on_val, item.disc1_mode, item.discount1, item.disc2_mode,
                    item.discount2, item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount,
                    item.igst_amount, item.cess_amount)
            returning * into item;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                inward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, party_id, party_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, -(item.qty * item.unit_conv * loose),
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_debit_note.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_debit_note.warehouse_id, war.name,
                    ven.id, ven.name);
        end loop;
    return v_debit_note;
end;
$$ language plpgsql security definer;
--##

--##
create function delete_debit_note(id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from debit_note where debit_note.id = $1 returning voucher_id into voucher_id;
    delete from voucher where voucher.id = voucher_id;
    if not FOUND then
        raise exception 'Invalid debit_note';
    end if;
end;
$$ language plpgsql;
