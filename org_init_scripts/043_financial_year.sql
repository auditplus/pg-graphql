create table if not exists financial_year
(
    id          int  not null generated always as identity primary key,
    fy_start    date not null,
    fy_end      date not null,
    updated_at  timestamp not null default current_timestamp
);
--##
create trigger sync_financial_year_updated_at
    before update
    on financial_year
    for each row
execute procedure sync_updated_at();
--##
create function create_financial_year()
returns financial_year
as
$$
declare
    fy financial_year;
begin
    select * into fy from financial_year order by id desc limit 1;
    insert into financial_year(fy_start, fy_end) values(fy.fy_start+'1y'::interval, fy.fy_end+'1y'::interval)
    returning * into fy;
    return fy;
end;
$$ language plpgsql security definer;