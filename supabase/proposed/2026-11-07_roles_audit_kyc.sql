-- =====================================================================
-- STM Gold · PROPOSED migration (NOT APPLIED) · 2026-11-07
-- 1) Staff roles + permissions (enforced in the database, not only the UI)
-- 2) Audit log (who changed what)
-- 3) KYC (documents in a PRIVATE bucket, staff review)
-- Apply only after owner approval, first on a Supabase branch / staging.
-- Rollback: 2026-11-07_roles_audit_kyc_ROLLBACK.sql
-- Existing staff become 'super_admin' so nothing they can do today breaks.
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

-- ---------- 2. AUDIT LOG ----------
create table if not exists public.gold_audit (
  id bigserial primary key,
  at timestamptz not null default now(),
  actor text,                 -- staff email, or 'system' (edge functions / cron)
  role text,
  action text not null,       -- INSERT / UPDATE / DELETE
  tbl text not null,
  row_pk text,
  old_row jsonb,
  new_row jsonb
);
create index if not exists gold_audit_at on public.gold_audit (at desc);
alter table public.gold_audit enable row level security;
revoke all on public.gold_audit from anon, authenticated;
grant select on public.gold_audit to authenticated;
drop policy if exists audit_read on public.gold_audit;
create policy audit_read on public.gold_audit for select to authenticated using (public.gold_can('audit.read'));

create or replace function public.gold_audit_trg() returns trigger
language plpgsql security definer set search_path = public as $$
declare o jsonb; n jsonb;
begin
  o := case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) end;
  n := case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) end;
  -- never copy secrets into the log
  o := o - 'pin' - 'act_code'; n := n - 'pin' - 'act_code';
  insert into public.gold_audit(actor, role, action, tbl, row_pk, old_row, new_row)
  values (coalesce(auth.jwt() ->> 'email', 'system'), public.gold_role(), tg_op, tg_table_name,
          coalesce(n ->> 'id', o ->> 'id', n ->> 'key', o ->> 'key', n ->> 'email', o ->> 'email'), o, n);
  return coalesce(new, old);
end $$;
revoke all on function public.gold_audit_trg() from public, anon, authenticated;

do $$ declare t text; begin
  foreach t in array array['gold_customers','gold_payments','gold_requests','gold_rate','gold_schemes','gold_staff','gold_refer_cfg'] loop
    execute format('drop trigger if exists trg_audit on public.%I', t);
    execute format('create trigger trg_audit after insert or update or delete on public.%I for each row execute function public.gold_audit_trg()', t);
  end loop;
end $$;

-- ---------- 3. KYC ----------
create table if not exists public.gold_kyc (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.gold_customers(id) on delete cascade,
  doc_type text not null check (doc_type in ('aadhaar','pan','voter','dl','passport')),
  doc_last4 text check (doc_last4 ~ '^[0-9A-Za-z]{4}$'),   -- only the last 4 characters are stored
  front_path text,            -- object path inside the PRIVATE bucket 'kyc'
  back_path text,
  status text not null default 'pending' check (status in ('pending','verified','rejected')),
  note text,
  submitted_at timestamptz not null default now(),
  reviewed_by text,
  reviewed_at timestamptz,
  unique (customer_id, doc_type)
);
alter table public.gold_kyc enable row level security;
revoke all on public.gold_kyc from anon;
grant select, update on public.gold_kyc to authenticated;
drop policy if exists kyc_staff_read on public.gold_kyc;
drop policy if exists kyc_staff_review on public.gold_kyc;
create policy kyc_staff_read on public.gold_kyc for select to authenticated using (public.gold_can('kyc.review') or public.gold_can('kyc.view'));
create policy kyc_staff_review on public.gold_kyc for update to authenticated using (public.gold_can('kyc.review')) with check (public.gold_can('kyc.review'));
-- customers submit through an Edge Function (kyc-submit: mobile + mPIN check, service role) → no anon insert here.

-- customer can see only their own KYC status (mobile + PIN, same pattern as gold_profile)
create or replace function public.gold_kyc_status(p_mobile text, p_pin text) returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $$
declare c public.gold_customers;
begin
  select * into c from public.gold_customers where mobile = trim(p_mobile);
  if not found or c.pin is null or c.pin <> crypt(trim(p_pin), c.pin) then return null; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('doc', doc_type, 'last4', doc_last4, 'status', status, 'note', note, 'at', submitted_at))
                   from public.gold_kyc where customer_id = c.id), '[]'::jsonb);
end $$;
revoke all on function public.gold_kyc_status(text,text) from public;
grant execute on function public.gold_kyc_status(text,text) to anon, authenticated;

drop trigger if exists trg_audit on public.gold_kyc;
create trigger trg_audit after insert or update or delete on public.gold_kyc for each row execute function public.gold_audit_trg();

-- private bucket (5 MB, images / pdf only)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('kyc','kyc', false, 5242880, array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;
drop policy if exists kyc_obj_staff_read on storage.objects;
create policy kyc_obj_staff_read on storage.objects for select to authenticated
  using (bucket_id = 'kyc' and (public.gold_can('kyc.review') or public.gold_can('kyc.view')));
-- no insert/update/delete policies for clients: only the Edge Function (service role) writes to 'kyc'.

commit;
