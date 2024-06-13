create view batch_label
as
select b.id          as id,
       b.inventory_id,
       b.inventory_name,
       b.branch_id,
       b.branch_name,
       b.label_qty,
       b.sno,
       b.mrp,
       b.s_rate,
       b.barcode,
       b.expiry,
       b.entry_date,
       b.entry_type,
       b.batch_no,
       b.voucher_no,
       b.vendor_name,
       b.vendor_id,
       b.inventory_voucher_id,
       b.voucher_id,
       u.name        as unit_name,
       i.barcodes[1] as inventory_barcode,
       i.description as inventory_description
from batch b
         left join unit as u on b.unit_id = u.id
         left join inventory as i on b.inventory_id = i.id;
--##
comment on view batch_label is e'@graphql({"primary_key_columns": ["id"]})';