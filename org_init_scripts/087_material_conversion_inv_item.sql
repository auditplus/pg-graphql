create table if not exists material_conversion_inv_item
(
    target_id           uuid    not null,
    source_id           uuid    not null,
    material_conversion int     not null,
    source_batch        int     not null,
    source_inventory    int     not null,
    source_unit         int     not null,
    source_unit_conv    float   not null,
    source_qty          float   not null,
    qty_conv            float   not null,
    source_is_loose_qty boolean not null default false,
    source_asset_amount float,
    target_inventory    int     not null,
    target_unit         int     not null,
    target_unit_conv    float   not null,
    target_qty          float   not null,
    target_is_loose_qty boolean not null default true,
    target_gst_tax      text    not null,
    target_cost         float   not null,
    target_nlc          float   not null default 0,
    target_asset_amount float,
    target_mrp          float,
    target_s_rate       float,
    target_batch_no     text,
    target_expiry       date,
    target_category     json,
    primary key (source_id, target_id)
);
--##
create function sync_material_inv_item_delete()
    returns trigger as
$$
begin
    delete from inv_txn where id in (old.source_id, old.target_id);
    return old;
end;
$$ language plpgsql;
--##
create trigger delete_material_conversion_inv_item
    after delete
    on material_conversion_inv_item
    for each row
execute procedure sync_material_inv_item_delete();