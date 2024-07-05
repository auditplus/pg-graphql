create table if not exists inventory_opening
(
    id           uuid    not null primary key,
    branch_id    int  not null,
    inventory_id int  not null,
    warehouse_id int  not null,
    unit_id      int  not null,
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
    asset_amount float,
    unique (branch_id, inventory_id, warehouse_id, id)
);
--##
create function set_inventory_opening(input_data json)
    returns bool as
$$
declare
    input            jsonb               := json_convert_case($1::jsonb, 'snake_case');
    item             inventory_opening;
    items            inventory_opening[] := (select array_agg(x)
                                             from jsonb_populate_recordset(
                                                          null::inventory_opening,
                                                          (input ->> 'inv_items')::jsonb) as x);
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
    if items is null or coalesce(array_length(items, 1), 0) = 0 then
        delete
        from inv_txn
        where inventory_id = (input ->> 'inventory_id')::int
          and branch_id = (input ->> 'branch_id')::int
          and warehouse_id = (input ->> 'warehouse_id')::int
          and is_opening = true;
        delete
        from inventory_opening
        where inventory_id = (input ->> 'inventory_id')::int
          and branch_id = (input ->> 'branch_id')::int
          and warehouse_id = (input ->> 'warehouse_id')::int;
        delete
        from batch
        where inventory_id = (input ->> 'inventory_id')::int
          and branch_id = (input ->> 'branch_id')::int
          and warehouse_id = (input ->> 'warehouse_id')::int
          and entry_type = 'OPENING';
        select sum(asset_amount)
        into asset_amt
        from inv_txn
        where inv_txn.branch_id = (input ->> 'branch_id')::int
          and is_opening = true;
        update ac_txn
        set debit = coalesce(asset_amt, 0)
        where branch_id = (input ->> 'branch_id')::int
          and account_id = 16
          and is_opening = true;
        return true;
    end if;
    select * into inv from inventory where id = (input ->> 'inventory_id')::int;
    select * into div from division where id = inv.division_id;
    select * into br from branch where id = (input ->> 'branch_id')::int;
    select * into war from warehouse where id = (input ->> 'warehouse_id')::int;
    select array_agg(id)
    into missed_items_ids
    from ((select id
           from inventory_opening
           where inventory_opening.inventory_id = (input ->> 'inventory_id')::int
             and inventory_opening.branch_id = (input ->> 'branch_id')::int
             and inventory_opening.warehouse_id = (input ->> 'warehouse_id')::int)
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
                                           cost, rate, is_loose_qty, landing_cost, mrp, s_rate, batch_no, expiry,
                                           asset_amount)
            values (coalesce(item.id, gen_random_uuid()), (input ->> 'inventory_id')::int,
                    (input ->> 'branch_id')::int, (input ->> 'warehouse_id')::int, item.unit_id, item.unit_conv,
                    item.qty, item.nlc, item.cost, item.rate, item.is_loose_qty, item.landing_cost, item.mrp,
                    item.s_rate, item.batch_no, item.expiry, item.asset_amount)
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
                    asset_amount = excluded.asset_amount
            returning * into item;
            insert into batch (txn_id, inventory_id, reorder_inventory_id, inventory_name, inventory_hsn, branch_id,
                               branch_name, warehouse_id, warehouse_name, division_id, division_name, entry_type,
                               batch_no, expiry, entry_date, mrp, s_rate, p_rate, landing_cost, nlc, cost, unit_id,
                               unit_conv, manufacturer_id, manufacturer_name, loose_qty, label_qty)
            values (item.id, (input ->> 'inventory_id')::int,
                    coalesce(inv.reorder_inventory_id, (input ->> 'inventory_id')::int), inv.name, inv.hsn_code,
                    (input ->> 'branch_id')::int, br.name, (input ->> 'warehouse_id')::int, war.name, div.id,
                    div.name, 'OPENING', item.batch_no, item.expiry, en_date, item.mrp, item.s_rate, item.rate,
                    item.landing_cost, item.nlc, item.cost, item.unit_id, item.unit_conv, inv.manufacturer_id,
                    inv.manufacturer_name, inv.loose_qty, item.qty * item.unit_conv)
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
                    manufacturer_name = excluded.manufacturer_name
            returning * into bat;
            insert into inv_txn(id, date, branch_id, division_id, division_name, branch_name, batch_id, inventory_id,
                                reorder_inventory_id, inventory_name, inventory_hsn, manufacturer_id, manufacturer_name,
                                inward, asset_amount, warehouse_id, warehouse_name, is_opening, nlc)
            values (item.id, en_date, (input ->> 'branch_id')::int, div.id, div.name, br.name, bat.id,
                    (input ->> 'inventory_id')::int,
                    coalesce(inv.reorder_inventory_id, (input ->> 'inventory_id')::int), inv.name, inv.hsn_code,
                    inv.manufacturer_id, inv.manufacturer_name, item.qty * item.unit_conv * loose, item.asset_amount,
                    bat.warehouse_id, bat.warehouse_name, true, item.nlc)
            on conflict (id) do update
                set inventory_name    = excluded.inventory_name,
                    inventory_hsn     = excluded.inventory_hsn,
                    branch_name       = excluded.branch_name,
                    division_name     = excluded.division_name,
                    warehouse_name    = excluded.warehouse_name,
                    inward            = excluded.inward,
                    asset_amount      = excluded.asset_amount,
                    manufacturer_id   = excluded.manufacturer_id,
                    manufacturer_name = excluded.manufacturer_name;
        end loop;
    select sum(asset_amount)
    into asset_amt
    from inv_txn
    where inv_txn.branch_id = (input ->> 'branch_id')::int
      and is_opening = true;
    update ac_txn
    set debit = coalesce(asset_amt, 0)
    where branch_id = (input ->> 'branch_id')::int
      and account_id = 16
      and is_opening = true;
    if not FOUND then
        insert into ac_txn(id, date, account_id, credit, debit, account_name, base_account_types, branch_id,
                           branch_name, is_opening)
        values (gen_random_uuid(), en_date, 16, 0.0, coalesce(asset_amt, 0), 'Inventory Asset', array ['STOCK'],
                (input ->> 'branch_id')::int, br.name, true);
    end if;

    return true;
end;
$$ language plpgsql security definer;