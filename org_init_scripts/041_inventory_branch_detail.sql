create table if not exists inventory_branch_detail
(
    inventory_id         int       not null,
    inventory_name       text      not null,
    branch_id            int       not null,
    branch_name          text      not null,
    inventory_barcodes   text[],
    stock_location_id    text,
    s_disc               json,
    discount_1           json,
    discount_2           json,
    vendor_id            int,
    s_customer_disc      jsonb,
    mrp_price_list       json,
    s_rate_price_list    json,
    nlc_price_list       json,
    mrp                  float,
    s_rate               float,
    p_rate_tax_inc       boolean            default false,
    p_rate               float,
    landing_cost         float,
    nlc                  float,
    stock                float     not null default 0,
    reorder_inventory_id int       not null,
    reorder_mode         text      not null default 'DYNAMIC',
    reorder_level        float     not null default 0,
    min_order            float,
    max_order            float,
    updated_at           timestamp not null default current_timestamp,
    primary key (inventory_id, branch_id),
    constraint mrp_precision check (scale(mrp::numeric) <= 4),
    constraint s_rate_precision check (scale(s_rate::numeric) <= 4),
    constraint p_rate_precision check (scale(p_rate::numeric) <= 4),
    constraint landing_cost_precision check (scale(landing_cost::numeric) <= 4),
    constraint nlc_precision check (scale(nlc::numeric) <= 4),
    constraint reorder_mode_invalid check (check_reorder_mode(reorder_mode))
);
--##
create function before_inventory_branch_detail()
    returns trigger as
$$
begin
    select name into new.branch_name from branch where id = new.branch_id;
    select name, coalesce(reorder_inventory_id, id), barcodes
    into new.inventory_name, new.reorder_inventory_id, new.inventory_barcodes
    from inventory
    where id = new.inventory_id;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql;
--##
create trigger sync_inventory_branch_detail
    before insert or update
    on inventory_branch_detail
    for each row
execute procedure before_inventory_branch_detail();
--##
create function set_purchase_price(branch int, branch_name text, inv inventory, mrp float,
                                   s_rate float, rate float, landing_cost float, nlc float)
    returns boolean as
$$
begin
    insert into inventory_branch_detail
    (branch_id, branch_name, inventory_id, inventory_name, reorder_inventory_id, mrp, s_rate, p_rate, landing_cost, nlc)
    values ($1, $2, $3.id, $3.name, coalesce($3.reorder_inventory_id, $3.id), $4, $5, $6, $7, $8)
    on conflict (branch_id, inventory_id) do update
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
$$ language plpgsql security definer;