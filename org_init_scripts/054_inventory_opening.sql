create table if not exists inventory_opening
(
    id           uuid    not null primary key,
    branch       int     not null,
    inventory    int     not null,
    warehouse    int     not null,
    unit         int     not null,
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
    unique (branch, inventory, warehouse, id)
);
--##
create function set_inventory_opening(
    inv_id int,
    br_id int,
    war_id int,
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
        delete from inv_txn where inventory = $1 and branch = $2 and warehouse = $3 and is_opening = true;
        delete from inventory_opening where inventory = $1 and branch = $2 and warehouse = $3;
        delete from batch where inventory = $1 and branch = $2 and warehouse = $3 and entry_type = 'OPENING';
        select sum(asset_amount)
        into asset_amt
        from inv_txn
        where inv_txn.branch = $2
          and is_opening = true;
        update ac_txn set debit = coalesce(asset_amt, 0) where branch = $2 and account = 16 and is_opening = true;
        return;
    end if;
    select * into inv from inventory where id = $1;
    select * into div from division where id = inv.division;
    select * into br from branch where id = $2;
    select * into war from warehouse where id = $3;
    select array_agg(id)
    into missed_items_ids
    from ((select id
           from inventory_opening
           where inventory_opening.inventory = $1
             and inventory_opening.branch = $2
             and inventory_opening.warehouse = $3)
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
            insert into inventory_opening (id, inventory, branch, warehouse, unit, unit_conv, qty, nlc, cost, rate,
                                           is_loose_qty, landing_cost, mrp, s_rate, batch_no, expiry, category,
                                           asset_amount)
            values (item.id, $1, $2, $3, item.unit, item.unit_conv, item.qty, item.nlc, item.cost, item.rate,
                    item.is_loose_qty, item.landing_cost, item.mrp, item.s_rate, item.batch_no, item.expiry,
                    item.category, item.asset_amount)
            on conflict (id) do update
                set unit         = excluded.unit,
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
            insert into batch (txn_id, inventory, inventory_name, inventory_hsn, branch, branch_name, warehouse,
                               warehouse_name, division, division_name, entry_type, batch_no, expiry, entry_date, mrp,
                               s_rate, p_rate, landing_cost, nlc, cost, unit_id, unit_conv, manufacturer,
                               manufacturer_name, loose_qty, category1, category2, category3, category4, category5,
                               category6, category7, category8, category9, category10, label_qty)
            values (item.id, $1, inv.name, inv.hsn_code, $2, br.name, $3, war.name, div.id, div.name, 'OPENING',
                    item.batch_no, item.expiry, en_date, item.mrp, item.s_rate, item.rate, item.landing_cost, item.nlc,
                    item.cost, item.unit, item.unit_conv, inv.manufacturer, inv.manufacturer_name, inv.loose_qty,
                    (item.category ->> 'category1')::int, (item.category ->> 'category2')::int,
                    (item.category ->> 'category3')::int, (item.category ->> 'category4')::int,
                    (item.category ->> 'category5')::int, (item.category ->> 'category6')::int,
                    (item.category ->> 'category7')::int, (item.category ->> 'category8')::int,
                    (item.category ->> 'category9')::int, (item.category ->> 'category10')::int,
                    item.qty * item.unit_conv)
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
                    manufacturer      = excluded.manufacturer,
                    manufacturer_name = excluded.manufacturer_name,
                    category1         = excluded.category1,
                    category2         = excluded.category2,
                    category3         = excluded.category3,
                    category4         = excluded.category4,
                    category5         = excluded.category5,
                    category6         = excluded.category6,
                    category7         = excluded.category7,
                    category8         = excluded.category8,
                    category9         = excluded.category9,
                    category10        = excluded.category10
            returning * into bat;
            insert into inv_txn(id, date, branch, division, division_name, branch_name, batch, inventory,
                                reorder_inventory, inventory_name, inventory_hsn, manufacturer, manufacturer_name,
                                inward, asset_amount, category1, category1_name, category2, category2_name, category3,
                                category3_name, category4, category4_name, category5, category5_name, category6,
                                category6_name, category7, category7_name, category8, category8_name, category9,
                                category9_name, category10, category10_name, warehouse, warehouse_name, is_opening, nlc)
            values (item.id, en_date, $2, div.id, div.name, br.name, bat.id, $1, coalesce(inv.reorder_inventory, $1),
                    inv.name, inv.hsn_code, inv.manufacturer, inv.manufacturer_name, item.qty * item.unit_conv * loose,
                    item.asset_amount, bat.category1, bat.category1_name, bat.category2, bat.category2_name,
                    bat.category3, bat.category3_name, bat.category4, bat.category4_name, bat.category5,
                    bat.category5_name, bat.category6, bat.category6_name, bat.category7, bat.category7_name,
                    bat.category8, bat.category8_name, bat.category9, bat.category9_name, bat.category10,
                    bat.category10_name, bat.warehouse, bat.warehouse_name, true, item.nlc)
            on conflict (id) do update
                set inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    inward            = excluded.inward,
                    asset_amount      = excluded.asset_amount,
                    manufacturer      = excluded.manufacturer,
                    manufacturer_name = excluded.manufacturer_name,
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
                    category10_name   = excluded.category10_name;
        end loop;
    select sum(asset_amount)
    into asset_amt
    from inv_txn
    where inv_txn.branch = $2
      and is_opening = true;
    update ac_txn set debit = coalesce(asset_amt, 0) where branch = $2 and account = 16 and is_opening = true;
    if not FOUND then
        insert into ac_txn(id, date, account, credit, debit, account_name, account_type, branch, branch_name,
                           is_opening)
        values (gen_random_uuid(), en_date, 16, 0.0, coalesce(asset_amt, 0), 'Inventory Asset', 'STOCK', $2, br.name,
                true);
    end if;
    return query select *
                 from inventory_opening
                 where inventory_opening.inventory = $1
                   and inventory_opening.branch = $2
                   and inventory_opening.warehouse = $3;
end;
$$ language plpgsql security definer;