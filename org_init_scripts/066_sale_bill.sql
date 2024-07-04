create table if not exists sale_bill
(
    id                   bigserial         not null primary key,
    voucher_id           bigint            not null,
    date                 date              not null,
    eff_date             date,
    branch_id            bigint            not null,
    branch_name          text              not null,
    warehouse_id         bigint            not null,
    base_voucher_type    base_voucher_type not null,
    voucher_type_id      bigint            not null,
    voucher_no           text              not null,
    voucher_prefix       text              not null,
    voucher_fy           int               not null,
    voucher_seq          bigint            not null,
    lut                  boolean           not null default false,
    ref_no               text,
    gift_voucher_coupons jsonb,
    customer_id          bigint,
    customer_name        text,
    doctor_id            bigint,
    customer_group_id    bigint,
    description          text,
    branch_gst           json              not null,
    party_gst            json,
    emi_detail           json,
    delivery_info        json,
    bank_account_id      bigint,
    cash_account_id      bigint,
    eft_account_id       bigint,
    credit_account_id    bigint,
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
    pos_counter_id       bigint,
    created_at           timestamp         not null default current_timestamp,
    updated_at           timestamp         not null default current_timestamp
);
--##
create function create_sale_bill(input_data json, unique_session uuid default null)
    returns sale_bill as
$$
declare
    v_sale_bill sale_bill;
    v_voucher   voucher;
    item        sale_bill_inv_item;
    items       sale_bill_inv_item[] := (select array_agg(x)
                                         from jsonb_populate_recordset(
                                                      null::sale_bill_inv_item,
                                                      ($1 ->> 'inv_items')::jsonb) as x);
    inv         inventory;
    bat         batch;
    div         division;
    war         warehouse            := (select warehouse
                                         from warehouse
                                         where id = ($1 ->> 'warehouse_id')::bigint);
    cust        account              := (select account
                                         from account
                                         where id = ($1 ->> 'customer_id')::bigint
                                           and contact_type = 'CUSTOMER');
    loose       int;
    drugs_cat   text[];
    _fn_res     boolean;
