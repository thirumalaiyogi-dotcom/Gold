-- =====================================================================
-- STM Gold · 2026-11-08 · Staff roles + permissions (ROLES PART ONLY of the
-- 2026-11-07 proposal; audit log and KYC are NOT included).
-- Approved by the user in chat on 2026-11-08 ("இரண்டும்" → staff roles).
-- Existing staff become 'super_admin', so nothing they do today breaks.
-- Rollback: 2026-11-08_staff_roles_ROLLBACK.sql
-- =====================================================================
begin;

-- ---------- 1. ROLES ----------
alter table public.gold_staff
  add column if not exists role text not null default 'super_admin',
  add column if not exists active boolean not null default true,
  add column if not exists name text;
alter table public.gold_staff drop constraint if exists gold_staff_role_chk;
alter table public.gold_staff add constraint gold_staff_role_chk
  check (role in ('super_admin','admin','manager','accounts','support'));

-- current staff member's role (null = not staff / inactive)
create or replace function public.gold_role() returns text
language sql stable security definer set search_path = public as $$
  select s.role from public.gold_staff s
  where s.email = lower(coalesce(auth.jwt() ->> 'email','')) and s.active
$$;

-- permission matrix
create or replace function public.gold_can(p text) returns boolean
language sql stable security definer set search_path = public as $$
  select case public.gold_role()
    when 'super_admin' then true
    when 'admin'    then p <> 'staff.manage'
    when 'manager'  then p in ('cust.write','pay.write','rate.write','settings.write','notify.send','req.handle','kyc.review','audit.read')
    when 'accounts' then p in ('pay.write','pay.delete','rate.write','audit.read')
    when 'support'  then p in ('req.handle','notify.send','kyc.view')
    else false end
$$;
revoke all on function public.gold_role() from public, anon;
revoke all on function public.gold_can(text) from public, anon;
grant execute on function public.gold_role() to authenticated;
grant execute on function public.gold_can(text) to authenticated;

-- inactive staff lose access everywhere: tighten is_gold_staff()
create or replace function public.is_gold_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.gold_staff
                 where email = lower(coalesce(auth.jwt() ->> 'email','')) and active)
$$;

-- RESTRICTIVE write policies (reads stay as today: any active staff)
-- customers
drop policy if exists r_cust_ins on public.gold_customers;
drop policy if exists r_cust_upd on public.gold_customers;
drop policy if exists r_cust_del on public.gold_customers;
create policy r_cust_ins on public.gold_customers as restrictive for insert to authenticated
  with check (public.gold_can('cust.write') or public.gold_can('req.handle'));
create policy r_cust_upd on public.gold_customers as restrictive for update to authenticated
  using (public.gold_can('cust.write') or public.gold_can('req.handle'))
  with check (public.gold_can('cust.write') or public.gold_can('req.handle'));
create policy r_cust_del on public.gold_customers as restrictive for delete to authenticated
  using (public.gold_can('cust.delete'));
-- payments
drop policy if exists r_pay_ins on public.gold_payments;
drop policy if exists r_pay_upd on public.gold_payments;
drop policy if exists r_pay_del on public.gold_payments;
create policy r_pay_ins on public.gold_payments as restrictive for insert to authenticated with check (public.gold_can('pay.write'));
create policy r_pay_upd on public.gold_payments as restrictive for update to authenticated using (public.gold_can('pay.write')) with check (public.gold_can('pay.write'));
create policy r_pay_del on public.gold_payments as restrictive for delete to authenticated using (public.gold_can('pay.delete'));
-- requests
drop policy if exists r_req_upd on public.gold_requests;
drop policy if exists r_req_del on public.gold_requests;
create policy r_req_upd on public.gold_requests as restrictive for update to authenticated using (public.gold_can('req.handle')) with check (public.gold_can('req.handle'));
create policy r_req_del on public.gold_requests as restrictive for delete to authenticated using (public.gold_can('req.handle'));
-- rate
do $$ declare t text; begin
  foreach t in array array['gold_rate','gold_rate_history'] loop
    execute format('drop policy if exists r_rate_w on public.%I', t);
    execute format('create policy r_rate_w on public.%I as restrictive for all to authenticated using (true) with check (public.gold_can(''rate.write''))', t);
  end loop;
  -- app settings / content
  foreach t in array array['gold_banners','gold_slides','gold_scheme_img','gold_schemes','gold_popup','gold_links','gold_refer_cfg','gold_notices'] loop
    execute format('drop policy if exists r_set_w on public.%I', t);
    execute format('create policy r_set_w on public.%I as restrictive for all to authenticated using (true) with check (public.gold_can(''settings.write'') or (%L = ''gold_notices'' and public.gold_can(''notify.send'')))', t, t);
  end loop;
end $$;
-- NOTE: "for all ... using (true) with check (perm)" blocks INSERT/UPDATE for roles without the permission,
-- but DELETE only checks USING. Separate delete policies:
do $$ declare t text; begin
  foreach t in array array['gold_rate','gold_rate_history','gold_banners','gold_slides','gold_scheme_img','gold_schemes','gold_popup','gold_links','gold_refer_cfg','gold_notices'] loop
    execute format('drop policy if exists r_del_w on public.%I', t);
    execute format('create policy r_del_w on public.%I as restrictive for delete to authenticated using (public.gold_can(%L) or (%L = ''gold_notices'' and public.gold_can(''notify.send'')))',
      t, case when t like 'gold_rate%' then 'rate.write' else 'settings.write' end, t);
  end loop;
end $$;

-- who recorded a payment
alter table public.gold_payments add column if not exists created_by text default (auth.jwt() ->> 'email');

commit;
