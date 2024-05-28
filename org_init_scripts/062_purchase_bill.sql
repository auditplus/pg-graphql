create type typ_purchase_mode as enum ('CASH', 'CREDIT');
--##
create table if not exists purchase_bill
(
    id                int                   not null generated always as identity primary key,
    voucher           int                   not null,
    date              date                  not null,
    eff_date          date,
    branch            int                   not null,
    branch_name       text                  not null,
    warehouse         int                   not null,
    base_voucher_type typ_base_voucher_type not null,
    purchase_mode     typ_purchase_mode     not null default 'CREDIT',
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
    exchange_account  int,
    exchange_detail   json,
    party_name        text,
    gin               int unique,
    ac_trns           jsonb,
    agent_detail      json,
    tds_details       jsonb,
    amount            float,
    discount_amount   float,
    exchange_amount   float,
    rounded_off       float,
    profit_percentage float,
    profit_value      float,
    sale_value        float,
    nlc_value         float,
    created_at        timestamp             not null default current_timestamp,
    updated_at        timestamp             not null default current_timestamp
);
--##
create function create_purchase_bill(
    date date,
    branch int,
    branch_gst json,
    warehouse int,
    voucher_type int,
    inv_items jsonb,
    ac_trns jsonb,
    purchase_mode text,
    vendor int default null,
    gin int default null,
    party_gst json default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    party_account int default null,
    exchange_detail json default null,
    exchange_account int default null,
    exchange_amount float default null,
    amount float default null,
    discount_amount float default null,
    rounded_off float default null,
    agent_detail json default null,
    tds_details jsonb default null,
    nlc_value float default null,
    profit_value float default null,
    sale_value float default null,
    profit_percentage float default null,
    rcm boolean default false,
    unique_session uuid default gen_random_uuid()
)
    returns purchase_bill as
$$
declare
    v_purchase_bill purchase_bill;
    v_voucher       voucher;
    item            purchase_bill_inv_item;
    items           purchase_bill_inv_item[] := (select array_agg(x)
                                                 from jsonb_populate_recordset(
                                                              null::purchase_bill_inv_item,
                                                              create_purchase_bill.inv_items) as x);
    inv             inventory;
    bat             batch;
    div             division;
    war             warehouse;
    ven             vendor;
    fy              financial_year;
    loose           int;
    _fn_res         boolean;
    v_purchase_mode typ_purchase_mode := create_purchase_bill.purchase_mode::typ_purchase_mode;
