create table if not exists device
(
    id           int       not null generated always as identity primary key,
    name         text      not null,
    access       boolean   default false,
    branches     int[],
    reg_code     int,
    reg_iat      timestamp,
    created_at   timestamp not null default current_timestamp,
    updated_at   timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create trigger sync_device_updated_at
    before update
    on device
    for each row
execute procedure sync_updated_at();
--##
create or replace function generate_device_reg_code(device_id int)
returns int
AS
$$
declare
    code int := floor(random()* (999999-100000 + 1) + 100000);
begin

    update device set access=false, reg_code=code, reg_iat=current_timestamp
    where id=$1;
    if not found then
        raise exception '%',format('Device with id: %s is not found',device_id);
    end if;

    return code;
end
$$ language plpgsql
   security definer;
--##