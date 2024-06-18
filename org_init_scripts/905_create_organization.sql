create or replace function create_organization(input_data jsonb) 
returns void
as
$$
declare
    input jsonb := json_convert_case($1, 'snake_case');
    book_begin date := (input->>'book_begin')::date;
    fp_code int := (input->>'fp_code')::int;
    mon int;
    yr int;
    end_date date;
    cur_task text := '';
begin

    begin
        cur_task = '--insert organization';
        insert into organization(name, full_name, country, book_begin,gst_no,fp_code, status, owned_by)
        values((input->>'name')::text,(input->>'full_name')::text,(input->>'country')::text,(input->>'book_begin')::date,
        (input->>'gst_no')::text,(input->>'fp_code')::int,'ACTIVE',(input->>'owned_by')::int);
        
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

        cur_task = '--insert admin - member';
        INSERT INTO member(name, pass, remote_access, is_root, role_id, user_id, nick_name)
        values('admin','1',true,true,1,(input->>'owned_by')::int,'Administrator');

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

    exception
	   when others then
	      raise exception 'error while running task %',cur_task;
    end;

end
$$ language plpgsql security definer;
