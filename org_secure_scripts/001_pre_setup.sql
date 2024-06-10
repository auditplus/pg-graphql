create or replace procedure pre_setup() as
$$
declare
    anon text := (select concat(current_database(),'_anon'));
    admin text := (select concat(current_database(),'_admin'));
begin
    set search_path = "public";
    create schema graphql;
    create schema addon;

    set search_path = "addon";
    create extension pgcrypto;
    create extension pgjwt;
    create extension http;
    create extension pg_addon;

    set search_path = "graphql";
    create extension pg_graphql;
    comment on schema public is '@graphql({"inflect_names": true})';

    set search_path = "public";
    execute format('create role %s',anon);
    execute format('create role %s',admin);

    execute format('grant %s to postgres',anon);
    execute format('grant %s to postgres',admin);

    execute format('grant all on schema graphql to %s',anon);
    execute format('grant all on schema graphql to %s',admin);

end
$$ language plpgsql security definer;
--##
call pre_setup();
