create view vw_category_option_detail as
select a.id, a.name, (select b.category from category b where id = a.category_id) as category
from category_option a;
--##
create function fetch_categories(json)
    returns json
as
$$
declare
    _ids        int[]                       := (select array_agg(value)::int[]
                                                from json_each_text($1));
    _categories vw_category_option_detail[] := (select array_agg(a)
                                                from vw_category_option_detail a
                                                where a.id = any (_ids));
    _category   vw_category_option_detail;
    _out        json                        = '{}'::json;
    _key        text;
    _val        int;
begin
    foreach _category in array coalesce(_categories, array []::vw_category_option_detail[])
        loop
            for _key, _val in select * from json_each_text($1)
                loop
                    if _val = _category.id then
                        _out = jsonb_insert(_out::jsonb, array [_key], row_to_json(_category)::jsonb);
                    end if;
                end loop;
        end loop;
    return _out::json;
end;
$$ language plpgsql security definer;
--##
create view vw_voucher_approval_condensed as
select id, approval_state, require_no_of_approval
from voucher;
--##
create view vw_tds_nature_of_payment_condensed as
select id, name, threshold, section
from tds_nature_of_payment;
--##
create view vw_pos_counter_condensed as
select code, name
from pos_counter;
--##
create view vw_branch_condensed
as
select a.id, a.name, a.mobile, a.alternate_mobile, a.contact_person, a.telephone, a.email
from branch a;
--##
create view vw_voucher_type_condensed
as
select a.id, a.name, a.base_type
from voucher_type a;
--##
create view vw_tds_on_voucher as
select a.voucher_id,
       a.tds_deductee_type_id,
       a.party_name,
       a.tds_ratio,
       a.tds_amount,
       a.amount,
       a.pan_no,
       a.tds_section,
       (select row_to_json(b.*) from vw_account_condensed b where b.id = a.party_account_id) as party_account,
       (select row_to_json(c.*) from vw_account_condensed c where c.id = a.tds_account_id)   as tds_account,
       (select row_to_json(d.*) from vw_tds_nature_of_payment_condensed d where d.id = a.tds_nature_of_payment_id)
                                                                                             as tds_nature_of_payment
from tds_on_voucher a;
--##
create view vw_inventory_condensed
as
select a.id, a.name, a.inventory_type, a.allow_negative_stock, a.hsn_code,a.gst_tax_id
from inventory a;
--##
create view vw_batch_condensed
as
select a.id,
       a.txn_id,
       a.inventory_id,
       a.inventory_name,
       a.batch_no,
       a.mrp,
       a.s_rate,
       a.nlc,
       a.landing_cost,
       a.loose_qty,
       a.p_rate,
       a.closing,
       a.cost,
       a.expiry,
       (select *
        from fetch_categories(json_build_object('category1', a.category1_id, 'category2', a.category2_id, 'category3',
                                                a.category3_id, 'category4', a.category4_id, 'category5',
                                                a.category5_id, 'category6', a.category6_id, 'category7',
                                                a.category7_id, 'category8', a.category8_id, 'category9',
                                                a.category9_id, 'category10', a.category10_id
                              ))) as categories
from batch a;
--##
create view vw_bill_allocation_condensed
as
select a.id,
       a.sno,
       a.ac_txn_id,
       a.amount,
       a.ref_type,
       a.ref_no,
       a.eff_date,
       a.pending,
       a.base_voucher_type,
       a.voucher_no
from bill_allocation a
order by a.sno;
--##
create view vw_bank_txn_condensed
as
select a.id,
       a.sno,
       a.ac_txn_id,
       a.amount,
       a.account_id,
       a.account_name,
       a.inst_no,
       a.inst_date,
       a.txn_type
from bank_txn a
order by a.sno;
--##
create view vw_acc_cat_txn
as
select a.id,
       a.sno,
       a.ac_txn_id,
       a.amount,
       (select *
        from fetch_categories(json_build_object('category1', a.category1_id, 'category2', a.category2_id, 'category3',
                                                a.category3_id, 'category4', a.category4_id, 'category5',
                                                a.category5_id))) as categories
from acc_cat_txn a
order by a.sno;
--##
create view vw_gst_txn_condensed
as
select a.ac_txn_id,
       a.amount,
       a.taxable_amount,
       a.hsn_code,
       a.gst_tax_id,
       a.qty,
       a.uqc_id
from gst_txn a;
--##
create view vw_ac_txn
as
select a.id,
       a.credit,
       a.debit,
       a.is_default,
       a.sno,
       a.voucher_id,
       (select row_to_json(vw_account_condensed.*) from vw_account_condensed where id = a.account_id)
                                                                                      as account,
       (select jsonb_agg(row_to_json(b.*)) from vw_acc_cat_txn b where b.ac_txn_id = a.id)
                                                                                      as category_allocations,
       (select jsonb_agg(row_to_json(c.*)) from vw_bill_allocation_condensed c where c.ac_txn_id = a.id)
                                                                                      as bill_allocations,
       (select jsonb_agg(row_to_json(d.*)) from vw_bank_txn_condensed d where d.ac_txn_id = a.id)
                                                                                      as bank_allocations,
       (select row_to_json(e.*) from vw_gst_txn_condensed e where e.ac_txn_id = a.id) as gst_info
