create table if not exists credit_note
(
    id                   int       not null generated always as identity primary key,
    voucher_id           int       not null,
    date                 date      not null,
    eff_date             date,
    sale_bill_voucher_id int unique,
    branch_id            int       not null,
    warehouse_id         int       not null,
    branch_name          text      not null,
    base_voucher_type    text      not null,
    voucher_type_id      int       not null,
    voucher_no           text      not null,
    voucher_prefix       text      not null,
    voucher_fy           int       not null,
    voucher_seq          int       not null,
    lut                  boolean   not null default false,
    ref_no               text,
    customer_id          int,
    customer_name        text,
    description          text,
    branch_gst           json      not null,
    party_gst            json,
    bank_account_id      int,
    cash_account_id      int,
    credit_account_id    int,
    exchange_account_id  int,
    exchange_detail      json,
    bank_amount          float,
    cash_amount          float,
    credit_amount        float,
    exchange_amount      float,
    amount               float,
    discount_amount      float,
    rounded_off          float,
    pos_counter_code     text,
    created_at           timestamp not null default current_timestamp,
    updated_at           timestamp not null default current_timestamp,
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create function create_credit_note(input_data json, unique_session uuid default null)
    returns credit_note as
$$
declare
    v_credit_note credit_note;
    v_voucher     voucher;
    item          credit_note_inv_item;
    items         credit_note_inv_item[] := (select array_agg(x)
                                             from jsonb_populate_recordset(
                                                          null::credit_note_inv_item,
                                                          ($1 ->> 'inv_items')::jsonb) as x);
    inv           inventory;
    bat           batch;
    div           division;
    war           warehouse              := (select warehouse
                                             from warehouse
                                             where id = ($1 ->> 'warehouse_id')::int);
    cust          account                := (select account
                                             from account
                                             where id = ($1 ->> 'customer_id')::int
                                               and contact_type = 'CUSTOMER');
    loose         int;
    _fn_res       boolean;
begin
    $1 = jsonb_set($1::jsonb, '{mode}', '"INVENTORY"');
    $1 = jsonb_set($1::jsonb, '{lut}', coalesce(($1 ->> 'lut')::bool, false)::text::jsonb);
    select * into v_voucher from create_voucher($1, $2);
    if v_voucher.base_voucher_type != 'CREDIT_NOTE' then
        raise exception 'Allowed only CREDIT_NOTE voucher type';
    end if;
    if ($1 ->> 'exchange_account_id')::int is not null and ($1 ->> 'exchange_amount')::float <> 0 then
        select *
        into _fn_res
        from set_exchange(exchange_account := ($1 ->> 'exchange_account_id')::int,
                          exchange_amount := ($1 ->> 'exchange_amount')::float,
                          v_branch := v_voucher.branch_id, v_branch_name := v_voucher.branch_name,
                          v_voucher_id := v_voucher.id, v_voucher_no := v_voucher.voucher_no,
                          v_base_voucher_type := v_voucher.base_voucher_type,
                          v_date := v_voucher.date, v_ref_no := v_voucher.ref_no,
                          v_exchange_detail := ($1 ->> 'exchange_detail')::json);
        if not FOUND then
            raise exception 'internal error of set exchange';
        end if;
    end if;
    insert into credit_note (voucher_id, date, eff_date, sale_bill_voucher_id, branch_id, branch_name, warehouse_id,
                             base_voucher_type, voucher_type_id, voucher_no, voucher_prefix, voucher_fy, voucher_seq,
                             lut, ref_no, exchange_detail, customer_id, customer_name, description, branch_gst,
                             party_gst, bank_account_id, cash_account_id, credit_account_id, exchange_account_id,
                             bank_amount, cash_amount, credit_amount, exchange_amount, amount, discount_amount,
                             rounded_off, pos_counter_code)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, ($1 ->> 'sale_bill_voucher_id')::int, v_voucher.branch_id,
            v_voucher.branch_name, war.id, v_voucher.base_voucher_type, v_voucher.voucher_type_id, v_voucher.voucher_no,
            v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.lut, v_voucher.ref_no,
            ($1 ->> 'exchange_detail')::json, cust.id, cust.name, v_voucher.description, v_voucher.branch_gst,
            v_voucher.party_gst, ($1 ->> 'bank_account_id')::int, ($1 ->> 'cash_account_id')::int,
            ($1 ->> 'credit_account_id')::int, ($1 ->> 'exchange_account_id')::int, ($1 ->> 'bank_amount')::float,
            ($1 ->> 'cash_amount')::float, ($1 ->> 'credit_amount')::float, ($1 ->> 'exchange_amount')::float,
            ($1 ->> 'amount')::float, ($1 ->> 'discount_amount')::float, ($1 ->> 'rounded_off')::float,
            v_voucher.pos_counter_code)
    returning * into v_credit_note;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select * into div from division where id = inv.division_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_voucher.branch_id,
                           warehouse := v_credit_note.warehouse_id);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into credit_note_inv_item (id, sno, credit_note_id, batch_id, inventory_id, unit_id, unit_conv,
                                              gst_tax_id, qty, is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val,
                                              disc_mode, discount, s_inc_id, taxable_amount, asset_amount, cgst_amount,
                                              sgst_amount, igst_amount, cess_amount)
            values (coalesce(item.id, gen_random_uuid()), item.sno, v_credit_note.id, item.batch_id, item.inventory_id,
                    item.unit_id, item.unit_conv, item.gst_tax_id, item.qty, item.is_loose_qty, item.rate,
                    item.hsn_code, item.cess_on_qty, item.cess_on_val, item.disc_mode, item.discount, item.s_inc_id,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount)
            returning * into item;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, party_id, party_name, s_inc_id)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, -(item.qty * item.unit_conv * loose),
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_credit_note.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_credit_note.warehouse_id, war.name,
                    cust.id, cust.name, item.s_inc_id);
        end loop;
    return v_credit_note;
