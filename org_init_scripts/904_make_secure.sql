create or replace procedure make_secure() as
$$
declare
    anon text := (select concat(current_database(),'_anon'));
begin
    REVOKE ALL ON SCHEMA information_schema FROM public;
    REVOKE ALL ON SCHEMA pg_catalog FROM public;
    REVOKE ALL ON SCHEMA public FROM public;
    REVOKE ALL ON ALL TABLES IN SCHEMA pg_catalog FROM public;
    REVOKE ALL ON ALL TABLES IN SCHEMA information_schema FROM public;
    REVOKE ALL ON ALL TABLES IN SCHEMA public FROM public;
    REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM public;

    execute format('create role %s',anon);
    execute format('grant %s to postgres',anon);
    execute format('grant all on schema graphql to %s',anon);

    execute format('grant usage ON SCHEMA pg_catalog to %s;',anon);
    execute format('grant select ON ALL TABLES IN SCHEMA pg_catalog to %s;',anon);
    execute format('grant usage on schema public to %s;',anon);

end
$$ language plpgsql security definer;
--##
call make_secure();


