create table if not exists pos_counter_settlement
(
    id            bigserial not null primary key,
    opening       float     not null default 0,
    closing       float     not null default 0,
    created_by_id bigint    not null,
    created_at    timestamp not null default current_timestamp
);
--##
create function create_pos_settlement(counter_ids bigint[])
    returns pos_counter_settlement as
$$
declare
    mid         bigint := (select (x::json ->> 'id')::bigint
                           from current_setting('my.claims') x);
    settlement  pos_counter_settlement;
    session_ids bigint[];
begin
    insert into pos_counter_settlement (created_by_id)
    values (mid)
    returning * into settlement;
    with a as
             (update pos_counter_session set settlement_id = settlement.id
                 where pos_counter_id = any ($1) and settlement_id is null returning id)
    select array_agg(id)
    into session_ids
    from a;
    if coalesce(array_length(session_ids, 1), 0) = 0 then
        raise exception 'Closed session not found';
    end if;
    update pos_counter_transaction set settlement_id = settlement.id where session_id = any (session_ids);
    update pos_counter_transaction_breakup set settlement_id = settlement.id where session_id = any (session_ids);
    return settlement;
end;
$$ language plpgsql security definer;