create table if not exists purchase_bill
(
    id                  int       not null generated always as identity primary key,
    voucher_id          int       not null,
    date                date      not null,
    eff_date            date,
    branch_id           int       not null,
    branch_name         text      not null,
    warehouse_id        int       not null,
    warehouse_name      text      not null,
    base_voucher_type   text      not null,
    purchase_mode       text      not null default 'CREDIT',
    voucher_type_id     int       not null,
    voucher_no          text      not null,
    voucher_prefix      text      not null,
    voucher_fy          int       not null,
    voucher_seq         int       not null,
    rcm                 boolean   not null default false,
    ref_no              text,
    vendor_id           int,
    vendor_name         text,
    description         text,
    branch_gst          json      not null,
    party_gst           json,
    party_account_id    int,
    exchange_account_id int,
    exchange_detail     json,
    party_name          text,
    gin_voucher_id      int unique,
    agent_detail        json,
    amount              float,
    discount_amount     float,
    exchange_amount     float,
    rounded_off         float,
    profit_percentage   float,
    profit_value        float,
    sale_value          float,
    nlc_value           float,
    created_at          timestamp not null default current_timestamp,
    updated_at          timestamp not null default current_timestamp,
    constraint purchase_mode_invalid check (check_purchase_mode(purchase_mode)),
    constraint base_voucher_type_invalid check (check_base_voucher_type(base_voucher_type))
);
--##
create function create_purchase_bill(input_data json, unique_session uuid default null)
    returns purchase_bill as
$$
declare
    v_purchase_bill purchase_bill;
    v_voucher       voucher;
    item            purchase_bill_inv_item;
    items           purchase_bill_inv_item[] := (select array_agg(x)
                                                 from jsonb_populate_recordset(
                                                              null::purchase_bill_inv_item,
                                                              ($1 ->> 'inv_items')::jsonb) as x);
    inv             inventory;
    bat             batch;
    div             division;
    ven             account                  := (select account
                                                 from account
                                                 where id = ($1 ->> 'vendor_id')::int
                                                   and contact_type = 'VENDOR');
    war             warehouse                := (select warehouse
                                                 from warehouse
                                                 where id = ($1 ->> 'warehouse_id')::int);
    fy              financial_year           := (select financial_year
                                                 from financial_year
                                                 where ($1 ->> 'date')::date between fy_start and fy_end);
    loose           int;
    _fn_res         boolean;
