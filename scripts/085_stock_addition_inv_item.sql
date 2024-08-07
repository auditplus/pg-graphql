create table if not exists stock_addition_inv_item
(
    id                uuid     not null primary key,
    sno               smallint not null,
    stock_addition_id int      not null,
    inventory_id      int      not null,
    unit_id           int      not null,
    unit_conv         float    not null,
    qty               float    not null,
    cost              float    not null default 0,
    landing_cost      float,
    is_loose_qty      boolean  not null default true,
    nlc               float    not null default 0,
    barcode           text,
    source_batch_id   int,
    asset_amount      float,
    mrp               float,
    s_rate            float,
    batch_no          text,
    expiry            date,
    category1_id      int,
    category2_id      int,
    category3_id      int,
    category4_id      int,
    category5_id      int,
    category6_id      int,
    category7_id      int,
    category8_id      int,
    category9_id      int,
    category10_id     int
);
--##
create view vw_stock_addition_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.txn_id = a.id)           as batch,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from stock_addition_inv_item a
order by a.sno;
--##
create trigger tg_delete_stock_addition_inv_item
    after delete
    on stock_addition_inv_item
    for each row
execute procedure tgf_sync_inv_item_delete();
