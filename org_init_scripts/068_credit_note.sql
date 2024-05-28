create table if not exists credit_note
(
    id                int                   not null generated always as identity primary key,
    voucher           int                   not null,
    date              date                  not null,
    eff_date          date,
    sale_id           int,
    branch            int                   not null,
    warehouse         int                   not null,
    branch_name       text                  not null,
    base_voucher_type typ_base_voucher_type not null,
    voucher_type      int                   not null,
    voucher_no        text                  not null,
    voucher_prefix    text                  not null,
    voucher_fy        int                   not null,
    voucher_seq       int                   not null,
    lut               boolean               not null default false,
    ref_no            text,
    customer          int,
    customer_name     text,
    description       text,
    branch_gst        json                  not null,
    party_gst         json,
    ac_trns           jsonb,
    bank_account      int,
    cash_account      int,
    credit_account    int,
    exchange_account  int,
    exchange_detail   json,
    bank_amount       float,
    cash_amount       float,
    credit_amount     float,
    exchange_amount   float,
    amount            float,
    discount_amount   float,
    rounded_off       float,
    created_at        timestamp             not null default current_timestamp,
    updated_at        timestamp             not null default current_timestamp
);
--##
create function create_credit_note(
    date date,
    branch int,
    warehouse int,
    voucher_type int,
    inv_items jsonb,
    ac_trns jsonb,
    branch_gst JSON,
    party_gst JSON default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    sale_id int default null,
    exchange_detail json default null,
    amount float default null,
    discount_amount float default null,
    cash_amount float default null,
    credit_amount float default null,
    bank_amount float default null,
    cash_account int default null,
    credit_account int default null,
    bank_account int default null,
    rounded_off float default null,
    exchange_account int default null,
    exchange_amount float default null,
    customer int default null,
    lut boolean default false,
    unique_session uuid default gen_random_uuid()
)
    returns credit_note AS
$$
declare
    v_credit_note credit_note;
    v_voucher     voucher;
    item          credit_note_inv_item;
    items         credit_note_inv_item[] := (select array_agg(x)
                                             from jsonb_populate_recordset(
                                                          null::credit_note_inv_item,
                                                          create_credit_note.inv_items) as x);
    inv           inventory;
    bat           batch;
    div           division;
    war           warehouse;
    cust          customer;
    loose         int;
    _fn_res       boolean;
begin
    select *
    into v_voucher
    FROM
        create_voucher(date := create_credit_note.date, branch := create_credit_note.branch,
                       branch_gst := create_credit_note.branch_gst,
                       party_gst := create_credit_note.party_gst,
                       voucher_type := create_credit_note.voucher_type,
                       ref_no := create_credit_note.ref_no,
                       description := create_credit_note.description, mode := 'INVENTORY',
                       amount := create_credit_note.amount, ac_trns := create_credit_note.ac_trns,
                       eff_date := create_credit_note.eff_date, lut := create_credit_note.lut,
                       unique_session := create_credit_note.unique_session
        );
    if v_voucher.base_voucher_type != 'CREDIT_NOTE' then
        raise exception 'Allowed only CREDIT_NOTE voucher type';
    end if;
    if create_credit_note.exchange_account is not null and create_credit_note.exchange_amount <> 0 then
        select *
        into _fn_res
        from set_exchange(exchange_account := create_credit_note.exchange_account,
                          exchange_amount := create_credit_note.exchange_amount,
                          v_branch := v_voucher.branch, v_branch_name := v_voucher.branch_name,
                          voucher_id := v_voucher.id, v_voucher_no := v_voucher.voucher_no,
                          v_base_voucher_type := v_voucher.base_voucher_type,
                          v_date := v_voucher.date, v_ref_no := v_voucher.ref_no,
                          v_exchange_detail := create_credit_note.exchange_detail);
        if not FOUND then
            raise exception 'internal error of set exchange';
        end if;
    end if;
    select * into war from warehouse where id = create_credit_note.warehouse;
    select * into cust from customer where id = create_credit_note.customer;
    insert into credit_note (voucher, date, eff_date, sale_id, branch, branch_name, warehouse, base_voucher_type,
                             voucher_type, voucher_no, voucher_prefix, voucher_fy, voucher_seq, lut, ref_no,
                             exchange_detail, customer, customer_name, description, branch_gst, party_gst, ac_trns,
                             bank_account, cash_account, credit_account, exchange_account, bank_amount, cash_amount,
                             credit_amount, exchange_amount, amount, discount_amount, rounded_off)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, create_credit_note.sale_id, v_voucher.branch,
            v_voucher.branch_name, create_credit_note.warehouse, v_voucher.base_voucher_type, v_voucher.voucher_type,
            v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.lut,
            v_voucher.ref_no, create_credit_note.exchange_detail, create_credit_note.customer, cust.name,
            v_voucher.description, v_voucher.branch_gst, v_voucher.party_gst, create_credit_note.ac_trns,
            create_credit_note.bank_account, create_credit_note.cash_account, create_credit_note.credit_account,
            create_credit_note.exchange_account, create_credit_note.bank_amount, create_credit_note.cash_amount,
            create_credit_note.credit_amount, create_credit_note.exchange_amount,
            create_credit_note.amount, create_credit_note.discount_amount, create_credit_note.rounded_off)
    returning * into v_credit_note;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            select *
            into bat
            from get_batch(v_bat := item.batch, v_inv := item.inventory, v_br := v_voucher.branch,
                           v_war := v_credit_note.warehouse);
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
                                category9_name, category10, category10_name, warehouse, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    item.batch, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name, inv.hsn_code,
                    inv.manufacturer, inv.manufacturer_name, -(item.qty * item.unit_conv * loose), item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    v_voucher.ref_no, v_credit_note.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type,
                    v_voucher.base_voucher_type, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, v_credit_note.warehouse, war.name);
            insert into credit_note_inv_item (id, credit_note, batch, inventory, unit, unit_conv, gst_tax, qty,
                                              is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc_mode,
                                              discount,
                                              s_inc, taxable_amount, asset_amount, cgst_amount, sgst_amount,
                                              igst_amount, cess_amount)
            values (item.id, v_credit_note.id, item.batch, item.inventory, item.unit, item.unit_conv, item.gst_tax,
                    item.qty, item.is_loose_qty, item.rate, item.hsn_code, item.cess_on_qty, item.cess_on_val,
                    item.disc_mode, item.discount, item.s_inc, item.taxable_amount, item.asset_amount,
                    item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount);
        end loop;
    return v_credit_note;
