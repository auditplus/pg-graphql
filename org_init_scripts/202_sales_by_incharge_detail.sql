create view sales_by_incharge_detail as
select date,
       branch_id,
       branch_name,
       base_voucher_type,
       sale_bill_inv_item.inventory_id,
       inventory.name                                 as inventory_name,
       sale_bill_inv_item.s_inc_id                    as sale_incharge,
       sale_incharge.name                             as sale_incharge_name,
       sale_incharge.code                             as sale_incharge_code,
       sale_bill_inv_item.qty,
       coalesce(sale_bill_inv_item.taxable_amount, 0) as taxable_amount,
       (coalesce(sale_bill_inv_item.cgst_amount, 0) +
        coalesce(sale_bill_inv_item.sgst_amount, 0) +
        coalesce(sale_bill_inv_item.cess_amount, 0) +
        coalesce(sale_bill_inv_item.igst_amount, 0))  as tax_amount
from sale_bill
         left join sale_bill_inv_item on sale_bill.id = sale_bill_inv_item.sale_bill_id
         left join inventory on sale_bill_inv_item.inventory_id = inventory.id
         left join sale_incharge on sale_bill_inv_item.s_inc_id = sale_incharge.id
where sale_bill_inv_item.s_inc_id is not null
union all
(select date,
        branch_id,
        branch_name,
        base_voucher_type,
        credit_note_inv_item.inventory_id,
        inventory.name                                        as inventory_name,
        credit_note_inv_item.s_inc_id                         as sale_incharge,
        sale_incharge.name                                    as sale_incharge_name,
        sale_incharge.code                                    as sale_incharge_code,
        credit_note_inv_item.qty,
        coalesce(credit_note_inv_item.taxable_amount, 0) * -1 as taxable_amount,
        (coalesce(credit_note_inv_item.cgst_amount, 0) +
         coalesce(credit_note_inv_item.sgst_amount, 0) +
         coalesce(credit_note_inv_item.cess_amount, 0) +
         coalesce(credit_note_inv_item.igst_amount, 0)) * -1  as tax_amount

 from credit_note
          left join credit_note_inv_item on credit_note.id = credit_note_inv_item.credit_note_id
          left join inventory on credit_note_inv_item.inventory_id = inventory.id
          left join sale_incharge on credit_note_inv_item.s_inc_id = sale_incharge.id
 where credit_note_inv_item.s_inc_id is not null);