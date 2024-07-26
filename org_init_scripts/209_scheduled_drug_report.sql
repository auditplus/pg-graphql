create view scheduled_drug_report
as
select row_number() over () as row_id,
       sale_bill.id,
       sale_bill.date,
       sale_bill.branch_id,
       sale_bill.branch_name,
       sale_bill.doctor_id,
       d.name  as doctor_name,
       sale_bill.voucher_id,
       sale_bill.voucher_no,
       sbii.inventory_id,
       sbii.qty,
       sbii.drug_classifications,
       b.batch_no,
       b.inventory_name,
       b.expiry
from sale_bill
         left join sale_bill_inv_item sbii on sale_bill.id = sbii.sale_bill_id
         left join batch b on sbii.batch_id = b.id
         left join doctor d on sale_bill.doctor_id = d.id
where sbii.drug_classifications is not null;
