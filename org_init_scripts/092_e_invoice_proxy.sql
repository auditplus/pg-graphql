drop function if exists e_invoie_proxy;
--##
create function e_invoice_proxy(url_path text, method text, gstin text, body jsonb default null, token text default null) returns varchar as $$
    declare
        url text = format('%s%s', (current_setting('app.env')::json)->>'gst_host', url_path);
        gst_reg gst_registration = (SELECT gst_registration FROM gst_registration WHERE gst_no = gstin limit 1);
    begin
        raise info '%',url;
        if (gst_reg.e_invoice_username is null or gst_reg.e_password is null) then
            raise exception 'Username / Password not defined for gstin';
        end if;
        return (select content from addon.http((
           method,
           url,
           ARRAY[
               addon.http_header('gstin',gst_reg.gst_no),
               addon.http_header('username',gst_reg.e_invoice_username),
               addon.http_header('password',gst_reg.e_password),
               addon.http_header('auth-token',token),
               addon.http_header('auth-key',(current_setting('app.env')::json)->>'gst_auth_key')
               ],
           'application/json',
           body
        )::addon.http_request));
    end
$$ language plpgsql security definer;