begin
    if jsonb_array_length(coalesce(($1 ->> 'gift_voucher_coupons')::jsonb, '[]'::jsonb)) > 0 then
        select * into _fn_res from claim_gift_coupon(($1 ->> 'gift_voucher_coupons')::jsonb);
    end if;
    if $1 ->> 'points_earned' is not null then
        if round((($1 ->> 'amount')::float / 100.00)::numeric, 2)::float <> ($1 ->> 'points_earned')::float then
            raise exception 'Invalid customer earn points';
        end if;
        update account
        set loyalty_point = account.loyalty_point + ($1 ->> 'points_earned')::float
        where id = cust.id
          and enable_loyalty_point = true;
    end if;

    $1 = jsonb_set($1::jsonb, '{mode}', '"INVENTORY"');
    $1 = jsonb_set($1::jsonb, '{lut}', coalesce(($1 ->> 'lut')::bool, false)::text::jsonb);
    select * into v_voucher from create_voucher($1, $2);
    if v_voucher.base_voucher_type != 'SALE' then
        raise exception 'Allowed only SALE voucher type';
    end if;
    if (jsonb_array_length(coalesce(($1 ->> 'exchange_adjs')::jsonb, '[]'::jsonb)) > 0) or
       (jsonb_array_length(coalesce(($1 ->> 'advance_adjs')::jsonb, '[]'::jsonb)) > 0) then
        select *
        into _fn_res
        from claim_exchange(exchange_adjs := ($1 ->> 'exchange_adjs')::jsonb,
                            advance_adjs := ($1 ->> 'advance_adjs')::jsonb,
                            v_branch := v_voucher.branch_id, v_voucher_id := v_voucher.id,
                            v_voucher_no := v_voucher.voucher_no, v_base_voucher_type := v_voucher.base_voucher_type,
                            v_date := v_voucher.date);
        if not FOUND then
            raise exception 'invalid claim_exchange';
        end if;
    end if;
    select * into war from warehouse where id = ($1 ->> 'warehouse_id')::bigint;
    insert into sale_bill (voucher_id, date, eff_date, branch_id, branch_name, warehouse_id, base_voucher_type,
                           voucher_type_id, voucher_no, voucher_prefix, voucher_fy, voucher_seq, lut, ref_no,
                           customer_id, customer_name, doctor_id, customer_group_id, description, branch_gst, party_gst,
                           emi_detail, delivery_info, bank_account_id, cash_account_id, eft_account_id,
                           credit_account_id, exchange_adjs, advance_adjs, bank_amount, cash_amount, eft_amount,
                           credit_amount, gift_voucher_coupons, gift_voucher_amount, exchange_amount, advance_amount,
                           amount, discount_amount, rounded_off, points_earned, pos_counter_id)
    values (v_voucher.id, v_voucher.date, v_voucher.eff_date, v_voucher.branch_id, v_voucher.branch_name, war.id,
            v_voucher.base_voucher_type, v_voucher.voucher_type_id, v_voucher.voucher_no, v_voucher.voucher_prefix,
            v_voucher.voucher_fy, v_voucher.voucher_seq, v_voucher.lut, v_voucher.ref_no, cust.id, cust.name,
            ($1 ->> 'doctor_id')::bigint, ($1 ->> 'customer_group_id')::bigint, v_voucher.description,
            v_voucher.branch_gst, v_voucher.party_gst, ($1 ->> 'emi_detail')::json, ($1 ->> 'delivery_info')::json,
            ($1 ->> 'bank_account_id')::bigint, ($1 ->> 'cash_account_id')::bigint, ($1 ->> 'eft_account_id')::bigint,
            ($1 ->> 'credit_account_id')::bigint, ($1 ->> 'exchange_adjs')::jsonb, ($1 ->> 'advance_adjs')::jsonb,
            ($1 ->> 'bank_amount')::float, ($1 ->> 'cash_amount')::float, ($1 ->> 'eft_amount')::float,
            ($1 ->> 'credit_amount')::float, ($1 ->> 'gift_voucher_coupons')::jsonb,
            ($1 ->> 'gift_voucher_amount')::float, ($1 ->> 'exchange_amount')::float, ($1 ->> 'advance_amount')::float,
            ($1 ->> 'amount')::float, ($1 ->> 'discount_amount')::float, ($1 ->> 'rounded_off')::float,
            ($1 ->> 'points_earned')::float, ($1 ->> 'pos_counter_id')::bigint)
    returning * into v_sale_bill;
    foreach item in array coalesce(items, array []::sale_bill_inv_item[])
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
            select array_agg(distinct drug_category::text)
            into drugs_cat
            from pharma_salt
            where id = any (inv.salts)
              and drug_category is not null;
            insert into sale_bill_inv_item (id, sale_bill_id, batch_id, inventory_id, unit_id, unit_conv, gst_tax_id,
                                            qty, is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc_mode,
                                            discount, s_inc_id, taxable_amount, asset_amount, cgst_amount, sgst_amount,
                                            igst_amount, cess_amount, drug_classifications)
            values (coalesce(item.id, gen_random_uuid()), v_sale_bill.id, item.batch_id, item.inventory_id,
                    item.unit_id, item.unit_conv, item.gst_tax_id, item.qty, item.is_loose_qty, item.rate,
                    item.hsn_code, item.cess_on_qty, item.cess_on_val, item.disc_mode, item.discount, item.s_inc_id,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, drugs_cat)
            returning * into item;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, party_id, party_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, item.qty * item.unit_conv * loose,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_sale_bill.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_sale_bill.warehouse_id, war.name,
                    cust.id, cust.name);
        end loop;
    return v_sale_bill;
end;
$$ language plpgsql security definer;
--##
create function update_sale_bill(v_id bigint, input_data json)
    returns sale_bill as
