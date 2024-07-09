create table if not exists pos_server
(
    id           int       not null generated always as identity primary key,
    name         text      not null unique,
    branch_id    int       not null,
    mode         text      not null,
    reg_code     int,
    reg_iat      timestamp,
    is_active    boolean   not null default true,
    created_at   timestamp not null default current_timestamp,
    updated_at   timestamp not null default current_timestamp,
    constraint name_min_length check (char_length(trim(name)) > 0),
    constraint mode_invalid check (check_pos_mode(mode))
);
--##
create trigger sync_pos_server_updated_at
    before update
    on pos_server
    for each row
execute procedure sync_updated_at();
--##
create function generate_pos_server_token(pos_server_id int)
returns int
AS
$$
declare
    code int := floor(random()* (999999-100000 + 1) + 100000);
begin

    update pos_server set is_active=false, reg_code=code, reg_iat=current_timestamp
    where id=$1;
    if not found then
        raise exception '%',format('Pos server with id: %s is not found',pos_server_id);
    end if;

    return code;
end
$$ language plpgsql
   security definer;
--##
create function register_pos_server(code int)
returns json
AS
$$
declare
    pos            pos_server := (select pos_server from pos_server where reg_code=code);
    token          text;
    payload        json;
    jwt_secret_key text := (current_setting('app.env')::json)->>'jwt_private_key';
begin
    if pos.id is null then
        raise exception '%',format('Invalid registration code: %s',code);
    end if;

    if current_timestamp > pos.reg_iat+'10m'::interval then
        raise exception 'Registration code expired';
    end if;

    payload = json_build_object('id', pos.id, 'name', pos.name, 'branch_id', pos.branch_id,
                          'mode',pos.mode, 'org', current_database(), 'isu', current_timestamp);
    select addon.sign(payload, jwt_secret_key) into token;
    update pos_server set is_active=true,reg_code=null,reg_iat=null where id=pos.id;
    return json_build_object('claims', payload, 'token', token);
end
$$ language plpgsql
   security definer;
--##
create function deactivate_pos_server(pos_server_id int)
    returns void
AS
$$
declare
    pos pos_server := (select pos_server from pos_server where id = pos_server_id);
begin
    if pos.id is null then
        raise exception 'Pos server not found';
    end if;
    update pos_server set is_active=false where id=pos.id;
end
$$ language plpgsql
    security definer;