create type typ_print_layout as enum ('SALE', 'CREDIT_NOTE', 'SALE_QUOTATION', 'PURCHASE', 'DEBIT_NOTE',
    'STOCK_TRANSFER', 'BATCH', 'RACK', 'CHEQUE_BOOK', 'SETTLEMENT', 'POS_SERVER_SETTLEMENT',
    'GIFT_VOUCHER', 'CUSTOMER_ADVANCE', 'GOODS_INWARD_NOTE', 'GIFT_VOUCHER_COUPON');
--##
create table if not exists print_template
(
    id           int              not null generated always as identity primary key,
    name         text             not null
        constraint print_template_name_min_length check (char_length(trim(name)) > 0),
    config       json,
    layout       typ_print_layout not null,
    voucher_mode typ_voucher_mode,
    created_at   timestamp        not null default current_timestamp,
    updated_at   timestamp        not null default current_timestamp
);
--##
create trigger sync_print_template_updated_at
    before update
    on print_template
    for each row
execute procedure sync_updated_at();