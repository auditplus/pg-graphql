create table if not exists material_conversion_inv_item
(
    target_id              uuid     not null,
    source_id              uuid     not null,
    sno                    smallint not null,
    material_conversion_id int      not null,
    source_batch_id        int      not null,
    source_inventory_id    int      not null,
    source_unit_id         int      not null,
    source_unit_conv       float    not null,
    source_qty             float    not null,
    qty_conv               float    not null,
    source_is_loose_qty    boolean  not null default false,
    source_asset_amount    float,
    target_inventory_id    int      not null,
    target_unit_id         int      not null,
    target_unit_conv       float    not null,
    target_qty             float    not null,
    target_is_loose_qty    boolean  not null default true,
    target_gst_tax_id      text     not null,
    target_cost            float    not null,
    target_nlc             float    not null default 0,
    target_asset_amount    float,
    target_mrp             float,
    target_s_rate          float,
    target_batch_no        text,
    target_expiry          date,
    target_category1_id    int,
    target_category2_id    int,
    target_category3_id    int,
    target_category4_id    int,
    target_category5_id    int,
    target_category6_id    int,
    target_category7_id    int,
    target_category8_id    int,
    target_category9_id    int,
    target_category10_id   int,
    primary key (source_id, target_id)
);
--##
create view vw_material_conversion_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.source_inventory_id) as source_inventory,
       (select row_to_json(b1.*)
        from vw_inventory_condensed b1
        where b1.id = a.target_inventory_id)                                                      as target_inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.txn_id = a.target_id)           as target_batch,
       (select row_to_json(c1.*) from vw_batch_condensed c1 where c1.id = a.source_batch_id)      as source_batch,
       (select row_to_json(e.*) from unit e where e.id = a.source_unit_id)                        as source_unit,
       (select row_to_json(e1.*) from unit e1 where e1.id = a.target_unit_id)                     as target_unit
from material_conversion_inv_item a
order by a.sno;
--##
create function tgf_sync_material_inv_item_delete()
    returns trigger as
$$
begin
    delete from inv_txn where id in (old.source_id, old.target_id);
    return old;
end;
$$ language plpgsql;
--##
create trigger tg_delete_material_conversion_inv_item
    after delete
    on material_conversion_inv_item
    for each row
execute procedure tgf_sync_material_inv_item_delete();