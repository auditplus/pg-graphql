create function stock_location_detail(branch int, stock_locations int[] default array []::int[])
    returns table
            (
                stock_location text,
                inventories    jsonb
            )
as
$$
begin
    return query
        with aaa as (select ibd.stock_location                           as stk_loc,
                            jsonb_agg((row (inventory, inventory_name))) as inv
                     from inventory_branch_detail ibd
                     where ibd.branch = $1
                       and (case
                                when array_length($2, 1) > 0 then ibd.stock_location = any ($2)
                                else ibd.stock_location is not null end)
                     group by ibd.stock_location)
        select stock_location.name, inv
        from aaa
                 left join stock_location on aaa.stk_loc = stock_location.id;
end
$$ language plpgsql;
