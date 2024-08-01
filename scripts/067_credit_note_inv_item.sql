create table if not exists credit_note_inv_item
(
    id             uuid     not null primary key,
    sno            smallint not null,
    credit_note_id int      not null,
    batch_id       int      not null,
    inventory_id   int      not null,
    unit_id        int      not null,
    unit_conv      float    not null,
    gst_tax_id     text     not null,
    qty            float    not null,
    rate           float    not null,
    is_loose_qty   boolean  not null default false,
    hsn_code       text,
    cess_on_qty    float,
    cess_on_val    float,
    disc_mode      char(1),
    discount       float,
    s_inc_id       int,
    taxable_amount float,
    asset_amount   float,
    cgst_amount    float,
    sgst_amount    float,
    igst_amount    float,
    cess_amount    float,
    constraint disc_mode_invalid check ( disc_mode in ('P', 'V') )
);
--##
create view vw_credit_note_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(d.*) from gst_tax d where d.id = a.gst_tax_id)                  as gst_tax,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit,
       (select row_to_json(f.*) from sales_person f where f.id = a.s_inc_id)               as sales_person
from credit_note_inv_item a
order by a.sno;
--##
create trigger tg_delete_credit_note_inv_item
    after delete
    on credit_note_inv_item
    for each row
execute procedure tgf_sync_inv_item_delete();