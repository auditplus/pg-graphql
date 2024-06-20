create or replace function apply_member_role()
returns trigger as
$$
declare
    role_name text := (select concat(current_database(), '_', new.name));
    cur_task text := '';
    p permission;
begin
    begin
    if tg_op='INSERT' then
        cur_task = 'create role';
        execute format('create role %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = 'grant role';
        execute format('grant %s to postgres',role_name);
        execute format('grant all on schema graphql to %s',role_name);
        execute format('grant usage ON SCHEMA pg_catalog to %s;',role_name);
        execute format('grant select ON ALL TABLES IN SCHEMA pg_catalog to %s;',role_name);
        execute format('grant usage on schema public to %s;',role_name);
        -- execute format('grant execute on function authenticate to %s;',role_name);
        -- execute format('grant execute on function login to %s;',role_name);
        raise info 'current task: %',cur_task;
        
        cur_task = '000_common';
        execute format('grant execute on function check_gst_no to %s',role_name);
        execute format('grant execute on function json_convert_case to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '001_gst_tax';
        execute format('grant select on table gst_tax to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--003_permission';
        execute format('grant select on table permission to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--004_country';
        execute format('grant select on table country to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--005_uqc';
        execute format('grant select on table uqc to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--006_tds_deductee_type';
        execute format('grant select on table tds_deductee_type to %s',role_name);
        raise info 'current task: %',cur_task;
        cur_task = '--008_organization';
        execute format('grant select on table organization to %s',role_name);
        raise info 'current task: %',cur_task;
    end if;

    if tg_op='UPDATE' then
        cur_task = '--loop permission table for update';
        for p in (select * from permission where id=any(old.perms))
        loop
            if split_part(p.id,'__',2)='execute' then
                cur_task := format('revoke execute on function %s from %s', split_part(p.id,'__',1), role_name);
                execute format('revoke execute on function %s from %s', split_part(p.id,'__',1), role_name);
            elsif array_length(p.fields, 1) > 0 then
                cur_task := format('revoke %s(%s) on table %s from %s', split_part(p.id,'__',2), array_to_string(p.fields,','), split_part(p.id,'__',1), role_name);
                execute format('revoke %s(%s) on table %s from %s', split_part(p.id,'__',2), array_to_string(p.fields,','), split_part(p.id,'__',1), role_name);
            else
                cur_task := format('revoke %s on table %s from %s', split_part(p.id,'__',2), split_part(p.id,'__',1), role_name);
                execute format('revoke %s on table %s from %s', split_part(p.id,'__',2), split_part(p.id,'__',1), role_name);
            end if;
            raise info 'current task: %',cur_task;
        end loop;
    end if;
    ---------------------------------------------------------------------
    cur_task = '--loop permission table for insert';
    for p in (select * from permission where id=any(new.perms))
    loop
        if p.action='execute' then
            cur_task := format('grant execute on function %s to %s', p.resource, role_name);
            execute format('grant execute on function %s to %s', p.resource, role_name);
        elsif array_length(p.fields, 1) > 0 then
            cur_task := format('grant %s(%s) on table %s to %s', p.action, array_to_string(p.fields,','), p.resource, role_name);
            execute format('grant %s(%s) on table %s to %s', p.action, array_to_string(p.fields,','), p.resource, role_name);
        else
            cur_task := format('grant %s on table %s to %s', p.action, p.resource, role_name);
            execute format('grant %s on table %s to %s', p.action, p.resource, role_name);
        end if;
        raise info 'current task: %',cur_task;
    end loop;

    cur_task = '--025_account: row level security';
    ALTER TABLE account ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS account_select_policy ON account;
    DROP POLICY IF EXISTS account_insert_policy ON account;
    DROP POLICY IF EXISTS account_update_policy ON account;
    DROP POLICY IF EXISTS account_delete_policy ON account;
    CREATE POLICY account_select_policy ON account FOR SELECT USING (true);
    CREATE POLICY account_insert_policy ON account FOR INSERT WITH CHECK (is_default=false);
    CREATE POLICY account_update_policy ON account FOR UPDATE USING (is_default=false) WITH CHECK (is_default=false);
    CREATE POLICY account_delete_policy ON account FOR DELETE USING (is_default=false);

    exception
	   when others then
	      raise exception 'error while running task %',cur_task;
    end;
    return new;
end
$$ language plpgsql security definer;
--##
create or replace trigger apply_member_role
    after insert or update
    on member_role
    for each row
execute procedure apply_member_role();
