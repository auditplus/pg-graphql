create table if not exists debit_note_inv_item
(
    id             uuid    not null primary key,
    debit_note     int     not null,
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
    disc1_mode     char(1)
        constraint debit_note_inv_item_disc1_mode_invalid check ( disc1_mode in ('P', 'V') ),
    disc2_mode     char(1)
        constraint debit_note_inv_item_disc2_mode_invalid check ( disc2_mode in ('P', 'V') ),
    discount1      float,
    discount2      float,
    taxable_amount float,
    asset_amount   float,
    cgst_amount    float,
    sgst_amount    float,
    igst_amount    float,
    cess_amount    float
);
--##
create trigger delete_debit_note_inv_item
    after delete
    on debit_note_inv_item
    for each row
execute procedure sync_inv_item_delete();