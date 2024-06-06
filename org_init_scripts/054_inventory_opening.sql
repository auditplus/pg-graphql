create table if not exists inventory_opening
(
    id           uuid    not null primary key,
    branch_id    int     not null,
    inventory_id int     not null,
    warehouse_id int     not null,
    unit_id      int     not null,
    unit_conv    float   not null,
    qty          float   not null,
    nlc          float   not null default 0,
    cost         float   not null default 0,
    rate         float   not null,
    is_loose_qty boolean not null default false,
    landing_cost float,
    mrp          float,
    s_rate       float,
    batch_no     text,
    expiry       date,
    category     json,
    asset_amount float,
    unique (branch_id, inventory_id, warehouse_id, id)
);
--##
create function set_inventory_opening(
    inventory int,
    branch int,
    warehouse int,
    inv_items jsonb
)
    returns setof inventory_opening as
$$
declare
    item             inventory_opening;
    items            inventory_opening[] := (select array_agg(x)
                                             from jsonb_populate_recordset(
                                                          null::inventory_opening,
                                                          $4) as x);
    inv              inventory;
    bat              batch;
    div              division;
    war              warehouse;
    br               branch;
    en_date          date                := (select book_begin - 1
                                             from organization
                                             limit 1);
    missed_items_ids uuid[];
    loose            int;
    asset_amt        float;
