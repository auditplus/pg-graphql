create view customer_sale_history as
select a.customer_id,
       (select row_to_json(h.*) from vw_account_condensed h where h.id = a.customer_id) as customer,
       case when a.doctor_id is not null then (select row_to_json(d.*) from doctor d where d.id = a.doctor_id) end
                                                                                        as doctor,
       a.voucher_no,
       a.voucher_id,
       a.id,
       a.date,
       a.branch_id,
       a.branch_name,
       a.amount,
       (select jsonb_agg(row_to_json(x.*))
        from (select b.*,
                     (select c.name from inventory c where c.id = b.inventory_id) as inventory_name,
                     (select row_to_json(u.*) from unit u where u.id = b.unit_id) as unit
              from sale_bill_inv_item b
              where sale_bill_id = a.id) x)                                             as inv_items
from sale_bill a
where a.customer_id is not null
order by a.date desc
limit 100;
--##
create view vw_recent_sale_bill
as
select a.id,
       a.voucher_id,
       a.voucher_no,
       a.date,
       a.branch_id,
       a.branch_name,
       a.customer_id,
       a.customer_name,
       a.ref_no,
       a.amount
from sale_bill a
where a.date between current_date - 2 and current_date
order by a.updated_at desc;