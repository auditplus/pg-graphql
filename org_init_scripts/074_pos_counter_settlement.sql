create table if not exists pos_counter_settlement
(
    id             int       not null generated always as identity primary key,
    pos_counter_id int       not null,
    from_date      date      not null,
    to_date        date      not null,
    opening        float     not null default 0,
    closing        float     not null default 0,
    created_by     int       not null,
    created_at     timestamp not null default current_timestamp
);