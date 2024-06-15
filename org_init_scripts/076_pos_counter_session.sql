create table if not exists pos_counter_session
(
    id             int not null generated always as identity primary key,
    pos_counter_id int not null,
    settlement_id  int,
    denomination   json,
    closed_by      int,
    closed_at      timestamp
);
--##
create function start_pos_session()
    returns trigger as
$$
begin
    insert into pos_counter_session (pos_counter_id) values (new.id);
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger start_session
    after insert
    on pos_counter
    for each row
execute procedure start_pos_session();
--##
create function close_pos_session(pos_counter_id int, denomination json)
    returns bool as
$$
begin
    update pos_counter_session
    set closed_by    = current_setting('my.id')::int,
        denomination = $2,
        closed_at    = current_timestamp
    where pos_counter_id = $1
      and closed_by is null;
    insert into pos_counter_session (pos_counter_id) values ($1);
    return true;
end;
$$ language plpgsql security definer;