create table if not exists sale_bill_inv_item
(
    id                   uuid    not null primary key,
    sale_bill_id         int     not null,
    batch_id             int     not null,
    inventory_id         int     not null,
    unit_id              int     not null,
    unit_conv            float   not null,
    gst_tax_id           text    not null,
    qty                  float   not null,
    rate                 float   not null,
    is_loose_qty         boolean not null default false,
    hsn_code             text,
    cess_on_qty          float,
    cess_on_val          float,
    disc_mode            char(1)
        constraint sale_bill_inv_item_disc_mode_invalid check ( disc_mode in ('P', 'V') ),
    discount             float,
    s_inc_id             int,
    taxable_amount       float,
    asset_amount         float,
    cgst_amount          float,
    sgst_amount          float,
    igst_amount          float,
    cess_amount          float,
    drug_classifications typ_drug_category[]
);
--##
create trigger delete_sale_bill_inv_item
    after delete
    on sale_bill_inv_item
    for each row
execute procedure sync_inv_item_delete();