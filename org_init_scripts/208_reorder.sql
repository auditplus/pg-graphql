
create function generate_reorder(
    branch int,
    as_on_date date,
    days int,
    factor float
)
    returns bool
as
$$
declare
    from_date date := $2 - format('%s days', $3)::interval;
begin

    with s1 as (select reorder_inventory_id,
                       (sum(outward) * $4) as order_level
                from inv_txn
                where base_voucher_type in ('SALE', 'CREDIT_NOTE')
                  and (date between from_date and $2)
                  and branch_id = $1
                group by reorder_inventory_id)
    update inventory_branch_detail as ibd
    set reorder_level = s1.order_level
    from s1
    where ibd.branch_id = $1
      and ibd.inventory_id = s1.reorder_inventory_id
      and ibd.reorder_mode = 'DYNAMIC';

    return true;
end;
$$ language plpgsql;
--##
create function set_reorder(
    branch int,
    input jsonb
)
    returns bool
as
$$
begin
    with s1 as (select (j ->> 'inventory')::integer                                                    as inventory,
                       coalesce((j ->> 'reorder_mode')::typ_reorder_mode, 'DYNAMIC'::typ_reorder_mode) as reorder_mode,
                       coalesce((j ->> 'reorder_level')::float, 0.0)                                   as reorder_level,
                       (j ->> 'min_order')::float                                                      as min_order,
                       (j ->> 'max_order')::float                                                      as max_order
                from jsonb_array_elements($2) j)
    update inventory_branch_detail as ibd
    set reorder_level = s1.reorder_level,
        reorder_mode  = s1.reorder_mode,
        min_order     = s1.min_order,
        max_order     = s1.max_order
    from s1
    where ibd.branch_id = $1
      and s1.inventory = ibd.inventory_id;

    return true;
end;
$$ language plpgsql;
--##
create or replace function get_reorder(
    br_id int,
    as_on_date date,
    days int,
    factor float,
    expiry_days int default null
)
    returns table
            (
                branch            int,
                branch_name       text,
                inventory         int,
                inventory_name    text,
                manufacturer      int,
                manufacturer_name text,
                vendor            int,
                vendor_name       text,
                unit              int,
                unit_name         text,
                loose_qty         int,
                order_level       float,
                stock             float
            )
as
$$
declare
    from_date   date := $2 - format('%s days', $3)::interval;
    expiry_date date := $2 + format('%s days', coalesce($5, 0))::interval;
begin

    return query
        with s1 as (SELECT reorder_inventory_id,
                           (sum(outward) * $4) as order_level
                    from inv_txn
                    where base_voucher_type in ('SALE', 'CREDIT_NOTE')
                      and (date between from_date and $2)
                      and inv_txn.branch_id = $1
                    group by reorder_inventory_id),
             s2 as (select min(b.branch_id)      as brn,
                           min(b.branch_name)    as brn_name,
                           b.reorder_inventory_id,
                           sum(s1.order_level)   as ord_level,
                           sum(inward - outward) as stock
                    from batch as b
                             right join s1 on b.reorder_inventory_id = s1.reorder_inventory_id
                    where b.branch_id = $1
                      and (case
                               when $5 is null then true
                               else ((b.expiry is null) or (b.expiry > expiry_date)) end)
                    group by b.reorder_inventory_id)
        select s2.brn,
               s2.brn_name,
               s2.reorder_inventory_id,
               i.name as inventory_name,
               i.manufacturer_id,
               i.manufacturer_name,
               i.vendor_id,
               i.vendor_name,
               i.unit_id,
               u.name as unit_name,
               i.loose_qty,
               s2.ord_level,
               s2.stock
        from s2
                 left join inventory as i on s2.reorder_inventory_id = i.id
                 left join unit as u on i.unit_id = u.id
        where (s2.ord_level - s2.stock) > 0;
end
$$ language plpgsql;