create procedure setup() as
$$
declare
    anon text := (select concat(current_database(),'_anon'));
    admin text := (select concat(current_database(),'_admin'));
begin
    set search_path = "public";
    REVOKE ALL ON SCHEMA information_schema FROM public;
    REVOKE ALL ON SCHEMA pg_catalog FROM public;
    REVOKE ALL ON SCHEMA public FROM public;
    REVOKE ALL ON ALL TABLES IN SCHEMA pg_catalog FROM public;
    REVOKE ALL ON ALL TABLES IN SCHEMA information_schema FROM public;
    REVOKE ALL ON ALL TABLES IN SCHEMA public FROM public;
    REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM public;

    execute format('grant usage ON SCHEMA pg_catalog to %s;', admin);
    execute format('grant select ON ALL TABLES IN SCHEMA pg_catalog to %s;',admin);
    execute format('grant usage on schema public to %s;',admin);
    execute format('grant execute on function authenticate to %s;',admin);
    execute format('grant execute on function login to %s;',admin);

    execute format('grant usage ON SCHEMA pg_catalog to %s;',anon);
    execute format('grant select ON ALL TABLES IN SCHEMA pg_catalog to %s;',anon);
    execute format('grant usage on schema public to %s;',anon);
    execute format('grant execute on function authenticate to %s;',anon);
    execute format('grant execute on function login to %s;',anon);
end
$$ language plpgsql security definer;
--##
call setup();
