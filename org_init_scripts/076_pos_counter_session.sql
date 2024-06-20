create table if not exists pos_counter_session
(
    id                      int       not null generated always as identity primary key,
    pos_counter_id          int       not null,
    denomination            json      not null,
    closed_by_id            int       not null,
    settlement_id           int,
    petty_cash_denomination json,
    closed_at               timestamp not null default current_timestamp
);
--##
create function after_pos_counter_session()
    returns trigger as
$$
begin
    update pos_counter_transaction_breakup
    set session_id = new.id
    where session_id is null
      and pos_counter_id = new.pos_counter_id;
    update pos_counter_transaction
    set session_id = new.id
    where session_id is null
      and pos_counter_id = new.pos_counter_id;
    return new;
end;
$$ language plpgsql;
--##
create trigger after_session_insert
    after insert
    on pos_counter_session
    for each row
execute procedure after_pos_counter_session();
--##
create function close_pos_session(counter_id int, denomination json, petty_cash_denomination json default null)
    returns bool as
$$
declare
    mid int := (select (x::json ->> 'id')::int
                from current_setting('my.claims') x);
begin
    insert into pos_counter_session (pos_counter_id, denomination, closed_by_id, petty_cash_denomination)
    values ($1, $2, mid, $3);
    return true;
end;
$$ language plpgsql security definer;