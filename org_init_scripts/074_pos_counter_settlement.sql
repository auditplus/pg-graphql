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
    mid int := (select (x::json ->> 'id')::int
                from current_setting('my.claims') x);
begin
    insert into pos_counter_settlement (pos_counter_id, created_by)
    values ($1, mid);
    return true;
end;
$$ language plpgsql security definer;
--##
create function after_pos_counter_settlement()
    returns trigger as
$$
begin
    update pos_counter_session
    set settlement_id = new.id
    where settlement_id is null
      and pos_counter_id = new.pos_counter_id;
    if not FOUND then
        raise exception 'There is no closed session';
    end if;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger after_settlement_insert
    after insert
    on pos_counter_settlement
    for each row
execute procedure after_pos_counter_settlement();