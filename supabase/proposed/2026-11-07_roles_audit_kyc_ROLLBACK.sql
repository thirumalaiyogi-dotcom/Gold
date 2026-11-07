-- Rollback for 2026-11-07_roles_audit_kyc.sql  (KYC files in the 'kyc' bucket must be removed from the dashboard first)
begin;
drop policy if exists kyc_obj_staff_read on storage.objects;
delete from storage.buckets where id = 'kyc' and not exists (select 1 from storage.objects where bucket_id = 'kyc');
drop function if exists public.gold_kyc_status(text,text);
drop table if exists public.gold_kyc;
do $$ declare t text; begin
  foreach t in array array['gold_customers','gold_payments','gold_requests','gold_rate','gold_schemes','gold_staff','gold_refer_cfg'] loop
    execute format('drop trigger if exists trg_audit on public.%I', t);
  end loop;
  foreach t in array array['gold_rate','gold_rate_history'] loop
    execute format('drop policy if exists r_rate_w on public.%I', t);
  end loop;
  foreach t in array array['gold_banners','gold_slides','gold_scheme_img','gold_schemes','gold_popup','gold_links','gold_refer_cfg','gold_notices'] loop
    execute format('drop policy if exists r_set_w on public.%I', t);
  end loop;
  foreach t in array array['gold_rate','gold_rate_history','gold_banners','gold_slides','gold_scheme_img','gold_schemes','gold_popup','gold_links','gold_refer_cfg','gold_notices'] loop
    execute format('drop policy if exists r_del_w on public.%I', t);
  end loop;
end $$;
drop function if exists public.gold_audit_trg() cascade;
drop table if exists public.gold_audit;
drop policy if exists r_cust_ins on public.gold_customers; drop policy if exists r_cust_upd on public.gold_customers; drop policy if exists r_cust_del on public.gold_customers;
drop policy if exists r_pay_ins on public.gold_payments; drop policy if exists r_pay_upd on public.gold_payments; drop policy if exists r_pay_del on public.gold_payments;
drop policy if exists r_req_upd on public.gold_requests; drop policy if exists r_req_del on public.gold_requests;
alter table public.gold_payments drop column if exists created_by;
create or replace function public.is_gold_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.gold_staff where email = lower(coalesce(auth.jwt() ->> 'email','')))
$$;
drop function if exists public.gold_can(text);
drop function if exists public.gold_role();
alter table public.gold_staff drop constraint if exists gold_staff_role_chk;
alter table public.gold_staff drop column if exists role, drop column if exists active, drop column if exists name;
commit;
