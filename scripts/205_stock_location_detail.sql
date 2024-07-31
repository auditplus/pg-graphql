create function stock_location_detail(branch int, stock_locations text[] default array []::text[])
    returns jsonb as
$$
begin
    return
        (with a as (select ibd.stock_location_id                         as stk_loc,
                           jsonb_agg(jsonb_build_object('inventory_id', inventory_id, 'inventory_name',
                                                        inventory_name)) as inv
                    from inventory_branch_detail ibd
                    where ibd.branch_id = $1
                      and (case
                               when array_length($2, 1) > 0 then ibd.stock_location_id = any ($2)
                               else ibd.stock_location_id is not null end)
                    group by ibd.stock_location_id)
         select jsonb_agg(jsonb_build_object('stock_location_id', a.stk_loc, 'inventories', a.inv))
         from a);
end
$$ language plpgsql;