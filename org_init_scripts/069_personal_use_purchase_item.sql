create table if not exists personal_use_purchase_inv_item
(
    id                       uuid    not null primary key,
    personal_use_purchase_id bigint  not null,
    batch_id                 bigint  not null,
    inventory_id             bigint  not null,
    unit_id                  bigint  not null,
    unit_conv                float   not null,
    gst_tax_id               text    not null,
    qty                      float   not null,
    cost                     float   not null,
    is_loose_qty             boolean not null default false,
    hsn_code                 text,
    cess_on_qty              float,
    cess_on_val              float,
    taxable_amount           float,
    asset_amount             float,
    cgst_amount              float,
    sgst_amount              float,
    igst_amount              float,
    cess_amount              float
);
--##
create trigger delete_personal_use_purchase_inv_item
    after delete
    on personal_use_purchase_inv_item
    for each row
execute procedure sync_inv_item_delete();