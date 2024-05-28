create table if not exists division
(
    id         int       not null generated always as identity primary key,
    name       text      not null,
    created_at timestamp not null default current_timestamp,
    updated_at timestamp not null default current_timestamp
);
--##
create trigger sync_division_updated_at
    before update
    on division
    for each row
execute procedure sync_updated_at();
--##
create function get_division(v_id int)
    returns setof division AS
$$
begin
    return query select * from division where id = $1;
    if not found then
        raise exception 'Invalid division';
    end if;
end;
$$ language plpgsql;