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
    new.closed_at = current_timestamp;
    insert into pos_counter_session (pos_counter_id) values (new.pos_counter_id);
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger start_session
    after update
    on pos_counter_session
    for each row
    when (new.closed_by is not null)
execute procedure start_pos_session();
--##
create function start_pos_session()
    returns trigger as
$$
begin
    new.closed_at = current_timestamp;
    insert into pos_counter_session (pos_counter_id) values (new.pos_counter_id);
    return new;
end;
$$ language plpgsql security definer;