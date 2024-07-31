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
create trigger tg_sync_device_updated_at
    before update
    on device
    for each row
execute procedure tgf_sync_updated_at();
--##
create function generate_device_token(device_id int)
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
create function register_device(code int)
returns text
AS
$$
declare
    dev            device := (select device from device where reg_code=code);
    token          text;
    payload        json;
    jwt_secret_key text := (current_setting('app.env')::json)->>'jwt_private_key';
begin
    if dev.id is null then
        raise exception '%',format('Invalid registration code: %s',code);
    end if;

    if current_timestamp > dev.reg_iat+'10m'::interval then
        raise exception 'Registration code expired';
    end if;

    payload = json_build_object('id', dev.id, 'name', dev.name, 'branches', dev.branches,
                                'org', current_database(), 'isu', current_timestamp);
    select addon.sign(payload, jwt_secret_key) into token;
    update device set access=true,reg_code=null,reg_iat=null where id=dev.id;
    return token;
end
$$ language plpgsql
   security definer;
--##
create function deactivate_device(device_id int)
    returns void
AS
$$
declare
    dev device := (select device from device where id = device_id);
begin
    if dev.id is null then
        raise exception 'Device not found';
    end if;
    update device set access=false where id=dev.id;
end
$$ language plpgsql
    security definer;
