create view vw_inventory
as
with s1 as (
select id, name, (select c.category from category as c where id=category_option.category_id) as category
 from category_option
 where id =any((select category1 || category2 || category3 || category4 || category5 || category6 || category7 || category8 || category9 || category10 from inventory where id=1)::int[])
)
select a.id, a.name, a.inventory_type, a.allow_negative_stock, a.cess, a.barcodes, a.loose_qty, a.hsn_code, a.description,
       (select json_build_object('id',id, 'name',name) from division where id=a.division_id) as division,
       json_build_object(
               'category1',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category1)),
               'category2',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category2)),
               'category3',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category3)),
               'category4',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category4)),
               'category5',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category5)),
               'category6',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category6)),
               'category7',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category7)),
               'category8',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category8)),
               'category9',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category9)),
               'category10',(select json_agg(row_to_json(s1.*)) from s1 where s1.id = any(a.category10))
       ) as categories,
    (case when a.manufacturer_id is not null then json_build_object('id', a.manufacturer_id, 'name', a.manufacturer_name) end) as manufacturer,
    (case when a.vendor_id is not null then json_build_object('id', a.vendor_id, 'name', a.vendor_name) end) as vendor,
    a.apply_s_rate_from_master_for_sale,
    a.set_rate_values_via_purchase,
    (case when coalesce(array_length(a.salts, 1),0) > 0 then (select row_to_json(pharma_salt.*) from pharma_salt where id = any(a.salts)) end) as salts,
    (select row_to_json(unit.*) from unit where id=a.unit_id) as unit,
    (select row_to_json(unit.*) from unit where id=a.sale_unit_id) as sale_unit,
    (select row_to_json(unit.*) from unit where id=a.purchase_unit_id) as purchase_unit,
    (select row_to_json(gst_tax.*) from gst_tax where id=a.gst_tax_id) as gst_tax,
    purchase_config,
    sale_config,
    bulk_inventory_id,
    qty,
    (case when coalesce(array_length(a.tags, 1),0) > 0 then (select row_to_json(tag.*) from tag where id = any(a.tags)) end) as tags
from inventory as a;

create function get_inventory(int)
returns setof vw_inventory
as
$$
begin
    return query
    select * from vw_inventory
    where id=$1;
end
$$ immutable language plpgsql security definer;
