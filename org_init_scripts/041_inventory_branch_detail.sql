create type typ_reorder_mode as enum ('FIXED', 'DYNAMIC');
--##
create table if not exists inventory_branch_detail
(
    inventory          int       not null,
    inventory_name     text      not null,
    branch             int       not null,
    branch_name        text      not null,
    inventory_barcodes text[],
    stock_location     int,
    s_disc             json,
    discount_1         json,
    discount_2         json,
    vendor             int,
    s_customer_disc    jsonb,
    mrp_price_list     json,
    s_rate_price_list  json,
    nlc_price_list     json,
    mrp                numeric(11, 4),
    s_rate             numeric(11, 4),
    p_rate_tax_inc     boolean            default false,
    p_rate             numeric(11, 4),
    landing_cost       numeric(11, 4),
    nlc                numeric(11, 4),
    stock              float     not null default 0,
    reorder_inventory  int       not null,
    reorder_mode       typ_reorder_mode not null default 'DYNAMIC',
    reorder_level      float not null default 0,
    min_order          float,
    max_order          float,
    updated_at         timestamp not null default current_timestamp,
    primary key (inventory, branch)
);
--##
create trigger sync_inventory_branch_detail_at
    before update
    on inventory_branch_detail
    for each row
execute procedure sync_updated_at();
--##
create function set_purchase_price(branch int, branch_name text, inv inventory, mrp float,
                                   s_rate float, rate float, landing_cost float, nlc float)
    returns boolean as
$$
begin
    insert into inventory_branch_detail
    (branch, branch_name, inventory, inventory_name, reorder_inventory, mrp, s_rate, p_rate, landing_cost, nlc)
    values ($1, $2, $3.id, $3.name, coalesce($3.reorder_inventory, $3.id), $4, $5, $6, $7, $8)
    on conflict (branch, inventory) do update
        set inventory_name = excluded.inventory_name,
            branch_name    = excluded.branch_name,
            mrp            = excluded.mrp,
            s_rate         = excluded.s_rate,
            landing_cost   = excluded.landing_cost,
            nlc            = excluded.nlc,
            p_rate         = (case
                                  when inventory_branch_detail.p_rate_tax_inc = true
                                      then excluded.landing_cost
                                  else excluded.p_rate end);
    return true;
end;
$$ language plpgsql;