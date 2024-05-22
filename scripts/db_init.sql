create extension pg_graphql;
grant usage on schema graphql to anon;
grant usage on schema graphql TO customer;

create schema online_sale;
grant usage on schema online_sale to anon;
grant usage on schema online_sale to customer;

comment on schema online_sale is e'@graphql({"inflect_names": true})'