begin
    if (($1 ->> 'party_gst')::json ->> 'gst_no')::text is not null then
        if exists(select id
                  from purchase_bill
                  where purchase_bill.ref_no = ($1 ->> 'ref_no')::text
                    and (purchase_bill.party_gst ->> 'gst_no')::text = (($1 ->> 'party_gst')::json ->> 'gst_no')::text
                    and purchase_bill.date between fy.fy_start and fy.fy_end) then
            raise exception 'Duplicate bill number found';
        end if;
    end if;
    if (($1 ->> 'gin_voucher_id') is not null) and not exists(select id
                                                              from voucher
                                                              where id = ($1 ->> 'gin_voucher_id')::int
                                                                and base_voucher_type = 'GOODS_INWARD_NOTE'
                                                                and approval_state = require_no_of_approval) then
        raise exception 'Goods Inward Note % is not approved / not found', $1 ->> 'gin_voucher_id';
    end if;
    $1 = jsonb_set($1::jsonb, '{mode}', '"INVENTORY"');
    $1 = jsonb_set($1::jsonb, '{rcm}', coalesce(($1 ->> 'rcm')::bool, false)::text::jsonb);
    select * into v_voucher from create_voucher($1, $2);
    if v_voucher.base_voucher_type != 'PURCHASE' then
        raise exception 'Allowed only PURCHASE voucher type';
    end if;

    if ($1 ->> 'exchange_account_id') is not null and ($1 ->> 'exchange_amount')::float <> 0 then
        select *
        into _fn_res
        from set_exchange(exchange_account := ($1 ->> 'exchange_account_id')::int,
                          exchange_amount := ($1 ->> 'exchange_amount')::float,
                          v_branch := v_voucher.branch_id, v_branch_name := v_voucher.branch_name,
                          v_voucher_id := v_voucher.id, v_voucher_no := v_voucher.voucher_no,
                          v_base_voucher_type := v_voucher.base_voucher_type, v_date := v_voucher.date,
                          v_ref_no := v_voucher.ref_no, v_exchange_detail := ($1 ->> 'exchange_detail')::json
             );
        if not FOUND then
            raise exception 'internal error of set exchange';
        end if;
    end if;
    insert into purchase_bill (voucher_id, date, eff_date, branch_id, branch_name, warehouse_id, warehouse_name,
                               base_voucher_type, purchase_mode, voucher_type_id, voucher_no, voucher_prefix,
                               voucher_fy, voucher_seq, rcm, ref_no, vendor_id, vendor_name, description, branch_gst,
                               party_gst, party_account_id, exchange_account_id, exchange_detail, gin_voucher_id,
                               agent_detail, amount, discount_amount, exchange_amount, rounded_off, profit_percentage,
                               profit_value, sale_value, nlc_value)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name, war.id,
            war.name, v_voucher.base_voucher_type, ($1 ->> 'purchase_mode')::text, v_voucher.voucher_type_id,
            v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.rcm,
            v_voucher.ref_no, ven.id, ven.name, v_voucher.description, v_voucher.branch_gst, v_voucher.party_gst,
            v_voucher.party_id, ($1 ->> 'exchange_account_id')::int, ($1 ->> 'exchange_detail')::json,
            ($1 ->> 'gin_voucher_id')::int, ($1 ->> 'agent_detail')::json, ($1 ->> 'amount')::float,
            ($1 ->> 'discount_amount')::float, ($1 ->> 'exchange_amount')::float, ($1 ->> 'rounded_off')::float,
            ($1 ->> 'profit_percentage')::float, ($1 ->> 'profit_value')::float, ($1 ->> 'sale_value')::float,
            ($1 ->> 'nlc_value')::float)
    returning * into v_purchase_bill;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select * into div from division where id = inv.division_id;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into purchase_bill_inv_item (id, sno, purchase_bill_id, inventory_id, unit_id, unit_conv, gst_tax_id,
                                                qty, free_qty, rate, is_loose_qty, landing_cost, mrp, s_rate, batch_no,
                                                expiry, hsn_code, cess_on_qty, cess_on_val, disc1_mode, disc2_mode,
                                                discount1, discount2, taxable_amount, asset_amount, cgst_amount,
                                                sgst_amount, igst_amount, cess_amount, profit_percentage, sale_value,
                                                profit_value, cost, nlc, weight_qty, weight_rate, m_qty, label_qty,
                                                category1_id, category2_id, category3_id, category4_id, category5_id,
                                                category6_id, category7_id, category8_id, category9_id, category10_id)
            values (coalesce(item.id, gen_random_uuid()), item.sno, v_purchase_bill.id, item.inventory_id, item.unit_id,
                    item.unit_conv, item.gst_tax_id, item.qty, item.free_qty, item.rate, item.is_loose_qty,
                    item.landing_cost, item.mrp, item.s_rate, item.batch_no, item.expiry, item.hsn_code,
                    item.cess_on_qty, item.cess_on_val, item.disc1_mode, item.disc2_mode, item.discount1,
                    item.discount2, item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount,
                    item.igst_amount, item.cess_amount, item.profit_percentage, item.sale_value, item.profit_value,
                    item.cost, item.nlc, item.weight_qty, item.weight_rate, item.m_qty, item.label_qty,
                    item.category1_id, item.category2_id, item.category3_id, item.category4_id, item.category5_id,
                    item.category6_id, item.category7_id, item.category8_id, item.category9_id, item.category10_id)
            returning * into item;
            insert into batch (txn_id, sno, inventory_id, reorder_inventory_id, inventory_name, inventory_hsn,
                               branch_id, branch_name, warehouse_id, warehouse_name, division_id, division_name,
                               entry_type, batch_no, inventory_voucher_id, expiry, entry_date, mrp, s_rate, p_rate,
                               landing_cost, nlc, cost, unit_id, unit_conv, ref_no, manufacturer_id, manufacturer_name,
                               vendor_id, vendor_name, voucher_id, voucher_no, category1_id, category2_id, category3_id,
                               category4_id, category5_id, category6_id, category7_id, category8_id, category9_id,
                               category10_id, loose_qty, label_qty, is_loose_qty)
            values (item.id, item.sno, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id),
                    inv.name, item.hsn_code, v_purchase_bill.branch_id, v_purchase_bill.branch_name,
                    v_purchase_bill.warehouse_id, war.name, div.id, div.name, 'PURCHASE', item.batch_no,
                    v_purchase_bill.id, item.expiry, v_purchase_bill.date, item.mrp, item.s_rate, item.rate,
                    item.landing_cost, item.nlc, item.cost, item.unit_id, item.unit_conv, v_purchase_bill.ref_no,
                    inv.manufacturer_id, inv.manufacturer_name, v_purchase_bill.vendor_id, v_purchase_bill.vendor_name,
                    v_purchase_bill.voucher_id, v_purchase_bill.voucher_no, item.category1_id, item.category2_id,
                    item.category3_id, item.category4_id, item.category5_id, item.category6_id, item.category7_id,
                    item.category8_id, item.category9_id, item.category10_id, inv.loose_qty,
                    coalesce(item.label_qty, item.qty + coalesce(item.free_qty, 0)) * item.unit_conv, item.is_loose_qty)
            returning * into bat;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                inward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, party_id, party_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, div.id, div.name, v_voucher.branch_name, bat.id,
                    item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name, item.hsn_code,
                    inv.manufacturer_id, inv.manufacturer_name,
                    (item.qty + coalesce(item.free_qty, 0)) * item.unit_conv * loose, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    v_voucher.ref_no, v_purchase_bill.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type_id,
                    v_voucher.base_voucher_type, bat.category1_id, bat.category1_name, bat.category2_id,
                    bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id, bat.category4_name,
                    bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name, bat.category7_id,
                    bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id, bat.category9_name,
                    bat.category10_id, bat.category10_name, bat.warehouse_id, bat.warehouse_name, ven.id, ven.name);
            if inv.set_rate_values_via_purchase then
                select *
                into _fn_res
                from set_purchase_price(branch := v_voucher.branch_id, branch_name := v_voucher.branch_name,
                                        inv := inv, mrp := item.mrp, s_rate := item.s_rate, rate := item.rate,
                                        landing_cost := item.landing_cost, nlc := item.nlc);
            end if;
        end loop;
    return v_purchase_bill;
