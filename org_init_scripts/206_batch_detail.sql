create view batch_detail
as
select b.id, b.batch_no, b.entry_date,
       round((b.inward - b.outward)::numeric, 4)::float as closing,
       b.unit_conv,b.unit_id,u.name as unit_name,
       b.branch, b.branch_name,
       b.inventory,b.inventory_name,
       b.vendor,b.vendor_name,
       b.division, b.division_name,
       b.manufacturer, b.manufacturer_name,
       b.mrp::float, b.s_rate::float, b.p_rate::float, b.landing_cost::float, b.nlc::float,
       b.category1,
       b.category2,
       b.category3,
       b.category4,
       b.category5,
       b.category6,
       b.category7,
       b.category8,
       b.category9,
       b.category10,
       json_build_object(
        'category1', b.category1,
        'category2', b.category2,
        'category3', b.category3,
        'category4', b.category4,
        'category5', b.category5,
        'category6', b.category6,
        'category7', b.category7,
        'category8', b.category8,
        'category9', b.category9,
        'category10', b.category10
    ) as category
from batch as b left join unit as u on b.unit_id=u.id;