from ac_txn a
order by a.sno;
--##
create view vw_account_opening as
select a.account_id,
       a.branch_id,
       a.credit,
       a.debit,
       (select jsonb_agg(row_to_json(c.*)) from vw_bill_allocation_condensed c where c.ac_txn_id = a.id)
                                                                                       as bill_allocations,
       (select row_to_json(c.*) from vw_branch_condensed c where c.id = a.branch_id)   as branch,
       (select row_to_json(d.*) from vw_account_condensed d where d.id = a.account_id) as account
from ac_txn a
where a.is_opening;
--##
create view vw_inventory_opening as
select a.*,
       (select row_to_json(d.*) from unit d where d.id = a.unit_id) as unit
from inventory_opening a
order by a.sno;
--##
create view vw_voucher
as
select a.*,
       (select json_agg(row_to_json(b.*))
        from vw_ac_txn b
        where b.voucher_id = a.id)                                                               as ac_trns,
       (select row_to_json(c.*) from vw_branch_condensed c where c.id = a.branch_id)             as branch,
       (select row_to_json(d.*) from vw_voucher_type_condensed d where d.id = a.voucher_type_id) as voucher_type,
       (select row_to_json(d.*) from vw_account_condensed d where d.id = a.party_id)             as party,
       (select json_agg(row_to_json(e.*)) from vw_tds_on_voucher e where e.voucher_id = a.id)    as tds_details
from voucher a;
--##
create view vw_sale_bill_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(d.*) from gst_tax d where d.id = a.gst_tax_id)                  as gst_tax,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit,
       (select row_to_json(f.*) from sales_person f where f.id = a.s_inc_id)               as sales_person
from sale_bill_inv_item a
order by a.sno;
--##
create view vw_sale_bill
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)         as ac_trns,
       (select json_agg(row_to_json(c.*)) from vw_sale_bill_inv_item c where c.sale_bill_id = a.id)   as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)                  as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id)      as voucher_type,
       (select row_to_json(g.*) from warehouse g where g.id = a.warehouse_id)                         as warehouse,
       case
           when a.pos_counter_code is not null then (select row_to_json(f.*)
                                                     from vw_pos_counter_condensed f
                                                     where f.code = a.pos_counter_code) end
                                                                                                      as pos_counter,

       case
           when a.customer_id is not null then (select row_to_json(h.*)
                                                from vw_account_condensed h
                                                where h.id = a.customer_id) end                       as customer,
       case when a.doctor_id is not null then (select row_to_json(i.*) from doctor i where i.id = a.doctor_id) end
                                                                                                      as doctor,
       case
           when a.emi_detail is not null then (select row_to_json(h.*)
                                               from vw_account_condensed h
                                               where h.id = (a.emi_detail ->> 'account_id')::int) end as emi_account
from sale_bill a;
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
create view vw_credit_note
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)           as ac_trns,
       (select json_agg(row_to_json(c.*)) from vw_credit_note_inv_item c where c.credit_note_id = a.id) as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)                    as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id)        as voucher_type,
       (select row_to_json(g.*) from warehouse g where g.id = a.warehouse_id)                           as warehouse,
       case
           when a.customer_id is not null then (select row_to_json(h.*)
                                                from vw_account_condensed h
                                                where h.id = a.customer_id) end                         as customer,
       case
           when a.pos_counter_code is not null then (select row_to_json(f.*)
                                                     from vw_pos_counter_condensed f
                                                     where f.code = a.pos_counter_code) end
                                                                                                        as pos_counter
from credit_note a;
--##
create view vw_debit_note_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(d.*) from gst_tax d where d.id = a.gst_tax_id)                  as gst_tax,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from debit_note_inv_item a
order by a.sno;
--##
create view vw_debit_note
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)         as ac_trns,
       (select json_agg(row_to_json(c.*)) from vw_debit_note_inv_item c where c.debit_note_id = a.id) as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)                  as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id)      as voucher_type,
       (select row_to_json(g.*) from warehouse g where g.id = a.warehouse_id)                         as warehouse,
       case
           when a.vendor_id is not null then (select row_to_json(h.*)
                                              from vw_account_condensed h
                                              where h.id = a.vendor_id) end                           as vendor
from debit_note a;
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
create view vw_purchase_bill
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)         as ac_trns,
       (select json_agg(row_to_json(c.*)) from vw_purchase_bill_inv_item c where c.purchase_bill_id = a.id)
                                                                                                      as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)                  as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id)      as voucher_type,
       (select row_to_json(g.*) from warehouse g where g.id = a.warehouse_id)                         as warehouse,
       (select row_to_json(i.*) from vw_voucher_approval_condensed i where i.id = a.voucher_id)       as voucher,
       (select json_agg(row_to_json(j.*)) from vw_tds_on_voucher j where j.voucher_id = a.voucher_id) as tds_details,
       case
           when a.vendor_id is not null then (select row_to_json(h.*)
                                              from vw_account_condensed h
                                              where h.id = a.vendor_id) end                           as vendor
