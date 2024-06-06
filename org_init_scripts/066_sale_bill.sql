create table if not exists sale_bill
(
    id                   int                   not null generated always as identity primary key,
    voucher_id           int                   not null,
    date                 date                  not null,
    eff_date             date,
    branch_id            int                   not null,
    branch_name          text                  not null,
    warehouse_id         int                   not null,
    base_voucher_type    typ_base_voucher_type not null,
    voucher_type_id      int                   not null,
    voucher_no           text                  not null,
    voucher_prefix       text                  not null,
    voucher_fy           int                   not null,
    voucher_seq          int                   not null,
    lut                  boolean               not null default false,
    ref_no               text,
    gift_voucher_coupons jsonb,
    customer_id          int,
    customer_name        text,
    doctor_id            int,
    customer_group_id    int,
    description          text,
    branch_gst           json                  not null,
    party_gst            json,
    emi_detail           json,
    delivery_info        json,
    ac_trns              jsonb,
    bank_account_id      int,
    cash_account_id      int,
    eft_account_id       int,
    credit_account_id    int,
    exchange_adjs        jsonb,
    advance_adjs         jsonb,
    bank_amount          float,
    cash_amount          float,
    eft_amount           float,
    credit_amount        float,
    gift_voucher_amount  float,
    exchange_amount      float,
    advance_amount       float,
    amount               float,
    discount_amount      float,
    rounded_off          float,
    points_earned        float,
    pos_counter_id       int,
    created_at           timestamp             not null default current_timestamp,
    updated_at           timestamp             not null default current_timestamp
);
--##
create function create_sale_bill(
    date date,
    branch int,
    warehouse int,
    voucher_type int,
    inv_items jsonb,
    ac_trns jsonb,
    branch_gst json,
    party_gst json default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    gift_voucher_coupons jsonb default null,
    gift_voucher_amount float default null,
    emi_detail json default null,
    delivery_info json default null,
    amount float default null,
    discount_amount float default null,
    cash_amount float default null,
    credit_amount float default null,
    bank_amount float default null,
    eft_amount float default null,
    cash_account int default null,
    credit_account int default null,
    bank_account int default null,
    eft_account int default null,
    rounded_off float default null,
    exchange_amount float default null,
    advance_amount float default null,
    exchange_adjs jsonb default null,
    advance_adjs jsonb default null,
    points_earned float default null,
    customer int default null,
    customer_group int default null,
    doctor int default null,
    pos_counter_id int default null,
    counter_trns jsonb default null,
    lut boolean default false,
    unique_session uuid default gen_random_uuid()
)
    returns sale_bill AS
$$
declare
    v_sale_bill sale_bill;
    v_voucher   voucher;
    item        sale_bill_inv_item;
    items       sale_bill_inv_item[] := (select array_agg(x)
                                         from jsonb_populate_recordset(
                                                      null::sale_bill_inv_item,
                                                      create_sale_bill.inv_items) as x);
    inv         inventory;
    bat         batch;
    div         division;
    war         warehouse;
    cust        customer;
    loose       int;
    drugs_cat   typ_drug_category[];
    _fn_res     boolean;
