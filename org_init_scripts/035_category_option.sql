create table if not exists category_option
(
    id            int       not null generated always as identity primary key,
    category_id   text      not null,
    category_name text      not null,
    name          text      not null,
    active        boolean   not null default true,
    updated_at    timestamp not null default current_timestamp,
    unique (category_id, name),
    constraint name_min_length check (char_length(trim(name)) > 0)
);
--##
create function sync_category_option_catname_at()
    returns trigger as
$$
begin
    select x.category into new.category_name from category as x where x.id = new.category_id;
    new.updated_at = current_timestamp;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger sync_category_option_catname_at
    before insert or update
    on category_option
    for each row
execute procedure sync_category_option_catname_at();