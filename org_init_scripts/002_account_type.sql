create table if not exists account_type
(
    id             int       not null generated by default as identity (start with 101 increment by 1) primary key,
    name           text      not null,
    allow_account  boolean   not null,
    allow_sub_type boolean   not null,
    base_types     text[]    not null,
    parent_id      int references account_type,
    default_name   text,
    description    text,
    created_at     timestamp not null default current_timestamp,
    updated_at     timestamp not null default current_timestamp,
    constraint base_types_invalid check (check_base_account_types(base_types)),
    constraint default_name_invalid check (check_base_account_type(default_name))
--     constraint account_type_parent_id_required check (not (default_name is null and parent_id is null))
);
--##
create function before_account_type()
    returns trigger as
$$
begin
    if (new.default_name is null and new.parent_id is null) then
        raise exception 'parent_id required';
    end if;
    select allow_account, allow_sub_type, base_types
    into new.allow_account, new.allow_sub_type, new.base_types
    from account_type
    where id = new.parent_id;
    if not new.allow_sub_type then
        raise exception 'can not create/update sub_type of %', new.parent_id;
    end if;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql;
--##
create trigger sync_acc_type
    before insert or update
    on account_type
    for each row
    when (new.default_name is null)
execute procedure before_account_type();