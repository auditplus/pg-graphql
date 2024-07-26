create table if not exists inventory
(
    id                                int            not null generated always as identity primary key,
    name                              text           not null,
    division_id                       int            not null,
    inventory_type                    text           not null default 'STANDARD',
    allow_negative_stock              boolean        not null default false,
    gst_tax_id                        text           not null,
    unit_id                           int            not null,
    loose_qty                         int            not null default 1,
    reorder_inventory_id              int references inventory,
    bulk_inventory_id                 int references inventory,
    qty                               float,
    sale_unit_id                      int,
    purchase_unit_id                  int,
    cess                              json,
    purchase_config                   json           not null default '{
      "mrp_editable": true,
      "tax_editable": true,
      "free_editable": true,
      "disc_1_editable": true,
      "disc_2_editable": true,
      "p_rate_editable": true,
      "s_rate_editable": true
    }'::json,
    sale_config                       json           not null default '{
      "tax_editable": true,
      "disc_editable": true,
      "rate_editable": true,
      "unit_editable": true
    }'::json,
    barcodes                          text[],
    tags                              int[],
    hsn_code                          text,
    description                       text,
    manufacturer_id                   int,
    manufacturer_name                 text,
    vendor_id                         int,
    vendor_name                       text,
    vendors                           int[],
    salts                             int[],
    set_rate_values_via_purchase      boolean                 default false,
    apply_s_rate_from_master_for_sale boolean                 default false,
    category1                         int[],
    category2                         int[],
    category3                         int[],
    category4                         int[],
    category5                         int[],
    category6                         int[],
    category7                         int[],
    category8                         int[],
    category9                         int[],
    category10                        int[],
    created_at                        timestamp      not null default current_timestamp,
    updated_at                        timestamp      not null default current_timestamp,
    constraint loose_qty_gt_0 check (loose_qty > 0),
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint hsn_code_invalid check (hsn_code ~ '^[0-9]*$' and char_length(hsn_code) between 1 and 10),
    constraint inventory_type_invalid check (check_inventory_type(inventory_type))
);
--##
create function sync_inventory_updated_at()
    returns trigger as
$$
begin
    if (TG_OP = 'UPDATE') and exists(select id
                                     from batch
                                     where inventory_id = new.id
                                       and closing < 0) and not new.allow_negative_stock then
        raise exception 'Negative stock found so can not set allow_negative_stock as false';
    end if;
    select name into new.manufacturer_name from manufacturer x where id = new.manufacturer_id;
    select name into new.vendor_name from account x where id = new.vendor_id;
    select new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger sync_inventory_updated_at
    before insert or update
    on inventory
    for each row
execute procedure sync_inventory_updated_at();
