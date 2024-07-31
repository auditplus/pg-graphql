create table if not exists vendor_item_map
(
    vendor_id        int  not null,
    inventory_id     int  not null,
    vendor_inventory text not null,
    primary key (vendor_id, inventory_id)
);