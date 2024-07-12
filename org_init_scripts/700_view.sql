create view vw_category_option_detail as
select a.id, a.name, (select b.category from category b where id = a.category_id) as category
from category_option a;
--##
create function fetch_categories(json)
    returns json
as
$$
declare
    _ids        int[]                     := (select array_agg(value)::int[]
                                              from json_each_text($1));
    _categories vw_category_option_detail := (select *
                                              from vw_category_option_detail a
                                              where a.id = any (_ids));
    _out        json;
    _key        text;
    _val        int;
begin
    for _key, _val in select * from json_each_text($1)
        loop
            _out = jsonb_insert(_out::jsonb, array [_key],
                                (select row_to_json(a.*) from _categories a where a.id = _val)::jsonb);

        end loop;
    return _out;
end;
$$ language plpgsql security definer;
--##
create view vw_account_condensed
as
select a.id,
       a.name,
       a.bill_wise_detail,
       a.transaction_enabled,
       a.alias_name,
       a.account_type_id,
       a.base_account_types,
       a.sac_code,
       a.mobile,
       a.email,
       a.telephone,
       a.contact_person
from account a;
--##
create view vw_branch_condensed
as
select a.id, a.name, a.mobile, a.alternate_mobile, a.contact_person, a.telephone, a.email
from branch a;
--##
create view vw_voucher_type_condensed
as
select a.id, a.name
from voucher_type a;
--##
create view vw_inventory_condensed
as
select a.id, a.name, a.inventory_type, a.allow_negative_stock, a.hsn_code
from inventory a;
--##
create view vw_batch_condensed
as
select a.id,
       a.batch_no,
       a.barcode,
       a.mrp,
       a.s_rate,
       a.nlc,
       a.p_rate,
       a.inventory_id,
       a.inventory_name
from batch a;
--##
create view vw_bill_allocation_condensed
as
select a.id,
       a.ac_txn_id,
       a.amount,
       a.ref_type,
       a.ref_no,
       a.eff_date,
       a.pending,
       a.base_voucher_type,
       a.voucher_no
from bill_allocation a;
--##
create view vw_bank_txn_condensed
as
select a.id,
       a.ac_txn_id,
       a.amount,
       a.account_id,
       a.account_name,
       a.inst_no,
       a.inst_date,
       a.txn_type
from bank_txn a;
--##
create view vw_acc_cat_txn
as
select a.id,
       a.ac_txn_id,
       a.amount,
       (select *
        from fetch_categories(json_build_object('category1', a.category1_id, 'category2', a.category2_id, 'category3',
                                                a.category3_id, 'category4', a.category4_id, 'category5',
                                                a.category5_id))) as categories
from acc_cat_txn a;
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
       a.voucher_id,
       (select row_to_json(vw_account_condensed.*) from vw_account_condensed where id = a.account_id)    as account,
       (select jsonb_agg(row_to_json(b.*)) from vw_acc_cat_txn b where b.ac_txn_id = a.id)               as cat_txns,
       (select jsonb_agg(row_to_json(c.*)) from vw_bill_allocation_condensed c where c.ac_txn_id = a.id) as bill_txns,
       (select jsonb_agg(row_to_json(d.*)) from vw_bank_txn_condensed d where d.ac_txn_id = a.id)        as bank_txns,
       (select row_to_json(e.*) from vw_gst_txn_condensed e where e.ac_txn_id = a.id)                    as gst_info
from ac_txn a;
--##
create view vw_voucher
as
select a.*,
       (select json_agg(row_to_json(b.*))
        from vw_ac_txn b
        where b.voucher_id = a.id)                                                               as ac_txns,
       (select row_to_json(c.*) from vw_branch_condensed c where c.id = a.branch_id)             as branch,
       (select row_to_json(d.*) from vw_voucher_type_condensed d where d.id = a.voucher_type_id) as voucher_type,
       (select row_to_json(d.*) from vw_account_condensed d where d.id = a.party_id)             as party
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
from sale_bill_inv_item a;
--##
create view vw_sale_bill
as
select a.*,
       (select json_agg(row_to_json(b.*))
        from vw_ac_txn b
        where b.voucher_id = a.voucher_id)                                                       as ac_txns,
       (select json_agg(row_to_json(c.*))
        from vw_sale_bill_inv_item c
        where c.sale_bill_id = a.id)                                                             as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type
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
from credit_note_inv_item a;
--##
create view vw_credit_note
as
select a.*,
       (select json_agg(row_to_json(b.*))
        from vw_ac_txn b
        where b.voucher_id = a.voucher_id)                                                       as ac_txns,
       (select json_agg(row_to_json(c.*))
        from vw_credit_note_inv_item c
        where c.credit_note_id = a.id)                                                           as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type
from credit_note a;
--##
create view vw_debit_note_inv_item
as
select a.*,
       (select row_to_json(b.*) from vw_inventory_condensed b where b.id = a.inventory_id) as inventory,
       (select row_to_json(c.*) from vw_batch_condensed c where c.id = a.batch_id)         as batch,
       (select row_to_json(d.*) from gst_tax d where d.id = a.gst_tax_id)                  as gst_tax,
       (select row_to_json(e.*) from unit e where e.id = a.unit_id)                        as unit
from debit_note_inv_item a;
--##
create view vw_debit_note
as
select a.*,
       (select json_agg(row_to_json(b.*))
        from vw_ac_txn b
        where b.voucher_id = a.voucher_id)                                                       as ac_txns,
       (select json_agg(row_to_json(c.*))
        from vw_debit_note_inv_item c
        where c.debit_note_id = a.id)                                                            as inv_items,
       (select row_to_json(d.*) from vw_branch_condensed d where d.id = a.branch_id)             as branch,
       (select row_to_json(e.*) from vw_voucher_type_condensed e where e.id = a.voucher_type_id) as voucher_type
from debit_note a;
