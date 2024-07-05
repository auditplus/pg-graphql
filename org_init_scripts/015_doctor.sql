create table if not exists doctor
(
    id         int       not null generated always as identity primary key,
    name       text      not null,
    license_no text,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp,
    constraint doctor_name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_doctor_updated_at
    before update
    on doctor
    for each row
execute procedure sync_updated_at();