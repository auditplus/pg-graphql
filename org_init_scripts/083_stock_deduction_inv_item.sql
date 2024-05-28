create table if not exists stock_deduction_inv_item
(
    id              uuid  not null primary key,
    stock_deduction int   not null,
    batch           int   not null,
    inventory       int   not null,
    unit            int   not null,
    unit_conv       float not null,
    qty             float not null,
    cost            float not null,
    is_loose_qty    bool  not null default false,
    asset_amount    float
);
--##
create trigger delete_stock_deduction_inv_item
    after delete
    on stock_deduction_inv_item
    for each row
execute procedure sync_inv_item_delete();