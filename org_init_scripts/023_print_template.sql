create domain print_layout as text
    check (value in ('SALE', 'CREDIT_NOTE', 'SALE_QUOTATION', 'PURCHASE', 'DEBIT_NOTE',
                     'STOCK_TRANSFER', 'BATCH', 'RACK', 'CHEQUE_BOOK', 'SETTLEMENT', 'POS_SERVER_SETTLEMENT',
                     'GIFT_VOUCHER', 'CUSTOMER_ADVANCE', 'GOODS_INWARD_NOTE', 'GIFT_VOUCHER_COUPON'));
--##
create table if not exists print_template
(
    id           bigserial    not null primary key,
    name         text         not null,
    config       json,
    layout       print_layout not null,
    voucher_mode voucher_mode,
    created_at   timestamp    not null default current_timestamp,
    updated_at   timestamp    not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_print_template_updated_at
    before update
    on print_template
    for each row
execute procedure sync_updated_at();