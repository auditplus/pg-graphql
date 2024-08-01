create table if not exists personal_use_purchase_inv_item
(
    id                       uuid     not null primary key,
    sno                      smallint not null,
    personal_use_purchase_id int      not null,
    batch_id                 int      not null,
    inventory_id             int      not null,
    unit_id                  int      not null,
    unit_conv                float    not null,
    gst_tax_id               text     not null,
    qty                      float    not null,
    cost                     float    not null,
    is_loose_qty             boolean  not null default false,
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
create view vw_personal_use_purchase_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit,
       (select row_to_json(f.*) from gst_tax f where f.id = a.gst_tax_id)                  as gst_tax
from personal_use_purchase_inv_item a
order by a.sno;
--##
create trigger tg_delete_personal_use_purchase_inv_item
    after delete
    on personal_use_purchase_inv_item
    for each row
execute procedure tgf_sync_inv_item_delete();