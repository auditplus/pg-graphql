create view inventory_category_report_detail
as
select it.id                      as id,
       it.date                    as date,
       it.batch_id                as batch,
       it.branch_id               as branch,
       it.branch_name             as branch_name,
       it.inventory_id            as inventory,
       it.inventory_name          as inventory_name,
       it.inward                  as inward,
       it.outward                 as outward,
       (it.inward - it.outward)   as closing,
       it.ref_no                  as ref_no,
       it.voucher_no              as voucher_no,
       it.base_voucher_type::text as base_voucher_type,
       it.voucher_type_id         as voucher_type,
       it.voucher_id              as voucher,
       it.inventory_voucher_id    as inventory_voucher_id,
       it.category1_id            as category1,
       it.category2_id            as category2,
       it.category3_id            as category3,
       it.category4_id            as category4,
       it.category5_id            as category5,
       it.category6_id            as category6,
       it.category7_id            as category7,
       it.category8_id            as category8,
       it.category9_id            as category9,
       it.category10_id           as category10,
       json_build_object(
               'category1', (case
                                 when it.category1_id is not null then
                                     json_build_object('id', it.category1_id, 'name', co1.name,
                                                       'category',
                                                       json_build_object('id', co1.category_id, 'name', c1.name,
                                                                         'category', c1.category, 'category_type',
                                                                         c1.category_type)
                                     ) end),
               'category2', (case
                                 when it.category2_id is not null then
                                     json_build_object('id', it.category2_id, 'name', co2.name,
                                                       'category',
                                                       json_build_object('id', co2.category_id, 'name', c2.name,
                                                                         'category', c2.category, 'category_type',
                                                                         c2.category_type)
                                     ) end),
               'category3', (case
                                 when it.category3_id is not null then
                                     json_build_object('id', it.category3_id, 'name', co3.name,
                                                       'category',
                                                       json_build_object('id', co3.category_id, 'name', c3.name,
                                                                         'category', c3.category, 'category_type',
                                                                         c3.category_type)
                                     ) end),
               'category4', (case
                                 when it.category4_id is not null then
                                     json_build_object('id', it.category4_id, 'name', co4.name,
                                                       'category',
                                                       json_build_object('id', co4.category_id, 'name', c4.name,
                                                                         'category', c4.category, 'category_type',
                                                                         c4.category_type)
                                     ) end),
               'category5', (case
                                 when it.category5_id is not null then
                                     json_build_object('id', it.category5_id, 'name', co5.name,
                                                       'category',
                                                       json_build_object('id', co5.category_id, 'name', c5.name,
                                                                         'category', c5.category, 'category_type',
                                                                         c5.category_type)
                                     ) end),
               'category6', (case
                                 when it.category6_id is not null then
                                     json_build_object('id', it.category6_id, 'name', co6.name,
                                                       'category',
                                                       json_build_object('id', co6.category_id, 'name', c6.name,
                                                                         'category', c6.category, 'category_type',
                                                                         c6.category_type)
                                     ) end),
               'category7', (case
                                 when it.category7_id is not null then
                                     json_build_object('id', it.category7_id, 'name', co7.name,
                                                       'category',
                                                       json_build_object('id', co7.category_id, 'name', c7.name,
                                                                         'category', c7.category, 'category_type',
                                                                         c7.category_type)
                                     ) end),
               'category8', (case
                                 when it.category8_id is not null then
                                     json_build_object('id', it.category8_id, 'name', co8.name,
                                                       'category',
                                                       json_build_object('id', co8.category_id, 'name', c8.name,
                                                                         'category', c8.category, 'category_type',
                                                                         c8.category_type)
                                     ) end),
               'category9', (case
                                 when it.category9_id is not null then
                                     json_build_object('id', it.category9_id, 'name', co9.name,
                                                       'category',
                                                       json_build_object('id', co9.category_id, 'name', c9.name,
                                                                         'category', c9.category, 'category_type',
                                                                         c9.category_type)
                                     ) end),
               'category10', (case
                                  when it.category10_id is not null then
                                      json_build_object('id', it.category10_id, 'name', co10.name,
                                                        'category',
                                                        json_build_object('id', co10.category_id, 'name', c10.name,
                                                                          'category', c10.category, 'category_type',
                                                                          c10.category_type)
                                      ) end)
       )                          as category
from inv_txn as it
         left join category_option as co1 on it.category1_id = co1.id
         left join category as c1 on co1.category_id = c1.id
         left join category_option as co2 on it.category2_id = co2.id
         left join category as c2 on co2.category_id = c2.id
         left join category_option as co3 on it.category3_id = co3.id
         left join category as c3 on co3.category_id = c3.id
         left join category_option as co4 on it.category4_id = co4.id
         left join category as c4 on co4.category_id = c4.id
         left join category_option as co5 on it.category5_id = co5.id
         left join category as c5 on co5.category_id = c5.id
         left join category_option as co6 on it.category6_id = co6.id
         left join category as c6 on co6.category_id = c6.id
         left join category_option as co7 on it.category7_id = co7.id
         left join category as c7 on co7.category_id = c7.id
         left join category_option as co8 on it.category8_id = co8.id
         left join category as c8 on co8.category_id = c8.id
         left join category_option as co9 on it.category9_id = co9.id
         left join category as c9 on co9.category_id = c9.id
         left join category_option as co10 on it.category10_id = co10.id
         left join category as c10 on co10.category_id = c10.id;