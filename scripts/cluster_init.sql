create role anon;
create role customer;
create role authenticator with password '1' login noinherit nocreatedb nocreaterole nosuperuser;
GRANT anon TO authenticator;
grant customer to authenticator;

-- Revoking and granting needs to be done once after every change on database
REVOKE ALL ON SCHEMA graphql FROM public;
REVOKE ALL ON SCHEMA information_schema FROM public;
REVOKE ALL ON SCHEMA pg_catalog FROM public;
REVOKE ALL ON SCHEMA public FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA pg_catalog FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA graphql FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA information_schema FROM public;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM public;
REVOKE ALL ON ALL FUNCTION IN SCHEMA public FROM public;

GRANT ALL ON ALL TABLES IN SCHEMA pg_catalog TO authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA graphql TO authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA information_schema TO authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticator;


GRANT EXECUTE ON FUNCTION member_login TO anon;