$$
declare
    v_sale_bill      sale_bill;
    v_voucher        voucher;
    item             sale_bill_inv_item;
    items            sale_bill_inv_item[] := (select array_agg(x)
                                              from jsonb_populate_recordset(
                                                           null::sale_bill_inv_item,
                                                           ($2 -> 'inv_items')::jsonb) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    cust             account;
    loose            int;
    missed_items_ids uuid[];
    drugs_cat        text[];
begin
    select * into cust from account a where a.id = ($2 ->> 'customer_id')::bigint and contact_type = 'CUSTOMER';
    update sale_bill
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
        emi_detail        = ($2 ->> 'emi_detail')::json,
        delivery_info     = ($2 ->> 'delivery_info')::json,
        cash_amount       = ($2 ->> 'cash_amount')::float,
        credit_amount     = ($2 ->> 'credit_amount')::float,
        bank_amount       = ($2 ->> 'bank_amount')::float,
        eft_amount        = ($2 ->> 'eft_amount')::float,
        cash_account_id   = ($2 ->> 'cash_account_id')::bigint,
        credit_account_id = ($2 ->> 'credit_account_id')::bigint,
        bank_account_id   = ($2 ->> 'bank_account_id')::bigint,
        eft_account_id    = ($2 ->> 'eft_account_id')::bigint,
        customer_group_id = ($2 ->> 'customer_group_id')::bigint,
        doctor_id         = ($2 ->> 'doctor_id')::bigint,
        lut               = coalesce(($2 ->> 'lut')::bool, false),
        updated_at        = current_timestamp
    where sale_bill.id = $1
    returning * into v_sale_bill;
    if not FOUND then
        raise exception 'Sale bill not found';
    end if;
    select *
    into v_voucher
    from
        update_voucher(v_sale_bill.voucher_id, $2);
    select array_agg(_id)
    into missed_items_ids
    from ((select a.id as _id, a.inventory_id, a.batch_id
           from sale_bill_inv_item a
           where sale_bill_id = $1)
          except
          (select a.id as _id, a.inventory_id, a.batch_id
           from unnest(items) a));
    delete from sale_bill_inv_item a where a.id = any (missed_items_ids);
    select * into war from warehouse a where a.id = v_sale_bill.warehouse_id;
    foreach item in array items
        loop
            select * into inv from inventory a where a.id = item.inventory_id;
            select * into div from division a where a.id = inv.division_id;
            select *
            into bat
            from get_batch(batch := item.batch_id, inventory := item.inventory_id, branch := v_sale_bill.branch_id,
                           warehouse := v_sale_bill.warehouse_id);
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            select array_agg(distinct drug_category::text)
            into drugs_cat
            from pharma_salt a
            where a.id = any (inv.salts)
              and drug_category is not null;

            insert into sale_bill_inv_item (id, sale_bill_id, batch_id, inventory_id, unit_id, unit_conv, gst_tax_id,
                                            qty, is_loose_qty, rate, hsn_code, cess_on_qty, cess_on_val, disc_mode,
                                            discount, s_inc_id, taxable_amount, asset_amount, cgst_amount, sgst_amount,
                                            igst_amount, cess_amount, drug_classifications)
            values (coalesce(item.id, gen_random_uuid()), v_sale_bill.id, item.batch_id, item.inventory_id,
                    item.unit_id, item.unit_conv, item.gst_tax_id, item.qty, item.is_loose_qty, item.rate,
                    item.hsn_code, item.cess_on_qty, item.cess_on_val, item.disc_mode, item.discount, item.s_inc_id,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, drugs_cat)
            on conflict(id) do update
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
                    s_inc_id             = excluded.s_inc_id
            returning * into item;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                outward, taxable_amount, asset_amount, cgst_amount, sgst_amount, igst_amount,
                                cess_amount, ref_no, inventory_voucher_id, voucher_id, voucher_no, voucher_type_id,
                                base_voucher_type, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, party_id, party_name)
            values (item.id, v_voucher.date, v_voucher.branch_id, inv.division_id, div.name, v_voucher.branch_name,
                    item.batch_id, item.inventory_id, coalesce(inv.reorder_inventory_id, item.inventory_id), inv.name,
                    inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name, item.qty * item.unit_conv * loose,
                    item.taxable_amount, item.asset_amount, item.cgst_amount, item.sgst_amount, item.igst_amount,
                    item.cess_amount, v_voucher.ref_no, v_sale_bill.id, v_voucher.id, v_voucher.voucher_no,
                    v_voucher.voucher_type_id, v_voucher.base_voucher_type, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, v_sale_bill.warehouse_id, war.name,
                    cust.id, cust.name)
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
                    party_name        = excluded.party_id,
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
    return v_sale_bill;
end;
$$ language plpgsql security definer;
--##
create function delete_sale_bill(id bigint)
    returns void as
$$
declare
    voucher_id bigint;
begin
    delete from sale_bill where sale_bill.id = $1 returning voucher_id into voucher_id;
    delete from voucher where voucher.id = voucher_id;
    if not FOUND then
        raise exception 'Invalid sale_bill';
    end if;
end;
$$ language plpgsql security definer;
