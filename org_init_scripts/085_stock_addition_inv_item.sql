create table if not exists stock_addition_inv_item
(
    id                uuid    not null primary key,
    stock_addition_id int     not null,
    inventory_id      int     not null,
    unit_id           int     not null,
    unit_conv         float   not null,
    qty               float   not null,
    cost              float   not null default 0,
    landing_cost      float,
    is_loose_qty      boolean not null default true,
    nlc               float   not null default 0,
    barcode           text,
    asset_amount      float,
    mrp               float,
    s_rate            float,
    batch_no          text,
    expiry            date,
    category          json
);
--##
create trigger delete_stock_addition_inv_item
    after delete
    on stock_addition_inv_item
    for each row
execute procedure sync_inv_item_delete();