begin
    if items is null or array_length(items, 1) = 0 then
        delete from inv_txn where inventory_id = $1 and branch_id = $2 and warehouse_id = $3 and is_opening = true;
        delete from inventory_opening where inventory_id = $1 and branch_id = $2 and warehouse_id = $3;
        delete from batch where inventory_id = $1 and branch_id = $2 and warehouse_id = $3 and entry_type = 'OPENING';
        select sum(asset_amount)
        into asset_amt
        from inv_txn
        where inv_txn.branch_id = $2
          and is_opening = true;
        update ac_txn set debit = coalesce(asset_amt, 0) where branch_id = $2 and account_id = 16 and is_opening = true;
        return;
    end if;
    select * into inv from inventory where id = $1;
    select * into div from division where id = inv.division_id;
    select * into br from branch where id = $2;
    select * into war from warehouse where id = $3;
    select array_agg(id)
    into missed_items_ids
    from ((select id
           from inventory_opening
           where inventory_opening.inventory_id = $1
             and inventory_opening.branch_id = $2
             and inventory_opening.warehouse_id = $3)
          except
          (select id
           from unnest(items)));
    delete from inv_txn where id = any (missed_items_ids);
    delete from inventory_opening where id = any (missed_items_ids);
    foreach item in array items
        loop
            if item.is_loose_qty then
                loose = 1;
            else
                loose = inv.loose_qty;
            end if;
            insert into inventory_opening (id, inventory_id, branch_id, warehouse_id, unit_id, unit_conv, qty, nlc,
                                           cost, rate,
                                           is_loose_qty, landing_cost, mrp, s_rate, batch_no, expiry, category,
                                           asset_amount)
            values (item.id, $1, $2, $3, item.unit_id, item.unit_conv, item.qty, item.nlc, item.cost, item.rate,
                    item.is_loose_qty, item.landing_cost, item.mrp, item.s_rate, item.batch_no, item.expiry,
                    item.category, item.asset_amount)
            on conflict (id) do update
                set unit_id      = excluded.unit_id,
                    unit_conv    = excluded.unit_conv,
                    qty          = excluded.qty,
                    is_loose_qty = excluded.is_loose_qty,
                    rate         = excluded.rate,
                    landing_cost = excluded.landing_cost,
                    nlc          = excluded.nlc,
                    cost         = excluded.cost,
                    mrp          = excluded.mrp,
                    expiry       = excluded.expiry,
                    s_rate       = excluded.s_rate,
                    batch_no     = excluded.batch_no,
                    category     = excluded.category,
                    asset_amount = excluded.asset_amount;
            insert into batch (txn_id, inventory_id, reorder_inventory_id, inventory_name, inventory_hsn, branch_id,
                               branch_name, warehouse_id, warehouse_name, division_id, division_name, entry_type,
                               batch_no, expiry, entry_date, mrp, s_rate, p_rate, landing_cost, nlc, cost, unit_id,
                               unit_conv, manufacturer_id, manufacturer_name, loose_qty, label_qty, category1_id,
                               category2_id, category3_id, category4_id, category5_id, category6_id, category7_id,
                               category8_id, category9_id, category10_id)
            values (item.id, $1, coalesce(inv.reorder_inventory_id, $1), inv.name, inv.hsn_code, $2, br.name, $3,
                    war.name, div.id, div.name, 'OPENING', item.batch_no, item.expiry, en_date, item.mrp, item.s_rate,
                    item.rate, item.landing_cost, item.nlc, item.cost, item.unit_id, item.unit_conv,
                    inv.manufacturer_id, inv.manufacturer_name, inv.loose_qty, item.qty * item.unit_conv,
                    (item.category ->> 'category1_id')::int, (item.category ->> 'category2_id')::int,
                    (item.category ->> 'category3_id')::int, (item.category ->> 'category4_id')::int,
                    (item.category ->> 'category5_id')::int, (item.category ->> 'category6_id')::int,
                    (item.category ->> 'category7_id')::int, (item.category ->> 'category8_id')::int,
                    (item.category ->> 'category9_id')::int, (item.category ->> 'category10_id')::int)
            on conflict (txn_id) do update
                set inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    batch_no          = excluded.batch_no,
                    expiry            = excluded.expiry,
                    entry_date        = excluded.entry_date,
                    label_qty         = excluded.label_qty,
                    mrp               = excluded.mrp,
                    p_rate            = excluded.p_rate,
                    s_rate            = excluded.s_rate,
                    nlc               = excluded.nlc,
                    cost              = excluded.cost,
                    landing_cost      = excluded.landing_cost,
                    unit_conv         = excluded.unit_conv,
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
                    category10_id     = excluded.category10_id
            returning * into bat;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                inward, asset_amount, category1_id, category1_name, category2_id, category2_name,
                                category3_id, category3_name, category4_id, category4_name, category5_id,
                                category5_name, category6_id, category6_name, category7_id, category7_name,
                                category8_id, category8_name, category9_id, category9_name, category10_id,
                                category10_name, warehouse_id, warehouse_name, is_opening, nlc)
            values (item.id, en_date, $2, div.id, div.name, br.name, bat.id, $1, coalesce(inv.reorder_inventory_id, $1),
                    inv.name, inv.hsn_code, inv.manufacturer_id, inv.manufacturer_name,
                    item.qty * item.unit_conv * loose, item.asset_amount, bat.category1_id, bat.category1_name,
                    bat.category2_id, bat.category2_name, bat.category3_id, bat.category3_name, bat.category4_id,
                    bat.category4_name, bat.category5_id, bat.category5_name, bat.category6_id, bat.category6_name,
                    bat.category7_id, bat.category7_name, bat.category8_id, bat.category8_name, bat.category9_id,
                    bat.category9_name, bat.category10_id, bat.category10_name, bat.warehouse_id, bat.warehouse_name,
                    true, item.nlc)
            on conflict (id) do update
                set inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    inward            = excluded.inward,
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
                    category10_name   = excluded.category10_name;
        end loop;
    select sum(asset_amount)
    into asset_amt
    from inv_txn
    where inv_txn.branch_id = $2
      and is_opening = true;
    update ac_txn set debit = coalesce(asset_amt, 0) where branch_id = $2 and account_id = 16 and is_opening = true;
    if not FOUND then
        insert into ac_txn(id, date, account_id, credit, debit, account_name, account_type_id, branch_id, branch_name,
                           is_opening)
        values (gen_random_uuid(), en_date, 16, 0.0, coalesce(asset_amt, 0), 'Inventory Asset', 'STOCK', $2, br.name,
                true);
    end if;
    return query select *
                 from inventory_opening
                 where inventory_opening.inventory_id = $1
                   and inventory_opening.branch_id = $2
                   and inventory_opening.warehouse_id = $3;
end;
$$ language plpgsql security definer;