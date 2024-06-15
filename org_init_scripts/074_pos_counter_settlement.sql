create table if not exists pos_counter_settlement
(
    id             int       not null generated always as identity primary key,
    pos_counter_id int       not null,
    opening        float     not null default 0,
    closing        float     not null default 0,
    created_by     int       not null,
    created_at     timestamp not null default current_timestamp
);
--##
create function create_pos_settlement(counter_id int)
    returns bool as
$$
declare
    settle_id int;
begin
    insert into pos_counter_settlement (pos_counter_id, created_by)
    values ($1, current_setting('my.id')::int)
    returning id into settle_id;
    update pos_counter_session
    set settlement_id = settle_id
    where pos_counter_id = $1
      and closed_by is not null
      and settlement_id is null;
    if not FOUND then
        raise exception 'closed session not found';
    end if;
    return true;
end;
$$ language plpgsql security definer;