end;
$$ language plpgsql security definer;
--##
create function update_credit_note(
    v_id int,
    date date,
    inv_items jsonb,
    ac_trns jsonb,
    party_gst JSON default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    amount float default null,
    discount_amount float default null,
    cash_amount float default null,
    credit_amount float default null,
    bank_amount float default null,
    cash_account int default null,
    credit_account int default null,
    bank_account int default null,
    rounded_off float default null,
    customer int default null,
    lut boolean default false
)
    returns credit_note AS
$$
declare
    v_credit_note    credit_note;
    v_voucher        voucher;
    item             credit_note_inv_item;
    items            credit_note_inv_item[] := (select array_agg(x)
                                                from jsonb_populate_recordset(
                                                             null::credit_note_inv_item,
                                                             update_credit_note.inv_items) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    cust             customer;
    loose            int;
    missed_items_ids uuid[];
begin
    select * into cust from customer where id = update_credit_note.customer;
    update credit_note
    set date            = update_credit_note.date,
        eff_date        = update_credit_note.eff_date,
        ref_no          = update_credit_note.ref_no,
        description     = update_credit_note.description,
        amount          = update_credit_note.amount,
        ac_trns         = update_credit_note.ac_trns,
        customer        = update_credit_note.customer,
        customer_name   = cust.name,
        party_gst       = update_credit_note.party_gst,
        discount_amount = update_credit_note.discount_amount,
        rounded_off     = update_credit_note.rounded_off,
        cash_amount     = update_credit_note.cash_amount,
        credit_amount   = update_credit_note.credit_amount,
        bank_amount     = update_credit_note.bank_amount,
        cash_account    = update_credit_note.cash_account,
        credit_account  = update_credit_note.credit_account,
        bank_account    = update_credit_note.bank_account,
        lut             = update_credit_note.lut,
        updated_at      = current_timestamp
    where id = $1
    returning * into v_credit_note;
    if not FOUND then
        raise exception 'Credit Note not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_id := v_credit_note.voucher, date := v_credit_note.date,
                       branch_gst := v_credit_note.branch_gst,
                       party_gst := v_credit_note.party_gst, ref_no := v_credit_note.ref_no,
                       description := v_credit_note.description, amount := v_credit_note.amount,
                       ac_trns := v_credit_note.ac_trns, eff_date := v_credit_note.eff_date,
                       lut := v_credit_note.lut
        );
    select array_agg(id)
    into missed_items_ids
    from ((select id, inventory, batch
           from credit_note_inv_item
           where credit_note = update_credit_note.v_id)
          except
          (select id, inventory, batch
           from unnest(items)));
    delete from credit_note_inv_item where id = any (missed_items_ids);
    select * into war from warehouse where id = v_credit_note.warehouse;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            select *
            into bat
            from get_batch(v_bat := item.batch, v_inv := item.inventory, v_br := v_credit_note.branch,
                           v_war := v_credit_note.warehouse);
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
                                category9_name, category10, category10_name, warehouse, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch, inv.division, div.name, v_voucher.branch_name,
                    item.batch, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name, inv.hsn_code,
                    inv.manufacturer, inv.manufacturer_name, -(item.qty * item.unit_conv * loose), item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    v_voucher.ref_no, v_credit_note.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type,
                    v_voucher.base_voucher_type, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, v_credit_note.warehouse, war.name)
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
                    customer          = excluded.customer,
                    customer_name     = excluded.customer_name,
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
            insert into credit_note_inv_item (id, credit_note, batch, inventory, unit, unit_conv, gst_tax, qty,
                                              is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc_mode,
                                              discount,
                                              s_inc, taxable_amount, asset_amount, cgst_amount, sgst_amount,
                                              igst_amount, cess_amount)
            values (item.id, v_credit_note.id, item.batch, item.inventory, item.unit, item.unit_conv, item.gst_tax,
                    item.qty, item.is_loose_qty, item.rate, item.hsn_code, item.cess_on_qty, item.cess_on_val,
                    item.disc_mode, item.discount, item.s_inc, item.taxable_amount, item.asset_amount,
                    item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount)
            on conflict (id) do update
                set unit           = excluded.unit,
                    unit_conv      = excluded.unit_conv,
                    gst_tax        = excluded.gst_tax,
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
                    s_inc          = excluded.s_inc;
        end loop;
    return v_credit_note;
end;
$$ language plpgsql security definer;
--##
create function delete_credit_note(v_id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from credit_note where id = $1 returning voucher into voucher_id;
    delete from voucher where id = voucher_id;
    if not FOUND then
        raise exception 'Invalid credit_note';
    end if;
end;
$$ language plpgsql security definer;