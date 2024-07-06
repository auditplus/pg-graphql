create table if not exists print_template
(
    id           int       not null generated always as identity primary key,
    name         text      not null,
    config       json,
    layout       text      not null,
    voucher_mode text,
    created_at   timestamp    not null default current_timestamp,
    updated_at   timestamp    not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint layout_invalid check (check_print_layout(layout)),
    constraint voucher_mode_invalid check (check_voucher_mode(voucher_mode))
);
--##
create trigger sync_print_template_updated_at
    before update
    on print_template
    for each row
execute procedure sync_updated_at();