end;
$$ language plpgsql security definer;
--##
create function update_credit_note(v_id int, input_data json)
    returns credit_note AS
$$
declare
    v_credit_note    credit_note;
    v_voucher        voucher;
    item             credit_note_inv_item;
    items            credit_note_inv_item[] := (select array_agg(x)
                                                from jsonb_populate_recordset(
                                                             null::credit_note_inv_item,
                                                             ($2 ->> 'inv_items')::jsonb) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    cust             account;
    loose            int;
    missed_items_ids uuid[];
begin
    select * into cust from account a where a.id = ($2 ->> 'customer_id')::int and contact_type = 'CUSTOMER';
    update credit_note
    set date              = ($2 ->> 'date')::date,
        eff_date          = ($2 ->> 'eff_date')::date,
        ref_no            = ($2 ->> 'ref_no')::text,
        description       = ($2 ->> 'description')::text,
        amount            = ($2 ->> 'amount')::float,
        customer_id       = cust.id,
        customer_name     = cust.name,
        party_gst         = ($2 ->> 'party_gst')::json,
        discount_amount   = ($2 ->> 'discount_amount')::float,
        rounded_off       = ($2 ->> 'rounded_off')::float,
        cash_amount       = ($2 ->> 'cash_amount')::float,
        credit_amount     = ($2 ->> 'credit_amount')::float,
        bank_amount       = ($2 ->> 'bank_amount')::float,
        cash_account_id   = ($2 ->> 'cash_account_id')::int,
        credit_account_id = ($2 ->> 'credit_account_id')::int,
        bank_account_id   = ($2 ->> 'bank_account_id')::int,
        lut               = coalesce(($2 ->> 'lut')::bool, false),
        updated_at        = current_timestamp
    where id = $1
    returning * into v_credit_note;
    if not FOUND then
        raise exception 'Credit Note not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_credit_note.voucher_id, $2);
    select array_agg(x._id)
    into missed_items_ids
    from ((select a.id as _id, inventory_id, batch_id
           from credit_note_inv_item a
           where credit_note_id = $1)
          except
          (select a.id as _id, inventory_id, batch_id
           from unnest(items) a)) as x;
    delete from credit_note_inv_item a where a.id = any (missed_items_ids);
    select * into war from warehouse a where a.id = v_credit_note.warehouse_id;
    foreach item in array items
        loop
            select * into inv from inventory a where a.id = item.inventory_id;
            select * into div from division a where a.id = inv.division_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_credit_note.branch_id,
                           warehouse := v_credit_note.warehouse_id);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into credit_note_inv_item (id, sno, credit_note_id, batch_id, inventory_id, unit_id, unit_conv,
                                              gst_tax_id, qty, is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val,
                                              disc_mode, discount, s_inc_id, taxable_amount, asset_amount, cgst_amount,
                                              sgst_amount, igst_amount, cess_amount)
            values (coalesce(item.id, gen_random_uuid()), item.sno, v_credit_note.id, item.batch_id, item.inventory_id,
                    item.unit_id, item.unit_conv, item.gst_tax_id, item.qty, item.is_loose_qty, item.rate,
                    item.hsn_code, item.cess_on_qty, item.cess_on_val, item.disc_mode, item.discount, item.s_inc_id,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount)
            on conflict (id) do update
                set unit_id        = excluded.unit_id,
                    unit_conv      = excluded.unit_conv,
                    gst_tax_id     = excluded.gst_tax_id,
                    sno            = excluded.sno,
                    qty            = excluded.qty,
                    is_loose_qty   = excluded.is_loose_qty,
                    rate           = excluded.rate,
                    hsn_code       = excluded.hsn_code,
                    disc_mode      = excluded.disc_mode,
                    discount       = excluded.discount,
                    cess_on_val    = excluded.cess_on_val,
                    cess_on_qty    = excluded.cess_on_qty,
                    taxable_amount = excluded.taxable_amount,
                    cgst_amount    = excluded.cgst_amount,
                    sgst_amount    = excluded.sgst_amount,
                    igst_amount    = excluded.igst_amount,
                    cess_amount    = excluded.cess_amount,
                    s_inc_id       = excluded.s_inc_id
            returning * into item;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, party_id, party_name, s_inc_id)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, -(item.qty * item.unit_conv * loose),
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_credit_note.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_credit_note.warehouse_id, war.name,
                    cust.id, cust.name, item.s_inc_id)
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
                    manufacturer_id   = excluded.manufacturer_id,
                    manufacturer_name = excluded.manufacturer_name,
                    party_id          = excluded.party_id,
                    party_name        = excluded.party_name,
                    s_inc_id          = excluded.s_inc_id,
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
    return v_credit_note;
end;
$$ language plpgsql security definer;
--##
create function delete_credit_note(id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from credit_note where credit_note.id = $1 returning voucher_id into voucher_id;
    delete from voucher where voucher.id = voucher_id;
    if not FOUND then
        raise exception 'Invalid credit_note';
    end if;
end;
$$ language plpgsql security definer;