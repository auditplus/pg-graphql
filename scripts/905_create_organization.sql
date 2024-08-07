create or replace function create_organization(input jsonb)
returns void
as
$$
declare
    book_begin date := ($1->>'book_begin')::date;
    fp_code int := ($1->>'fp_code')::int;
    mon int;
    yr int;
    end_date date;
    cur_task text := '';
    pos_permission text[] := array[
        'member__select',
        'doctor__select',
        'price_list__select',
        'price_list_condition__select',
        'account__select',
        'pos_server__select',
        'inventory__select',
        'inventory_branch_detail__select',
        'financial_year__select',
        'get_voucher__execute',
        'account_pending__select',
        'get_sale_bill__execute',
        'get_recent_sale_bill__execute',
        'customer_sale_history__select',
        'vw_recent_sale_bill__select',
        'create_sale_bill__execute']::text[];
begin
    begin
        cur_task = '--insert organization';
        insert into organization(name, full_name, country, book_begin,gst_no,fp_code, status, owned_by)
        values(($1->>'name')::text,($1->>'full_name')::text,($1->>'country')::text,($1->>'book_begin')::date,
        ($1->>'gst_no')::text,($1->>'fp_code')::int,'ACTIVE',($1->>'owned_by')::int);
        
        cur_task = '--insert financial year';
        mon = date_part('month', book_begin);
        yr = date_part('year', book_begin);
        if mon < (fp_code-1) then
            yr = yr-1;
        end if;
        end_date= TO_DATE(format('%s-%s-01',yr+1, fp_code),'YYYY-MM-DD')-'1d'::interval;
        insert into financial_year(fy_start, fy_end) values(book_begin,end_date);

        cur_task = '--insert admin - member role';
        insert into member_role(name, perms) values ('admin',(select array_agg(id) from permission));
        cur_task = '--insert pos_server - role';
        insert into member_role(name, perms) values ('pos_server',pos_permission);

        cur_task = '--insert admin - member';
        INSERT INTO member(name, pass, remote_access, is_root, role_id, user_id, nick_name)
        values('admin','1',true,true,'admin',(input->>'owned_by')::int,'Administrator');

        cur_task = '--apply member_role: row level security';
        ALTER TABLE member_role ENABLE ROW LEVEL SECURITY;
        DROP POLICY IF EXISTS member_role_select_policy ON member_role;
        DROP POLICY IF EXISTS member_role_insert_policy ON member_role;
        DROP POLICY IF EXISTS member_role_update_policy ON member_role;
        DROP POLICY IF EXISTS member_role_delete_policy ON member_role;
        CREATE POLICY member_role_select_policy ON member_role FOR SELECT USING (true);
        CREATE POLICY member_role_insert_policy ON member_role FOR INSERT WITH CHECK (name <> 'admin');
        CREATE POLICY member_role_update_policy ON member_role FOR UPDATE USING (name <> 'admin') WITH CHECK (name <> 'admin');
        CREATE POLICY member_role_delete_policy ON member_role FOR DELETE USING (name <> 'admin');

        --member with name: admin, role: admin should not be edited

        execute format('grant execute on function register_device to %s_anon', current_database());
        execute format('grant execute on function register_pos_server to %s_anon', current_database());

    exception
	   when others then
	      raise exception 'error while running task %',cur_task;
    end;

end
$$ language plpgsql security definer;
