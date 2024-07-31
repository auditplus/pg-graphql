create table if not exists stock_adjustment_inv_item
(
    id                  uuid     not null primary key,
    sno                 smallint not null,
    stock_adjustment_id int      not null,
    batch_id            int      not null,
    inventory_id        int      not null,
    unit_id             int      not null,
    unit_conv           float    not null,
    qty                 float    not null,
    cost                float    not null,
    is_loose_qty        boolean  not null default false,
    asset_amount        float
);
--##
create trigger tg_delete_stock_adjustment_inv_item
    after delete
    on stock_adjustment_inv_item
    for each row
execute procedure tgf_sync_inv_item_delete();