begin
    if jsonb_array_length(coalesce(create_sale_bill.gift_voucher_coupons, '[]'::jsonb)) > 0 then
        select * into _fn_res from claim_gift_coupon(gift_coupons := create_sale_bill.gift_voucher_coupons);
    end if;
    if create_sale_bill.points_earned is not null then
        if round((create_sale_bill.amount / 100.00)::numeric, 2)::float <> create_sale_bill.points_earned then
            raise exception 'Invalid customer earn points';
        end if;
        update customer
        set loyalty_point = customer.loyalty_point + create_sale_bill.points_earned
        where id = create_sale_bill.customer
          and enable_loyalty_point = true;
    end if;

    select *
    into v_voucher
    FROM
        create_voucher(date := create_sale_bill.date, branch := create_sale_bill.branch,
                       branch_gst := create_sale_bill.branch_gst,
                       party_gst := create_sale_bill.party_gst,
                       voucher_type := create_sale_bill.voucher_type,
                       ref_no := create_sale_bill.ref_no,
                       description := create_sale_bill.description, mode := 'INVENTORY',
                       amount := create_sale_bill.amount, ac_trns := create_sale_bill.ac_trns,
                       eff_date := create_sale_bill.eff_date, lut := create_sale_bill.lut,
                       unique_session := create_sale_bill.unique_session,
                       pos_counter_id := create_sale_bill.pos_counter_id,
                       counter_trns := create_sale_bill.counter_trns
        );
    if v_voucher.base_voucher_type != 'SALE' then
        raise exception 'Allowed only SALE voucher type';
    end if;
    if (jsonb_array_length(coalesce(create_sale_bill.exchange_adjs, '[]'::jsonb)) > 0) or
       (jsonb_array_length(coalesce(create_sale_bill.advance_adjs, '[]'::jsonb)) > 0) then
        select *
        into _fn_res
        from claim_exchange(exchange_adjs := create_sale_bill.exchange_adjs,
                            advance_adjs := create_sale_bill.advance_adjs,
                            v_branch := v_voucher.branch_id, v_voucher_id := v_voucher.id,
                            v_voucher_no := v_voucher.voucher_no, v_base_voucher_type := v_voucher.base_voucher_type,
                            v_date := v_voucher.date);
        if not FOUND then
            raise exception 'invalid claim_exchange';
        end if;
    end if;
    select * into war from warehouse where id = create_sale_bill.warehouse;
    select * into cust from customer where id = create_sale_bill.customer;
    insert into sale_bill (voucher_id, date, eff_date, branch_id, branch_name, warehouse_id, base_voucher_type,
                           voucher_type_id, voucher_no, voucher_prefix, voucher_fy, voucher_seq, lut, ref_no,
                           customer_id, customer_name, doctor_id, customer_group_id, description, branch_gst, party_gst,
                           emi_detail, delivery_info, ac_trns, bank_account_id, cash_account_id, eft_account_id,
                           credit_account_id, exchange_adjs, advance_adjs, bank_amount, cash_amount, eft_amount,
                           credit_amount, gift_voucher_coupons, gift_voucher_amount, exchange_amount, advance_amount,
                           amount, discount_amount, rounded_off, points_earned, pos_counter_id)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name,
            create_sale_bill.warehouse, v_voucher.base_voucher_type, v_voucher.voucher_type_id, v_voucher.voucher_no,
            v_voucher.voucher_prefix, v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.lut, v_voucher.ref_no,
            create_sale_bill.customer, cust.name, create_sale_bill.doctor, create_sale_bill.customer_group,
            v_voucher.description, v_voucher.branch_gst, v_voucher.party_gst, create_sale_bill.emi_detail,
            create_sale_bill.delivery_info, create_sale_bill.ac_trns, create_sale_bill.bank_account,
            create_sale_bill.cash_account, create_sale_bill.eft_account, create_sale_bill.credit_account,
            create_sale_bill.exchange_adjs, create_sale_bill.advance_adjs, create_sale_bill.bank_amount,
            create_sale_bill.cash_amount, create_sale_bill.eft_amount, create_sale_bill.credit_amount,
            create_sale_bill.gift_voucher_coupons, create_sale_bill.gift_voucher_amount,
            create_sale_bill.exchange_amount, create_sale_bill.advance_amount, create_sale_bill.amount,
            create_sale_bill.discount_amount, create_sale_bill.rounded_off, create_sale_bill.points_earned,
            create_sale_bill.pos_counter_id)
    returning * into v_sale_bill;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select * into div from division where id = inv.division_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_voucher.branch_id,
                           warehouse := v_sale_bill.warehouse_id);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, item.qty * item.unit_conv * loose,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_sale_bill.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_sale_bill.warehouse_id, war.name);
            select array_agg(distinct drug_category)
            into drugs_cat
            from pharma_salt
            where id = any (inv.salts)
              and drug_category is not null;
            insert into sale_bill_inv_item (id, sale_bill_id, batch_id, inventory_id, unit_id, unit_conv, gst_tax_id,
                                            qty, is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc_mode,
                                            discount, s_inc_id, taxable_amount, asset_amount, cgst_amount, sgst_amount,
                                            igst_amount, cess_amount, drug_classifications)
            values (item.id, v_sale_bill.id, item.batch_id, item.inventory_id, item.unit_id, item.unit_conv,
                    item.gst_tax_id, item.qty, item.is_loose_qty, item.rate, item.hsn_code, item.cess_on_qty,
                    item.cess_on_val, item.disc_mode, item.discount, item.s_inc_id, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    drugs_cat);
        end loop;
    return v_sale_bill;
end;
$$ language plpgsql security definer;
--##
create function update_sale_bill(
    v_id int,
    date date,
    inv_items jsonb,
    ac_trns jsonb,
    party_gst JSON default null,
    eff_date date default null,
    ref_no text default null,
    description text default null,
    emi_detail json default null,
    delivery_info json default null,
    amount float default null,
    discount_amount float default null,
    cash_amount float default null,
    credit_amount float default null,
    bank_amount float default null,
    eft_amount float default null,
    cash_account int default null,
    credit_account int default null,
    bank_account int default null,
    eft_account int default null,
    rounded_off float default null,
    customer int default null,
    customer_group int default null,
    doctor int default null,
    counter_trns jsonb default null,
    lut boolean default false
)
    returns sale_bill AS