begin
    if (create_purchase_bill.party_gst ->> 'gst_no')::text is not null then
        select *
        into fy
        from financial_year
        where create_purchase_bill.date between fy_start and fy_end;
        if exists(select
                  from purchase_bill
                  where purchase_bill.ref_no = create_purchase_bill.ref_no
                    and (purchase_bill.party_gst ->> 'gst_no')::text = (create_purchase_bill.party_gst ->> 'gst_no')::text
                    and purchase_bill.date between fy.fy_start and fy.fy_end) then
            raise exception 'Duplicate bill number found';
        end if;
    end if;
    if create_purchase_bill.gin is not null then
        select id
        from voucher
        where id = (select voucher from goods_inward_note where id = create_purchase_bill.gin)
          and approval_state = require_no_of_approval;
        if not FOUND then
            raise exception 'Goods Inward Note % is not approved', create_purchase_bill.gin;
        end if;
    end if;

    select *
    into v_voucher
    from
        create_voucher(date := create_purchase_bill.date, branch := create_purchase_bill.branch,
                       branch_gst := create_purchase_bill.branch_gst, party_gst := create_purchase_bill.party_gst,
                       voucher_type := create_purchase_bill.voucher_type, ref_no := create_purchase_bill.ref_no,
                       description := create_purchase_bill.description, mode := 'INVENTORY',
                       amount := create_purchase_bill.amount, ac_trns := create_purchase_bill.ac_trns,
                       eff_date := create_purchase_bill.eff_date, rcm := create_purchase_bill.rcm,
                       tds_details := create_purchase_bill.tds_details, party := create_purchase_bill.party_account,
                       unique_session := create_purchase_bill.unique_session);
    if v_voucher.base_voucher_type != 'PURCHASE' then
        raise exception 'Allowed only PURCHASE voucher type';
    end if;
    if create_purchase_bill.exchange_account is not null and create_purchase_bill.exchange_amount <> 0 then
        select *
        into _fn_res
        from set_exchange(exchange_account := create_purchase_bill.exchange_account,
                          exchange_amount := create_purchase_bill.exchange_amount,
                          v_branch := create_purchase_bill.branch, v_branch_name := v_voucher.branch_name,
                          voucher_id := v_voucher.id, v_voucher_no := v_voucher.voucher_no,
                          v_base_voucher_type := v_voucher.base_voucher_type, v_date := create_purchase_bill.date,
                          v_ref_no := v_voucher.ref_no, v_exchange_detail := create_purchase_bill.exchange_detail
             );
        if not FOUND then
            raise exception 'internal error of set exchange';
        end if;
    end if;
    select * into war from warehouse where id = create_purchase_bill.warehouse;
    select * into ven from vendor where id = create_purchase_bill.vendor;
    insert into purchase_bill(voucher, date, eff_date, branch, branch_name, warehouse, base_voucher_type, purchase_mode,
                              voucher_type, voucher_no, voucher_prefix, voucher_fy, voucher_seq, rcm,
                              ref_no, vendor, vendor_name, description, branch_gst, party_gst, party_account,
                              exchange_account, exchange_detail, gin, ac_trns, agent_detail,
                              tds_details, amount, discount_amount, exchange_amount, rounded_off, profit_percentage,
                              profit_value, sale_value, nlc_value)
    values (v_voucher.id, create_purchase_bill.date, create_purchase_bill.eff_date,
            create_purchase_bill.branch, v_voucher.branch_name,
            create_purchase_bill.warehouse, v_voucher.base_voucher_type,
            v_purchase_mode, create_purchase_bill.voucher_type,
            v_voucher.voucher_no, v_voucher.voucher_prefix, v_voucher.voucher_fy,
            v_voucher.voucher_seq, create_purchase_bill.rcm, create_purchase_bill.ref_no,
            create_purchase_bill.vendor, ven.name, create_purchase_bill.description,
            create_purchase_bill.branch_gst, create_purchase_bill.party_gst,
            create_purchase_bill.party_account, create_purchase_bill.exchange_account,
            create_purchase_bill.exchange_detail, create_purchase_bill.gin,
            create_purchase_bill.ac_trns, create_purchase_bill.agent_detail,
            create_purchase_bill.tds_details, create_purchase_bill.amount,
            create_purchase_bill.discount_amount, create_purchase_bill.exchange_amount,
            create_purchase_bill.rounded_off, create_purchase_bill.profit_percentage,
            create_purchase_bill.profit_value, create_purchase_bill.sale_value,
            create_purchase_bill.nlc_value)
    returning * into v_purchase_bill;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into purchase_bill_inv_item (id, sno, purchase_bill, inventory, unit, unit_conv, gst_tax, qty,
                                                free_qty, rate, is_loose_qty, landing_cost, mrp, s_rate, batch_no,
                                                expiry, category, hsn_code, cess_on_qty, cess_on_val, disc1_mode,
                                                disc2_mode, discount1, discount2, taxable_amount, asset_amount,
                                                cgst_amount, sgst_amount, igst_amount, cess_amount, profit_percentage,
                                                sale_value, profit_value, cost, nlc, weight_qty, weight_rate, t_meter,
                                                label_qty)
            values (item.id, item.sno, v_purchase_bill.id, item.inventory, item.unit, item.unit_conv, item.gst_tax,
                    item.qty, item.free_qty, item.rate, item.is_loose_qty, item.landing_cost, item.mrp, item.s_rate,
                    item.batch_no, item.expiry, item.category, item.hsn_code, item.cess_on_qty, item.cess_on_val,
                    item.disc1_mode, item.disc2_mode, item.discount1, item.discount2, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    item.profit_percentage, item.sale_value, item.profit_value, item.cost, item.nlc, item.weight_qty,
                    item.weight_rate, item.t_meter, item.label_qty);
            insert into batch (txn_id, sno, inventory, inventory_name, inventory_hsn, branch, branch_name, warehouse,
                               warehouse_name, division, division_name, entry_type, batch_no, inventory_voucher_id,
                               expiry, entry_date, mrp, s_rate, p_rate, landing_cost, nlc, cost, unit_id, unit_conv,
                               ref_no, manufacturer, manufacturer_name, vendor, vendor_name, voucher, voucher_no,
                               category1, category2, category3, category4, category5, category6, category7, category8,
                               category9, category10, loose_qty, label_qty)
            values (item.id, item.sno, item.inventory, inv.name, item.hsn_code, create_purchase_bill.branch,
                    v_purchase_bill.branch_name, create_purchase_bill.warehouse, war.name, div.id, div.name, 'PURCHASE',
                    item.batch_no, v_purchase_bill.id, item.expiry, v_purchase_bill.date, item.mrp, item.s_rate,
                    item.rate, item.landing_cost, item.nlc, item.cost, item.unit, item.unit_conv,
                    v_purchase_bill.ref_no, inv.manufacturer, inv.manufacturer_name, v_purchase_bill.vendor,
                    v_purchase_bill.vendor_name, v_purchase_bill.voucher, v_purchase_bill.voucher_no,
                    (item.category ->> 'category1')::int, (item.category ->> 'category2')::int,
                    (item.category ->> 'category3')::int, (item.category ->> 'category4')::int,
                    (item.category ->> 'category5')::int, (item.category ->> 'category6')::int,
                    (item.category ->> 'category7')::int, (item.category ->> 'category8')::int,
                    (item.category ->> 'category9')::int, (item.category ->> 'category10')::int, inv.loose_qty,
                    coalesce(item.label_qty, item.qty + coalesce(item.free_qty, 0)) * item.unit_conv)
            returning * into bat;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, inventory_hsn, manufacturer, manufacturer_name,
                                inward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch, div.id, div.name, v_voucher.branch_name,
                    bat.id, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name, item.hsn_code,
                    inv.manufacturer, inv.manufacturer_name,
                    (item.qty + coalesce(item.free_qty, 0)) * item.unit_conv * loose, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    v_voucher.ref_no, v_purchase_bill.id, v_voucher.id, v_voucher.voucher_no, v_voucher.voucher_type,
                    v_voucher.base_voucher_type, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, bat.warehouse, bat.warehouse_name);
            if inv.set_rate_values_via_purchase then
                select *
                into _fn_res
                from set_purchase_price(branch := v_voucher.branch, branch_name := v_voucher.branch_name,
                                        inv := inv, mrp := item.mrp, s_rate := item.s_rate, rate := item.rate,
                                        landing_cost := item.landing_cost, nlc := item.nlc);
            end if;
        end loop;
    return v_purchase_bill;
