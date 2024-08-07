create view batch_detail
as
select b.id,
       b.batch_no,
       b.entry_date,
       round((b.closing)::numeric, 4)::float as closing,
       b.unit_conv,
       b.unit_id,
       u.name                                as unit_name,
       b.branch_id,
       b.branch_name,
       b.inventory_id,
       b.inventory_name,
       b.vendor_id,
       b.vendor_name,
       b.division_id,
       b.division_name,
       b.manufacturer_id,
       b.manufacturer_name,
       b.mrp::float,
       b.s_rate::float,
       b.p_rate::float,
       b.landing_cost::float,
       b.nlc::float,
       b.category1_id,
       b.category2_id,
       b.category3_id,
       b.category4_id,
       b.category5_id,
       b.category6_id,
       b.category7_id,
       b.category8_id,
       b.category9_id,
       b.category10_id,
       json_build_object(
               'category1', b.category1_id,
               'category2', b.category2_id,
               'category3', b.category3_id,
               'category4', b.category4_id,
               'category5', b.category5_id,
               'category6', b.category6_id,
               'category7', b.category7_id,
               'category8', b.category8_id,
               'category9', b.category9_id,
               'category10', b.category10_id
       )                                     as category
from batch as b
         left join unit as u on b.unit_id = u.id;
