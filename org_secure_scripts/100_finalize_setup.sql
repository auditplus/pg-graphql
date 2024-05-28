create or replace function member_profile()
    returns member as
$$
declare
    my_name text := current_setting('my.name');
    mem member;
begin
    select * into mem from member where name = my_name;
    mem.pass = null;
    return mem;
end;
$$ language plpgsql immutable security definer;
--##
create or replace function branches(member)
    returns setof branch as
$$
begin
    return query
    select * from branch where (case when $1.is_root then true else $1.id = any(members) end);

end
$$ language plpgsql immutable;
--##
create or replace function voucher_types(member)
    returns setof voucher_type as
$$
declare
    mem_arr jsonb := jsonb_build_array(json_build_object('member',$1.id));
begin
    return query
    select * from voucher_type where members is null or members @> mem_arr;
end
$$ language plpgsql immutable;
--##