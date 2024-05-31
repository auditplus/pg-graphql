create table if not exists vendor_item_map
(
    vendor           int  not null,
    inventory        int  not null,
    vendor_inventory text not null,
    primary key (vendor, inventory)
);
--##
create function set_vendor_item_map(vendor_id int, item_map jsonb)
    returns boolean
as
$$
declare
    item  vendor_item_map;
    items vendor_item_map[] := (select array_agg(x)
                                from jsonb_populate_recordset(null::vendor_item_map, $2) as x);
begin
    foreach item in array items
        loop
            insert into vendor_item_map(vendor, inventory, vendor_inventory)
            values ($1, item.inventory, item.vendor_inventory)
            on conflict (vendor, inventory) do update
                set vendor_inventory = excluded.vendor_inventory;
        end loop;
    return true;
end;
$$ language plpgsql;