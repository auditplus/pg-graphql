create table if not exists vault
(
    key        text      not null primary key,
    value      text      not null,
    constraint key_min_length check (char_length(trim(key)) > 0),
    constraint value_min_length check (char_length(trim(value)) > 0)
);
--##
create function tgf_vault_event()
    returns trigger as
$$
declare
    vault_key text := ((current_setting('app.env')::json) ->> 'vault_key')::text;
begin
    new.value=addon.encrypt(concat(new.value,'#$#',current_timestamp)::bytea, vault_key::bytea, 'aes')::text;
    return new;
end;
$$ language plpgsql security definer;
--##
create trigger tg_vault_event
    before insert or update
    on vault
    for each row
execute procedure tgf_vault_event();
--##
create function decrypt_vault_value(cipher text)
    returns text
as
$$
declare
    vault_key text := ((current_setting('app.env')::json) ->> 'vault_key')::text;
begin
    return split_part((select convert_from(addon.decrypt(cipher::bytea, vault_key::bytea, 'aes'), 'SQL_ASCII')),'#$#',1)::text;
end;
$$ language plpgsql security definer;
--##
create view vw_vault
as
select key, decrypt_vault_value(value) as value from vault;
--##
create view vw_vault_key
as
select key from vault;