create type typ_inventory_type as enum ('STANDARD', 'MULTI_VARIANT');
--##
create table if not exists inventory
(
    id                                int                not null generated always as identity primary key,
    name                              text               not null
        constraint inventory_name_min_length check (char_length(trim(name)) > 0),
    division_id                       int                not null,
    inventory_type                    typ_inventory_type not null default 'STANDARD',
    allow_negative_stock              boolean            not null default false,
    gst_tax_id                        text               not null,
    unit_id                           int                not null,
    loose_qty                         int                not null default 1,
    reorder_inventory_id              int references inventory,
    bulk_inventory_id                 int references inventory,
    qty                               float,
    sale_unit_id                      int                not null,
    purchase_unit_id                  int                not null,
    cess                              json,
    purchase_config                   json               not null,
    sale_config                       json               not null,
    barcodes                          text[],
    tags                              int[],
    hsn_code                          text
        constraint inventory_hsn_code_invalid check (hsn_code ~ '^[0-9]*$' and char_length(hsn_code) between 1 and 10),
    description                       text,
    manufacturer_id                   int,
    manufacturer_name                 text,
    vendor_id                         int,
    vendor_name                       text,
    vendors                           int[],
    salts                             int[],
    set_rate_values_via_purchase      boolean                     default false,
    apply_s_rate_from_master_for_sale boolean                     default false,
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
    created_at                        timestamp          not null default current_timestamp,
    updated_at                        timestamp          not null default current_timestamp,
    check (loose_qty > 0)
);
--##
create trigger sync_inventory_updated_at
    before update
    on inventory
    for each row
execute procedure sync_updated_at();