from purchase_bill a;
--##
create view vw_stock_adjustment_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from stock_adjustment_inv_item a
order by a.sno;
--##
create view vw_stock_adjustment
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)    as ac_trns,
       (select json_agg(row_to_json(c.*)) from vw_stock_adjustment_inv_item c where c.stock_adjustment_id = a.id)
                                                                                                 as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type,
       (select row_to_json(g.*) from warehouse g where g.id = a.warehouse_id)                    as warehouse
from stock_adjustment a;
--##
create view vw_stock_deduction_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from stock_deduction_inv_item a
order by a.sno;
--##
create view vw_stock_deduction
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)        as ac_trns,
       (select json_agg(row_to_json(c.*)) from vw_stock_deduction_inv_item c where c.stock_deduction_id = a.id)
                                                                                                     as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)                 as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id)     as voucher_type,
       (select row_to_json(f.*) from warehouse f where f.id = a.warehouse_id)                        as warehouse,
       case
           when a.alt_branch_id is not null then
               (select row_to_json(g.*) from vw_branch_condensed g where g.id = a.alt_branch_id) end as alt_branch,
       case
           when a.alt_warehouse_id is not null then
               (select row_to_json(h.*) from warehouse h where h.id = a.alt_warehouse_id) end        as alt_warehouse
from stock_deduction a;
--##
create view vw_stock_addition_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.txn_id = a.id)           as batch,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from stock_addition_inv_item a
order by a.sno;
--##
create view vw_stock_addition
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)        as ac_trns,
       (select json_agg(row_to_json(c.*)) from vw_stock_addition_inv_item c where c.stock_addition_id = a.id)
                                                                                                     as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)                 as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id)     as voucher_type,
       (select row_to_json(f.*) from warehouse f where f.id = a.warehouse_id)                        as warehouse,
       case
           when a.alt_branch_id is not null then
               (select row_to_json(g.*) from vw_branch_condensed g where g.id = a.alt_branch_id) end as alt_branch,
       case
           when a.alt_warehouse_id is not null then
               (select row_to_json(h.*) from warehouse h where h.id = a.alt_warehouse_id) end        as alt_warehouse
from stock_addition a;
--##
create view vw_material_conversion_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.source_inventory_id) as source_inventory,
       (select row_to_json(b1.*)
        from vw_inventory_condensed b1
        where b1.id = a.target_inventory_id)                                                      as target_inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.txn_id = a.target_id)           as target_batch,
       (select row_to_json(c1.*) from vw_batch_condensed c1 where c1.id = a.source_batch_id)      as source_batch,
       (select row_to_json(e.*) from unit e where e.id = a.source_unit_id)                        as source_unit,
       (select row_to_json(e1.*) from unit e1 where e1.id = a.target_unit_id)                     as target_unit
from material_conversion_inv_item a
order by a.sno;
--##
create view vw_material_conversion
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)    as ac_trns,
       (select json_agg(row_to_json(c.*)) from vw_material_conversion_inv_item c where c.material_conversion_id = a.id)
                                                                                                 as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type,
       (select row_to_json(f.*) from warehouse f where f.id = a.warehouse_id)                    as warehouse
from material_conversion a;
--##
create view vw_personal_use_purchase_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from personal_use_purchase_inv_item a
order by a.sno;
--##
create view vw_personal_use_purchase
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)    as ac_trns,
       (select json_agg(row_to_json(c.*))
        from vw_personal_use_purchase_inv_item c
        where c.personal_use_purchase_id = a.id)
                                                                                                 as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type,
       (select row_to_json(f.*) from warehouse f where f.id = a.warehouse_id)                    as warehouse,
       case
           when a.expense_account_id is not null then (select row_to_json(g.*)
                                                       from vw_account_condensed g
                                                       where g.id = a.expense_account_id) end    as expense_account
from personal_use_purchase a;
--##
create view vw_customer_advance
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)    as ac_trns,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type
from customer_advance a;
--##
create view vw_goods_inward_note
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)    as ac_trns,
       (select row_to_json(c.*) from vw_account_condensed c where c.id = a.vendor_id)            as vendor,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type,
       (select row_to_json(i.*) from vw_voucher_approval_condensed i where i.id = a.voucher_id)  as voucher,
       case
           when a.transport_id is not null then (select row_to_json(f.*)
                                                 from vw_account_condensed f
                                                 where f.id = a.transport_id) end                as transport,
       case
           when a.division_id is not null then (select row_to_json(g.*)
                                                from division g
                                                where g.id = a.division_id) end                  as division
from goods_inward_note a;
--##
create view vw_gift_voucher
as
select a.*,
       (select json_agg(row_to_json(b.*)) from vw_ac_txn b where b.voucher_id = a.voucher_id)    as ac_trns,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type
from gift_voucher a;