$$
declare
    v_sale_bill      sale_bill;
    v_voucher        voucher;
    item             sale_bill_inv_item;
    items            sale_bill_inv_item[] := (select array_agg(x)
                                              from jsonb_populate_recordset(
                                                           null::sale_bill_inv_item,
                                                           update_sale_bill.inv_items) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    cust             customer;
    loose            int;
    missed_items_ids uuid[];
    drugs_cat        typ_drug_category[];
begin
    select * into cust from customer where id = update_sale_bill.customer;
    update sale_bill
    set date              = update_sale_bill.date,
        eff_date          = update_sale_bill.eff_date,
        ref_no            = update_sale_bill.ref_no,
        description       = update_sale_bill.description,
        amount            = update_sale_bill.amount,
        ac_trns           = update_sale_bill.ac_trns,
        customer_id       = update_sale_bill.customer,
        customer_name     = cust.name,
        party_gst         = update_sale_bill.party_gst,
        discount_amount   = update_sale_bill.discount_amount,
        rounded_off       = update_sale_bill.rounded_off,
        emi_detail        = update_sale_bill.emi_detail,
        delivery_info     = update_sale_bill.delivery_info,
        cash_amount       = update_sale_bill.cash_amount,
        credit_amount     = update_sale_bill.credit_amount,
        bank_amount       = update_sale_bill.bank_amount,
        eft_amount        = update_sale_bill.eft_amount,
        cash_account_id   = update_sale_bill.cash_account,
        credit_account_id = update_sale_bill.credit_account,
        bank_account_id   = update_sale_bill.bank_account,
        eft_account_id    = update_sale_bill.eft_account,
        customer_group_id = update_sale_bill.customer_group,
        doctor_id         = update_sale_bill.doctor,
        lut               = update_sale_bill.lut,
        updated_at        = current_timestamp
    where id = $1
    returning * into v_sale_bill;
    if not FOUND then
        raise exception 'Sale bill not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(id := v_sale_bill.voucher_id, date := v_sale_bill.date,
                       branch_gst := v_sale_bill.branch_gst,
                       party_gst := v_sale_bill.party_gst, ref_no := v_sale_bill.ref_no,
                       description := v_sale_bill.description, amount := v_sale_bill.amount,
                       ac_trns := v_sale_bill.ac_trns, eff_date := v_sale_bill.eff_date,
                       lut := v_sale_bill.lut, counter_trns := update_sale_bill.counter_trns
        );
    select array_agg(id)
    into missed_items_ids
    from ((select id, inventory_id, batch_id
           from sale_bill_inv_item
           where sale_bill_id = $1)
          except
          (select id, inventory_id, batch_id
           from unnest(items)));
    delete from sale_bill_inv_item where id = any (missed_items_ids);
    select * into war from warehouse where id = v_sale_bill.warehouse_id;
    foreach item in array items
        loop
            select * into inv from inventory where id = item.inventory_id;
            select * into div from division where id = inv.division_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_sale_bill.branch_id,
                           warehouse := v_sale_bill.warehouse_id);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, item.qty * item.unit_conv * loose,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_sale_bill.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_sale_bill.warehouse_id, war.name)
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
                    customer_id       = excluded.customer_id,
                    customer_name     = excluded.customer_name,
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
            select array_agg(distinct drug_category)
            into drugs_cat
            from pharma_salt
            where id = any (inv.salts)
              and drug_category is not null;
            insert into sale_bill_inv_item (id, sale_bill_id, batch_id, inventory_id, unit_id, unit_conv, gst_tax_id,
                                            qty, is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc_mode,
                                            discount, s_inc_id, taxable_amount, asset_amount, cgst_amount, sgst_amount,
                                            igst_amount, cess_amount, drug_classifications)
            values (item.id, v_sale_bill.id, item.batch_id, item.inventory_id, item.unit_id, item.unit_conv,
                    item.gst_tax_id, item.qty, item.is_loose_qty, item.rate, item.hsn_code, item.cess_on_qty,
                    item.cess_on_val, item.disc_mode, item.discount, item.s_inc_id, item.taxable_amount,
                    item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount, item.cess_amount,
                    drugs_cat)
            on conflict (id) do update
                set unit_id              = excluded.unit_id,
                    unit_conv            = excluded.unit_conv,
                    gst_tax_id           = excluded.gst_tax_id,
                    qty                  = excluded.qty,
                    is_loose_qty         = excluded.is_loose_qty,
                    rate                 = excluded.rate,
                    hsn_code             = excluded.hsn_code,
                    disc_mode            = excluded.disc_mode,
                    discount             = excluded.discount,
                    cess_on_val          = excluded.cess_on_val,
                    cess_on_qty          = excluded.cess_on_qty,
                    taxable_amount       = excluded.taxable_amount,
                    cgst_amount          = excluded.cgst_amount,
                    sgst_amount          = excluded.sgst_amount,
                    igst_amount          = excluded.igst_amount,
                    cess_amount          = excluded.cess_amount,
                    drug_classifications = excluded.drug_classifications,
                    s_inc_id             = excluded.s_inc_id;
        end loop;
    return v_sale_bill;
end;
$$ language plpgsql security definer;
--##
create function delete_sale_bill(id int)
    returns void as
$$
declare
    voucher_id int;
begin
    delete from sale_bill where sale_bill.id = $1 returning voucher_id into voucher_id;
    delete from voucher where voucher.id = voucher_id;
    if not FOUND then
        raise exception 'Invalid sale_bill';
    end if;
end;
$$ language plpgsql security definer;
