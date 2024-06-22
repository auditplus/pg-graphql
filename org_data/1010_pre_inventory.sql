CREATE TABLE TEMP_INV (
  ID int NOT NULL PRIMARY KEY,
  NAME TEXT,
  DIVISION_NAME TEXT,
  GST_TAX TEXT,
  CATEGORY1 TEXT,
  CATEGORY2 TEXT,
  CATEGORY3 TEXT,
  CATEGORY4 TEXT,
  HSN_CODE TEXT,
  MRP FLOAT,
  S_RATE FLOAT
);
--##
create or replace function fn_inventory_from_temp_inv()
returns trigger
language plpgsql
as
$$
declare
    inv_id int;
    div_id int;
    cat1_id int;
    cat2_id int;
    cat3_id int;
    cat4_id int;
    unit_id int;
    gst_tax text := 'gst0';
    _fn_res bool;
    inv_items jsonb;
    input_data json;
    inv_found int;
begin

    select id into div_id from division where name = coalesce(new.division_name,'DEFAULT');
    select id into cat1_id from category_option where name = new.category1 and category_id='INV_CAT1';
    select id into cat2_id from category_option where name = new.category2 and category_id='INV_CAT2';
    select id into cat3_id from category_option where name = new.category3 and category_id='INV_CAT3';
    select id into cat4_id from category_option where name = new.category4 and category_id='INV_CAT4';
    select id into unit_id from unit where name = 'PCS';
    if (new.gst_tax <> 'gst') then
        gst_tax = new.gst_tax;
    end if;
    -- inventory insert
    begin
      if (new.name is not null and char_length(new.name) > 0) then
          insert into inventory(name, division_id, gst_tax_id, unit_id, sale_unit_id, purchase_unit_id, allow_negative_stock, 
                              barcodes, hsn_code, category1, category2, category3, category4)
                      values(new.name, div_id, gst_tax, unit_id, unit_id, unit_id, true, ARRAY[new.id::text]::text[],
                            (case when (new.hsn_code ~ '^[0-9]*$') and (char_length(new.hsn_code) between 1 and 10) then trim(new.hsn_code) else null end),
                            (case when cat1_id is null then null else ARRAY[cat1_id]::int[] end),
                            (case when cat2_id is null then null else ARRAY[cat2_id]::int[] end),
                            (case when cat3_id is null then null else ARRAY[cat3_id]::int[] end),
                            (case when cat4_id is null then null else ARRAY[cat4_id]::int[] end))
                      returning id into inv_id;
          delete from temp_inv where id=new.id;
      end if;

    exception when others then
      raise exception 'insert into inventory(name, division_id, gst_tax_id, unit_id, sale_unit_id, purchase_unit_id, allow_negative_stock, 
                       barcodes, hsn_code, category1, category2, category3, category4)
                       values(%,%,%,%,%,%,%,%,%,%,%,%,%);',new.name, div_id, new.gst_tax, unit_id,unit_id,unit_id,true, ARRAY[new.id::text]::text[],
                        (case when (new.hsn_code ~ '^[0-9]*$') and (char_length(new.hsn_code) between 1 and 10) then trim(new.hsn_code) else null end),
                        (case when cat1_id is null then null else ARRAY[cat1_id]::int[] end),
                        (case when cat2_id is null then null else ARRAY[cat2_id]::int[] end),
                        (case when cat3_id is null then null else ARRAY[cat3_id]::int[] end),
                        (case when cat4_id is null then null else ARRAY[cat4_id]::int[] end);
    end;

    -- inventory opening
    begin
      inv_items =  json_agg(json_build_object('branchId',1, 'inventoryId',inv_id, 'warehouseId',1, 'unitId',1, 'unitConv',1,
      'qty',1.0, 'nlc',1.0, 'cost',1.0, 'rate',1.0, 'landingCost',1.0, 'mrp',new.mrp, 'sRate',new.s_rate,
      'assetAmount',1.0, 'isLooseQty', false));
      if (new.name is not null and char_length(new.name) > 0) then
        input_data = json_build_object('inventoryId',inv_id, 'branchId',1, 'warehouseId',1, 'invItems',inv_items );
        _fn_res = (select * from set_inventory_opening(input_data::json));
      end if;
    exception when others then
      raise exception 'select * from set_inventory_opening(%);',json_build_object('inventoryId',inv_id, 'branchId',1, 'warehouseId',1, 'invItems',inv_items );
    end;

    return new;
end;
$$;
--##
create trigger trig_inventory_from_temp_inv
after insert on temp_inv
for each row
execute procedure fn_inventory_from_temp_inv();
