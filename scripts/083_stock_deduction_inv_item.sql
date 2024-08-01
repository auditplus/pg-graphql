create table if not exists stock_deduction_inv_item
(
    id                 uuid     not null primary key,
    sno                smallint not null,
    stock_deduction_id int      not null,
    batch_id           int      not null,
    inventory_id       int      not null,
    unit_id            int      not null,
    unit_conv          float    not null,
    qty                float    not null,
    cost               float    not null,
    is_loose_qty       bool     not null default false,
    asset_amount       float
);
--##
create view vw_stock_deduction_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from stock_deduction_inv_item a
order by a.sno;
--##
create trigger tg_delete_stock_deduction_inv_item
    after delete
    on stock_deduction_inv_item
    for each row
execute procedure tgf_sync_inv_item_delete();