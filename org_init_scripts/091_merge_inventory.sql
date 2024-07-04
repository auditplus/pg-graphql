create function merge_inventory(dest bigint, src bigint)
    returns boolean as
$$
declare
    div      division;
    dest_inv inventory;
    src_inv  inventory;
begin
    if dest = src then
        raise exception 'Destination Source not same';
    end if;
    select * into dest_inv from inventory where id = dest;
    if not FOUND then
        raise exception 'Destination inventory not found';
    end if;
    select * into src_inv from inventory where id = src;
    if not FOUND then
        raise exception 'Source inventory not found';
    end if;
    if dest_inv.reorder_inventory_id = src then
        raise exception '% mapped on % for re-order purchase so can not merge', src_inv.name, dest_inv.name;
    end if;
    if dest_inv.bulk_inventory_id = src then
        raise exception 'bulk_inventory has conflict';
    end if;
    if dest_inv.allow_negative_stock <> src_inv.allow_negative_stock then
        raise exception 'allow_negative_stock has conflict';
    end if;
    select * into div from division where id = dest_inv.division_id;

    update batch
    set inventory_id      = dest,
        inventory_name    = dest_inv.name,
        manufacturer_id   = dest_inv.manufacturer_id,
        manufacturer_name = dest_inv.manufacturer_name,
        division_id       = div.id,
        division_name     = div.name
    where inventory_id = src;

    update inv_txn
    set inventory_id         = dest,
        inventory_name       = dest_inv.name,
        manufacturer_id      = dest_inv.manufacturer_id,
        manufacturer_name    = dest_inv.manufacturer_name,
        division_id          = dest_inv.division_id,
        division_name        = div.name,
        reorder_inventory_id = coalesce(dest_inv.reorder_inventory_id, dest_inv.id)
    where inventory_id = src;

    update inventory_opening set inventory_id = dest where inventory_id = src;
    update sale_bill_inv_item set inventory_id = dest where inventory_id = src;
    update purchase_bill_inv_item set inventory_id = dest where inventory_id = src;
    update credit_note_inv_item set inventory_id = dest where inventory_id = src;
    update debit_note_inv_item set inventory_id = dest where inventory_id = src;
    update personal_use_purchase_inv_item set inventory_id = dest where inventory_id = src;
    update stock_adjustment_inv_item set inventory_id = dest where inventory_id = src;
    update stock_addition_inv_item set inventory_id = dest where inventory_id = src;
    update stock_deduction_inv_item set inventory_id = dest where inventory_id = src;
    update material_conversion_inv_item set source_inventory_id = dest where source_inventory_id = src;
    update material_conversion_inv_item set target_inventory_id = dest where target_inventory_id = src;

    update inventory
    set category1     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category1, src_inv.category1)) x),
        category2     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category2, src_inv.category2)) x),
        category3     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category3, src_inv.category3)) x),
        category4     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category4, src_inv.category4)) x),
        category5     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category5, src_inv.category5)) x),
        category6     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category6, src_inv.category6)) x),
        category7     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category7, src_inv.category7)) x),
        category8     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category8, src_inv.category8)) x),
        category9     = (select array_agg(distinct x) from unnest(array_cat(dest_inv.category9, src_inv.category9)) x),
        category10    = (select array_agg(distinct x)
                         from unnest(array_cat(dest_inv.category10, src_inv.category10)) x),
        barcodes      = (select array_agg(distinct x) from unnest(array_cat(dest_inv.barcodes, src_inv.barcodes)) x),
        inventory_type= case
                            when (array_length(src_inv.category1, 1) > 0 or array_length(src_inv.category2, 1) > 0 or
                                  array_length(src_inv.category3, 1) > 0 or array_length(src_inv.category4, 1) > 0 or
                                  array_length(src_inv.category5, 1) > 0 or array_length(src_inv.category6, 1) > 0 or
                                  array_length(src_inv.category7, 1) > 0 or array_length(src_inv.category8, 1) > 0 or
                                  array_length(src_inv.category9, 1) > 0 or array_length(src_inv.category10, 1) > 0)
                                then 'MULTI_VARIANT'
                            else inventory.inventory_type end
    where id = dest;

    delete from inventory_branch_detail where inventory_id = src;
    delete from vendor_item_map where inventory_id = src;
    delete from inventory where id = src;
    return true;
end;
$$ language plpgsql security definer;
