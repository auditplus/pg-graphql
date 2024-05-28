create table if not exists credit_note_inv_item
(
    id             uuid    not null primary key,
    credit_note    int     not null,
    batch          int     not null,
    inventory      int     not null,
    unit           int     not null,
    unit_conv      float   not null,
    gst_tax        text    not null,
    qty            float   not null,
    rate           float   not null,
    is_loose_qty   boolean not null default false,
    hsn_code       text,
    cess_on_qty    float,
    cess_on_val    float,
    disc_mode      char(1)
        constraint credit_note_inv_item_disc_mode_invalid check ( disc_mode in ('P', 'V') ),
    discount       float,
    s_inc          int,
    taxable_amount float,
    asset_amount   float,
    cgst_amount    float,
    sgst_amount    float,
    igst_amount    float,
    cess_amount    float
);
--##
create trigger delete_credit_note_inv_item
    after delete
    on credit_note_inv_item
    for each row
execute procedure sync_inv_item_delete();