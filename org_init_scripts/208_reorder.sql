create function generate_reorder(
    br_id int,
    as_on_date date,
    days int,
    factor float
)
returns bool
as
$$
declare
    from_date date := as_on_date - format('%s days',days)::interval;
begin

    with s1 as(
    SELECT
        branch, reorder_inventory, (sum(outward) * factor) as order_level
    from inv_txn
    where base_voucher_type in ('SALE','CREDIT_NOTE')
    and (date between from_date and as_on_date)
    and branch=br_id
    group by reorder_inventory,branch
    )
    update inventory_branch_detail as ibd
        set reorder_level = s1.order_level
    from s1
    where ibd.branch=br_id and ibd.inventory = s1.reorder_inventory
    and ibd.reorder_mode='DYNAMIC';

    return true;
end;
$$ language plpgsql;
--##
create function set_reorder(
    br_id int,
    input jsonb
)
returns bool
as
$$
begin
    with s1 as(
    select 
        (j->>'inventory')::integer as inventory, 
        coalesce((j->>'reorder_mode')::typ_reorder_mode,'DYNAMIC'::typ_reorder_mode) as reorder_mode,
        coalesce((j->>'reorder_level')::float,0.0) as reorder_level,
        (j->>'min_order')::float as min_order,
        (j->>'max_order')::float as max_order
    from jsonb_array_elements(input) j
    )
    update inventory_branch_detail as ibd
        set reorder_level = s1.reorder_level,
            reorder_mode = s1.reorder_mode,
            min_order = s1.min_order,
            max_order = s1.max_order
    from s1
    where ibd.branch=br_id 
    and s1.inventory = ibd.inventory;

    return true;
end;
$$ language plpgsql;
--##
create function get_reorder(
    br_id int,
    as_on_date date,
    days int,
    factor float
)
returns table (
    branch  int,
    branch_name text,
    inventory int,
    inventory_name text,
    manufacturer int,
    manufacturer_name   text,
    vendor int,
    vendor_name text,
    unit int,
    unit_name text,
    loose_qty int,
    order_level float,
    stock float
)
as
$$
declare
    from_date date := as_on_date - format('%s days',days)::interval;
begin

    return query
    with s1 as(
    SELECT
        inv_txn.branch, reorder_inventory, (sum(outward) * factor) as order_level
    from inv_txn
    where base_voucher_type in ('SALE','CREDIT_NOTE')
    and (date between from_date and as_on_date)
    and inv_txn.branch=br_id
    group by reorder_inventory,inv_txn.branch
    ),
    s2 as(
    select min(s1.branch) as brn, min(ibd.branch_name) as brn_name,
           s1.reorder_inventory,
           sum(s1.order_level) as ord_level, sum(ibd.stock) as stock
    from s1 left join inventory_branch_detail as ibd on s1.branch=ibd.branch and s1.reorder_inventory=ibd.reorder_inventory
    left join inventory as i on ibd.reorder_inventory = i.id
    where (s1.order_level-ibd.stock)>0
    and s1.branch=ibd.branch and s1.reorder_inventory=ibd.reorder_inventory
    group by s1.reorder_inventory
    having (sum(s1.order_level)- sum(ibd.stock))>0
    )
    select s2.brn, s2.brn_name,
           s2.reorder_inventory, i.name as inventory_name,
           i.manufacturer, i.manufacturer_name,
           i.vendor, i.vendor_name,
           i.unit, u.name as unit_name,
           i.loose_qty, s2.ord_level, s2.stock
    from s2 left join inventory as i on s2.reorder_inventory=i.id
    left join unit as u on i.unit=u.id;

end
$$ language plpgsql;