end;
$$ language plpgsql security definer;
--##
create function update_purchase_bill(v_id int, input_data json)
    returns purchase_bill as
$$
declare
    v_purchase_bill  purchase_bill;
    v_voucher        voucher;
    item             purchase_bill_inv_item;
    items            purchase_bill_inv_item[] := (select array_agg(x)
                                                  from jsonb_populate_recordset(
                                                               null::purchase_bill_inv_item,
                                                               ($2 ->> 'inv_items')::jsonb) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    ven              account                  := (select account
                                                  from account
                                                  where id = ($2 ->> 'vendor_id')::int
                                                    and contact_type = 'VENDOR');
    fy               financial_year;
    missed_items_ids uuid[];
    loose            int;
    _fn_res          boolean;
begin
    if (($2 ->> 'party_gst')::json ->> 'gst_no')::text is not null then
        select *
        into fy
        from financial_year
        where ($2 ->> 'date')::date between fy_start and fy_end;
        if exists(select purchase_bill.id
                  from purchase_bill
                  where purchase_bill.id != $1
                    and purchase_bill.ref_no = ($2 ->> 'ref_no')::text
                    and (purchase_bill.party_gst ->> 'gst_no')::text = (($2 ->> 'party_gst')::json ->> 'gst_no')::text
                    and purchase_bill.date between fy.fy_start and fy.fy_end) then
            raise exception 'Duplicate bill number found';
        end if;
    end if;
    update purchase_bill
    set date              = ($2 ->> 'date')::date,
        eff_date          = ($2 ->> 'eff_date')::date,
        ref_no            = ($2 ->> 'ref_no')::text,
        description       = ($2 ->> 'description')::text,
        amount            = ($2 ->> 'amount')::float,
        vendor_id         = ven.id,
        vendor_name       = ven.name,
        party_gst         = ($2 ->> 'party_gst')::json,
        party_account_id  = ($2 ->> 'party_account_id')::int,
        discount_amount   = ($2 ->> 'discount_amount')::float,
        rounded_off       = ($2 ->> 'rounded_off')::float,
        agent_detail      = ($2 ->> 'agent_detail')::json,
        nlc_value         = ($2 ->> 'nlc_value')::float,
        profit_value      = ($2 ->> 'profit_value')::float,
        profit_percentage = ($2 ->> 'profit_percentage')::float,
        sale_value        = ($2 ->> 'sale_value')::float,
        rcm               = coalesce(($2 ->> 'rcm')::bool, false),
        purchase_mode     = ($2 ->> 'purchase_mode')::text,
        updated_at        = current_timestamp
    where id = $1
    returning * into v_purchase_bill;
    if not FOUND then
        raise exception 'Purchase bill not found';
    end if;
    select * into v_voucher from update_voucher(v_purchase_bill.voucher_id, $2);
    select array_agg(x.id)
    into missed_items_ids
    from ((select id, inventory_id
           from purchase_bill_inv_item
           where purchase_bill_id = update_purchase_bill.v_id)
          except
          (select id, inventory_id
           from unnest(items))) as x;
    delete from purchase_bill_inv_item where id = any (missed_items_ids);
    select * into war from warehouse where id = v_purchase_bill.warehouse_id;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select * into div from division where id = inv.division_id;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into purchase_bill_inv_item(id, sno, purchase_bill_id, inventory_id, unit_id, unit_conv, gst_tax_id,
                                               qty, free_qty, rate, landing_cost, mrp, s_rate, batch_no, expiry,
                                               hsn_code, cess_on_qty, cess_on_val, disc1_mode, disc2_mode, discount1,
                                               discount2, taxable_amount, asset_amount, cgst_amount, sgst_amount,
                                               igst_amount, cess_amount, profit_percentage, sale_value, profit_value,
                                               cost, nlc, is_loose_qty, weight_qty, weight_rate, m_qty, label_qty,
                                               category1_id, category2_id, category3_id, category4_id, category5_id,
                                               category6_id, category7_id, category8_id, category9_id, category10_id)
            values (coalesce(item.id, gen_random_uuid()), item.sno, v_purchase_bill.id, item.inventory_id, item.unit_id,
                    item.unit_conv, item.gst_tax_id, item.qty, item.free_qty, item.rate, item.landing_cost, item.mrp,
                    item.s_rate, item.batch_no, item.expiry, item.hsn_code, item.cess_on_qty, item.cess_on_val,
                    item.disc1_mode, item.disc2_mode, item.discount1, item.discount2, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    item.profit_percentage, item.sale_value, item.profit_value, item.cost, item.nlc, item.is_loose_qty,
                    item.weight_qty, item.weight_rate, item.m_qty, item.label_qty, item.category1_id, item.category2_id,
                    item.category3_id, item.category4_id, item.category5_id, item.category6_id, item.category7_id,
                    item.category8_id, item.category9_id, item.category10_id)
            on conflict (id) do update
                set unit_id           = excluded.unit_id,
                    sno               = excluded.sno,
                    unit_conv         = excluded.unit_conv,
                    gst_tax_id        = excluded.gst_tax_id,
                    qty               = excluded.qty,
                    is_loose_qty      = excluded.is_loose_qty,
                    free_qty          = excluded.free_qty,
                    label_qty         = excluded.label_qty,
                    rate              = excluded.rate,
                    m_qty             = excluded.m_qty,
                    weight_qty        = excluded.weight_qty,
                    weight_rate       = excluded.weight_rate,
                    landing_cost      = excluded.landing_cost,
                    nlc               = excluded.nlc,
                    cost              = excluded.cost,
                    mrp               = excluded.mrp,
                    expiry            = excluded.expiry,
                    s_rate            = excluded.s_rate,
                    batch_no          = excluded.batch_no,
                    hsn_code          = excluded.hsn_code,
                    disc1_mode        = excluded.disc1_mode,
                    disc2_mode        = excluded.disc2_mode,
                    discount1         = excluded.discount1,
                    discount2         = excluded.discount2,
                    cess_on_val       = excluded.cess_on_val,
                    cess_on_qty       = excluded.cess_on_qty,
                    taxable_amount    = excluded.taxable_amount,
                    cgst_amount       = excluded.cgst_amount,
                    sgst_amount       = excluded.sgst_amount,
                    igst_amount       = excluded.igst_amount,
                    cess_amount       = excluded.cess_amount,
                    profit_percentage = excluded.profit_percentage,
                    sale_value        = excluded.sale_value,
                    profit_value      = excluded.profit_value,
                    category1_id      = excluded.category1_id,
                    category2_id      = excluded.category2_id,
                    category3_id      = excluded.category3_id,
                    category4_id      = excluded.category4_id,
                    category5_id      = excluded.category5_id,
                    category6_id      = excluded.category6_id,
                    category7_id      = excluded.category7_id,
                    category8_id      = excluded.category8_id,
                    category9_id      = excluded.category9_id,
                    category10_id     = excluded.category10_id
            returning * into item;
            insert into batch (txn_id, sno, inventory_id, reorder_inventory_id, inventory_name, inventory_hsn,
                               branch_id, branch_name, warehouse_id, warehouse_name, division_id, division_name,
                               entry_type, batch_no, inventory_voucher_id, expiry, entry_date, mrp, s_rate, p_rate,
                               landing_cost, nlc, cost, unit_id, unit_conv, ref_no, manufacturer_id, manufacturer_name,
                               vendor_id, vendor_name, voucher_id, voucher_no, category1_id, category2_id, category3_id,
                               category4_id, category5_id, category6_id, category7_id, category8_id, category9_id,
                               category10_id, loose_qty, label_qty, is_loose_qty)
            values (item.id, item.sno, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id),
                    inv.name, item.hsn_code, v_purchase_bill.branch_id, v_purchase_bill.branch_name,
                    v_purchase_bill.warehouse_id, war.name, div.id, div.name, 'PURCHASE', item.batch_no,
                    v_purchase_bill.id, item.expiry, v_purchase_bill.date, item.mrp, item.s_rate, item.rate,
                    item.landing_cost, item.nlc, item.cost, item.unit_id, item.unit_conv, v_purchase_bill.ref_no,
                    inv.manufacturer_id, inv.manufacturer_name, v_purchase_bill.vendor_id, v_purchase_bill.vendor_name,
                    v_purchase_bill.voucher_id, v_purchase_bill.voucher_no, item.category1_id, item.category2_id,
                    item.category3_id, item.category4_id, item.category5_id, item.category6_id, item.category7_id,
                    item.category8_id, item.category9_id, item.category10_id, inv.loose_qty,
                    coalesce(item.label_qty, item.qty + coalesce(item.free_qty, 0)) * item.unit_conv, item.is_loose_qty)
            on conflict (txn_id) do update
                set inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    sno               = excluded.sno,
                    label_qty         = excluded.label_qty,
                    is_loose_qty      = excluded.is_loose_qty,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    batch_no          = excluded.batch_no,
                    expiry            = excluded.expiry,
                    entry_date        = excluded.entry_date,
                    mrp               = excluded.mrp,
                    p_rate            = excluded.p_rate,
                    s_rate            = excluded.s_rate,
                    nlc               = excluded.nlc,
                    cost              = excluded.cost,
                    landing_cost      = excluded.landing_cost,
                    unit_conv         = excluded.unit_conv,
                    manufacturer_id   = excluded.manufacturer_id,
                    manufacturer_name = excluded.manufacturer_name,
                    vendor_id         = excluded.vendor_id,
                    vendor_name       = excluded.vendor_name,
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
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                inward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, party_id, party_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, div.id, div.name, v_voucher.branch_name, bat.id,
                    item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name, item.hsn_code,
                    inv.manufacturer_id, inv.manufacturer_name,
                    (item.qty + coalesce(item.free_qty, 0)) * item.unit_conv * loose, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    v_voucher.ref_no, v_purchase_bill.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type_id,
                    v_voucher.base_voucher_type, bat.category1_id, bat.category1_name, bat.category2_id,
                    bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id, bat.category4_name,
                    bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name, bat.category7_id,
                    bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id, bat.category9_name,
                    bat.category10_id, bat.category10_name, bat.warehouse_id, bat.warehouse_name, ven.id, ven.name)
            on conflict (id) do update
                set date              = excluded.date,
                    inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    inward            = excluded.inward,
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
            if inv.set_rate_values_via_purchase then
                select *
                into _fn_res
                from set_purchase_price(branch := v_voucher.branch_id, branch_name := v_voucher.branch_name,
                                        inv := inv, mrp := item.mrp, s_rate := item.s_rate, rate := item.rate,
                                        landing_cost := item.landing_cost, nlc := item.nlc);
            end if;
        end loop;
    return v_purchase_bill;
end;
$$ language plpgsql security definer;
--##
create function delete_purchase_bill(id int)
    returns void as
$$
declare
    v_id int;
begin
    delete from purchase_bill where purchase_bill.id = $1 returning voucher_id into v_id;
    delete from voucher where voucher.id = v_id;
    if not FOUND then
        raise exception 'Invalid purchase_bill';
    end if;
end;
$$ language plpgsql security definer;