end;
$$ language plpgsql security definer;
--##
create function update_purchase_bill(
    v_id int,
    date date,
    inv_items jsonb,
    ac_trns jsonb,
    purchase_mode text,
    vendor int default null,
    party_gst json default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    party_account int default null,
    amount float default null,
    discount_amount float default null,
    rounded_off float default null,
    agent_detail json default null,
    tds_details jsonb default null,
    nlc_value float default null,
    profit_value float default null,
    sale_value float default null,
    profit_percentage float default null,
    rcm boolean default false
)
    returns purchase_bill as
$$
declare
    v_purchase_bill  purchase_bill;
    v_voucher        voucher;
    item             purchase_bill_inv_item;
    items            purchase_bill_inv_item[] := (select array_agg(x)
                                                  from jsonb_populate_recordset(
                                                               null::purchase_bill_inv_item,
                                                               update_purchase_bill.inv_items) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    ven              vendor;
    fy               financial_year;
    missed_items_ids uuid[];
    loose            int;
    _fn_res          boolean;
    v_purchase_mode typ_purchase_mode := update_purchase_bill.purchase_mode::typ_purchase_mode;
begin
    if (update_purchase_bill.party_gst ->> 'gst_no')::text is not null then
        select *
        into fy
        from financial_year
        where update_purchase_bill.date between fy_start and fy_end;
        if exists(select purchase_bill.id
                  from purchase_bill
                  where purchase_bill.id != update_purchase_bill.v_id
                    and purchase_bill.ref_no = update_purchase_bill.ref_no
                    and (purchase_bill.party_gst ->> 'gst_no')::text = (update_purchase_bill.party_gst ->> 'gst_no')::text
                    and purchase_bill.date between fy.fy_start and fy.fy_end) then
            raise exception 'Duplicate bill number found';
        end if;
    end if;

    select * into ven from vendor where id = update_purchase_bill.vendor;

    update purchase_bill
    set date              = update_purchase_bill.date,
        eff_date          = update_purchase_bill.eff_date,
        ref_no            = update_purchase_bill.ref_no,
        description       = update_purchase_bill.description,
        amount            = update_purchase_bill.amount,
        ac_trns           = update_purchase_bill.ac_trns,
        vendor            = update_purchase_bill.vendor,
        vendor_name       = ven.name,
        party_gst         = update_purchase_bill.party_gst,
        party_account     = update_purchase_bill.party_account,
        discount_amount   = update_purchase_bill.discount_amount,
        rounded_off       = update_purchase_bill.rounded_off,
        agent_detail      = update_purchase_bill.agent_detail,
        tds_details       = update_purchase_bill.tds_details,
        nlc_value         = update_purchase_bill.nlc_value,
        profit_value      = update_purchase_bill.profit_value,
        profit_percentage = update_purchase_bill.profit_percentage,
        sale_value        = update_purchase_bill.sale_value,
        rcm               = update_purchase_bill.rcm,
        purchase_mode     = v_purchase_mode,
        updated_at        = current_timestamp
    where id = $1
    returning * into v_purchase_bill;
    if not FOUND then
        raise exception 'Purchase bill not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_id := v_purchase_bill.voucher, date := v_purchase_bill.date,
                       branch_gst := v_purchase_bill.branch_gst,
                       party_gst := v_purchase_bill.party_gst, ref_no := v_purchase_bill.ref_no,
                       description := v_purchase_bill.description, amount := v_purchase_bill.amount,
                       ac_trns := v_purchase_bill.ac_trns, eff_date := v_purchase_bill.eff_date,
                       rcm := v_purchase_bill.rcm, tds_details := v_purchase_bill.tds_details,
                       party := v_purchase_bill.party_account
        );
    select array_agg(id)
    into missed_items_ids
    from ((select id, inventory
           from purchase_bill_inv_item
           where purchase_bill = update_purchase_bill.v_id)
          except
          (select id, inventory
           from unnest(items)));
    delete from purchase_bill_inv_item where id = any (missed_items_ids);
    select * into war from warehouse where id = v_purchase_bill.warehouse;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory;
            select * into div from division where id = inv.division;
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into purchase_bill_inv_item(id, sno, purchase_bill, inventory, unit, unit_conv, gst_tax, qty,
                                               free_qty, rate, landing_cost, mrp, s_rate, batch_no, expiry, category,
                                               hsn_code, cess_on_qty, cess_on_val, disc1_mode, disc2_mode, discount1,
                                               discount2, taxable_amount, asset_amount, cgst_amount, sgst_amount,
                                               igst_amount, cess_amount, profit_percentage, sale_value, profit_value,
                                               cost, nlc, is_loose_qty, weight_qty, weight_rate, t_meter, label_qty)
            values (item.id, item.sno, v_purchase_bill.id, item.inventory, item.unit, item.unit_conv, item.gst_tax,
                    item.qty, item.free_qty, item.rate, item.landing_cost, item.mrp, item.s_rate, item.batch_no,
                    item.expiry, item.category, item.hsn_code, item.cess_on_qty, item.cess_on_val, item.disc1_mode,
                    item.disc2_mode, item.discount1, item.discount2, item.taxable_amount, item.asset_amount,
                    item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount, item.profit_percentage,
                    item.sale_value, item.profit_value, item.cost, item.nlc, item.is_loose_qty, item.weight_qty,
                    item.weight_rate, item.t_meter, item.label_qty)
            on conflict (id) do update
                set unit              = excluded.unit,
                    sno               = excluded.sno,
                    unit_conv         = excluded.unit_conv,
                    gst_tax           = excluded.gst_tax,
                    qty               = excluded.qty,
                    is_loose_qty      = excluded.is_loose_qty,
                    free_qty          = excluded.free_qty,
                    label_qty         = excluded.label_qty,
                    rate              = excluded.rate,
                    t_meter           = excluded.t_meter,
                    weight_qty        = excluded.weight_qty,
                    weight_rate       = excluded.weight_rate,
                    landing_cost      = excluded.landing_cost,
                    nlc               = excluded.nlc,
                    cost              = excluded.cost,
                    mrp               = excluded.mrp,
                    expiry            = excluded.expiry,
                    s_rate            = excluded.s_rate,
                    batch_no          = excluded.batch_no,
                    category          = excluded.category,
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
                    profit_value      = excluded.profit_value;
            insert into batch (txn_id, sno, inventory, inventory_name, inventory_hsn, branch, branch_name, warehouse,
                               warehouse_name, division, division_name, entry_type, batch_no,
                               inventory_voucher_id, expiry, entry_date, mrp, s_rate, p_rate, landing_cost, nlc, cost,
                               unit_id, unit_conv, ref_no, manufacturer, manufacturer_name, vendor,
                               vendor_name, voucher, voucher_no, category1, category2, category3, category4, category5,
                               category6, category7, category8, category9, category10, loose_qty, label_qty)
            values (item.id, item.sno, item.inventory, inv.name, item.hsn_code, v_purchase_bill.branch,
                    v_purchase_bill.branch_name, v_purchase_bill.warehouse, war.name, div.id, div.name, 'PURCHASE',
                    item.batch_no, v_purchase_bill.id, item.expiry, v_purchase_bill.date, item.mrp, item.s_rate,
                    item.rate, item.landing_cost, item.nlc, item.cost, item.unit, item.unit_conv,
                    v_purchase_bill.ref_no, inv.manufacturer, inv.manufacturer_name, v_purchase_bill.vendor,
                    v_purchase_bill.vendor_name, v_purchase_bill.voucher, v_purchase_bill.voucher_no,
                    (item.category ->> 'category1')::int, (item.category ->> 'category2')::int,
                    (item.category ->> 'category3')::int, (item.category ->> 'category4')::int,
                    (item.category ->> 'category5')::int, (item.category ->> 'category6')::int,
                    (item.category ->> 'category7')::int, (item.category ->> 'category8')::int,
                    (item.category ->> 'category9')::int, (item.category ->> 'category10')::int, inv.loose_qty,
                    coalesce(item.label_qty, item.qty + coalesce(item.free_qty, 0)) * item.unit_conv)
            on conflict (txn_id) do update
                set inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    sno               = excluded.sno,
                    label_qty         = excluded.label_qty,
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
                    ref_no            = excluded.ref_no
            returning * into bat;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, inventory_hsn, manufacturer, manufacturer_name,
                                inward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher, voucher_no, voucher_type,
                                base_voucher_type, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch, div.id, div.name, v_voucher.branch_name,
                    bat.id, item.inventory, coalesce(inv.reorder_inventory, item.inventory), inv.name, item.hsn_code,
                    inv.manufacturer, inv.manufacturer_name,
                    (item.qty + coalesce(item.free_qty, 0)) * item.unit_conv * loose, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    v_voucher.ref_no, v_purchase_bill.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type, v_voucher.base_voucher_type, bat.category1, bat.category1_name,
                    bat.category2, bat.category2_name, bat.category3, bat.category3_name, bat.category4,
                    bat.category4_name, bat.category5, bat.category5_name, bat.category6, bat.category6_name,
                    bat.category7, bat.category7_name, bat.category8, bat.category8_name, bat.category9,
                    bat.category9_name, bat.category10, bat.category10_name, bat.warehouse, bat.warehouse_name)
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
            if inv.set_rate_values_via_purchase then
                select *
                into _fn_res
                from set_purchase_price(branch := v_voucher.branch, branch_name := v_voucher.branch_name,
                                        inv := inv, mrp := item.mrp, s_rate := item.s_rate, rate := item.rate, 
                                        landing_cost := item.landing_cost, nlc := item.nlc);
            end if;
        end loop;
    return v_purchase_bill;
end;
$$ language plpgsql security definer;
--##
create function delete_purchase_bill(v_id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from purchase_bill where id = $1 returning voucher into voucher_id;
    delete from voucher where id = voucher_id;
    if not FOUND then
        raise exception 'Invalid purchase_bill';
    end if;
end;
$$ language plpgsql security definer;