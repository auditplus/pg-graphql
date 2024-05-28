create view inventory_category_report_detail
as
select
    it.id as id,
    it.date as date,
    it.batch as batch,
    it.branch as branch, it.branch_name as branch_name,
    it.inventory as inventory, it.inventory_name as inventory_name,
    it.inward as inward, it.outward as outward, (it.inward - it.outward) as closing,
    it.ref_no as ref_no,
    it.voucher_no as voucher_no, it.base_voucher_type::text as base_voucher_type,
    it.voucher_type as voucher_type, it.voucher as voucher, it.inventory_voucher_id as inventory_voucher_id,
    it.category1 as category1, it.category2 as category2, it.category3 as category3, it.category4 as category4, it.category5 as category5,
    it.category6 as category6, it.category7 as category7, it.category8 as category8, it.category9 as category9, it.category10 as category10,
    json_build_object(
    'category1', (case when it.category1 is not null then
        json_build_object('id', it.category1, 'name', co1.name,
            'category',json_build_object('id', co1.category, 'name', c1.name,
                'category', c1.category, 'category_type',c1.category_type)
        ) end),
    'category2', (case when it.category2 is not null then
        json_build_object('id', it.category2, 'name', co2.name,
            'category',json_build_object('id', co2.category, 'name', c2.name,
                'category', c2.category, 'category_type',c2.category_type)
        ) end),
    'category3', (case when it.category3 is not null then
        json_build_object('id', it.category3, 'name', co3.name,
            'category',json_build_object('id', co3.category, 'name', c3.name,
                'category', c3.category, 'category_type',c3.category_type)
        ) end),
    'category4', (case when it.category4 is not null then
        json_build_object('id', it.category4, 'name', co4.name,
            'category',json_build_object('id', co4.category, 'name', c4.name,
                'category', c4.category, 'category_type',c4.category_type)
        ) end),
    'category5', (case when it.category5 is not null then
        json_build_object('id', it.category5, 'name', co5.name,
            'category',json_build_object('id', co5.category, 'name', c5.name,
                'category', c5.category, 'category_type',c5.category_type)
        ) end),
    'category6', (case when it.category6 is not null then
        json_build_object('id', it.category6, 'name', co6.name,
            'category',json_build_object('id', co6.category, 'name', c6.name,
                'category', c6.category, 'category_type',c6.category_type)
        ) end),
    'category7', (case when it.category7 is not null then
        json_build_object('id', it.category7, 'name', co7.name,
            'category',json_build_object('id', co7.category, 'name', c7.name,
                'category', c7.category, 'category_type',c7.category_type)
        ) end),
    'category8', (case when it.category8 is not null then
            json_build_object('id', it.category8, 'name', co8.name,
            'category',json_build_object('id', co8.category, 'name', c8.name,
                'category', c8.category, 'category_type',c8.category_type)
        ) end),
    'category9', (case when it.category9 is not null then
            json_build_object('id', it.category9, 'name', co9.name,
            'category',json_build_object('id', co9.category, 'name', c9.name,
                'category', c9.category, 'category_type',c9.category_type)
        ) end),
    'category10', (case when it.category10 is not null then
            json_build_object('id', it.category10,'name', co10.name,
            'category',json_build_object('id', co10.category, 'name', c10.name,
                'category', c10.category, 'category_type',c10.category_type)
        ) end)
    ) as category
from inv_txn as it
    left join category_option as co1 on it.category1 = co1.id left join category as c1 on co1.category = c1.id
    left join category_option as co2 on it.category2 = co2.id left join category as c2 on co2.category = c2.id
    left join category_option as co3 on it.category3 = co3.id left join category as c3 on co3.category = c3.id
    left join category_option as co4 on it.category4 = co4.id left join category as c4 on co4.category = c4.id
    left join category_option as co5 on it.category5 = co5.id left join category as c5 on co5.category = c5.id
    left join category_option as co6 on it.category6 = co6.id left join category as c6 on co6.category = c6.id
    left join category_option as co7 on it.category7 = co7.id left join category as c7 on co7.category = c7.id
    left join category_option as co8 on it.category8 = co8.id left join category as c8 on co8.category = c8.id
    left join category_option as co9 on it.category9 = co9.id left join category as c9 on co9.category = c9.id
    left join category_option as co10 on it.category10 = co10.id left join category as c10 on co10.category = c10.id;