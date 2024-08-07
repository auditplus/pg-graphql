create table if not exists purchase_bill_inv_item
(
    id                uuid     not null primary key,
    sno               smallint not null,
    purchase_bill_id  int      not null,
    inventory_id      int      not null,
    unit_id           int      not null,
    unit_conv         float    not null,
    gst_tax_id        text     not null,
    qty               float    not null default 0,
    free_qty          float,
    label_qty         float,
    weight_qty        float,
    weight_rate       float,
    m_qty             text,
    nlc               float    not null default 0,
    cost              float    not null default 0,
    rate              float    not null,
    is_loose_qty      boolean  not null default true,
    landing_cost      float,
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
    category10_id     int,
    hsn_code          text,
    cess_on_qty       float,
    cess_on_val       float,
    disc1_mode        char(1),
    disc2_mode        char(1),
    discount1         float,
    discount2         float,
    taxable_amount    float,
    asset_amount      float,
    cgst_amount       float,
    sgst_amount       float,
    igst_amount       float,
    cess_amount       float,
    profit_percentage float,
    sale_value        float,
    profit_value      float,
    constraint disc1_mode_invalid check (disc1_mode in ('P', 'V')),
    constraint disc2_mode_invalid check (disc2_mode in ('P', 'V')),
    constraint qty_free_qty_invalid check ((qty + coalesce(free_qty, 0)) > 0)
);
--##
create view vw_purchase_bill_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.txn_id = a.id)           as batch,
       (select row_to_json(d.*) from gst_tax d where d.id = a.gst_tax_id)                  as gst_tax,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from purchase_bill_inv_item a
order by a.sno;
--##
create trigger tg_delete_purchase_bill_inv_item
    after delete
    on purchase_bill_inv_item
    for each row
execute procedure tgf_sync_inv_item_delete();