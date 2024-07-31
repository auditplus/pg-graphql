create table if not exists tds_nature_of_payment
(
    id                         int       not null generated always as identity primary key,
    name                       text      not null,
    section                    text      not null unique,
    ind_huf_rate               float     not null default 0,
    ind_huf_rate_wo_pan        float     not null default 0,
    other_deductee_rate        float     not null default 0,
    other_deductee_rate_wo_pan float     not null default 0,
    threshold                  float     not null default 0,
    created_at                 timestamp not null default current_timestamp,
    updated_at                 timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint section_min_length check (char_length(trim(section)) > 0),
    constraint ind_huf_rate_invalid check (ind_huf_rate between 0 and 100),
    constraint ind_huf_rate_wo_pan_invalid check (ind_huf_rate_wo_pan between 0 and 100),
    constraint other_deductee_rate_invalid check (other_deductee_rate between 0 and 100),
    constraint other_deductee_rate_wo_pan_invalid check (other_deductee_rate_wo_pan between 0 and 100)
);
--##
create trigger tg_sync_tds_nature_of_payment_updated_at
    before update
    on tds_nature_of_payment
    for each row
execute procedure tgf_sync_updated_at();