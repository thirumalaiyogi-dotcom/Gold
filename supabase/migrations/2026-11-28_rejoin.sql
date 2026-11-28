-- User-approved 2026-11-28 ("மறுபடி சேர"): a customer whose scheme is closed can start a new scheme on the same account.
-- The finished scheme (its payments + closure details) moves to gold_scheme_history, so every existing rule
-- (passbook, Cashfree limits, reminders) keeps counting only the current scheme. Nothing is thrown away.

create table if not exists public.gold_scheme_history (
  id bigserial primary key,
  customer_id uuid not null references public.gold_customers(id) on delete cascade,
  scheme text, monthly_amount numeric, start_date date,
  status text, closed_on date, close_info jsonb, closed_by text,
  payments jsonb not null default '[]'::jsonb,
  total numeric, installments int,
  archived_at timestamptz not null default now(), archived_by text
);
create index if not exists gold_scheme_history_cust_idx on public.gold_scheme_history (customer_id, id);
alter table public.gold_scheme_history enable row level security;
create policy hist_staff_read on public.gold_scheme_history for select to authenticated using (is_gold_staff());
revoke all on public.gold_scheme_history from anon;
grant select on public.gold_scheme_history to authenticated;

-- Staff: start a new scheme for a closed (not deleted) account.
create or replace function public.gold_restart_scheme(p_id uuid, p_scheme text, p_monthly numeric default null, p_start date default null)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare c public.gold_customers%rowtype; me text := auth.jwt() ->> 'email'; pj jsonb; tot numeric; n int;
begin
  if not public.gold_can('cust.write') then return jsonb_build_object('ok', false, 'err', 'perm'); end if;
  if coalesce(p_scheme, '') !~ '^[A-Za-z0-9_-]{1,64}$' then return jsonb_build_object('ok', false, 'err', 'scheme'); end if;
  select * into c from public.gold_customers where id = p_id for update;
  if not found then return jsonb_build_object('ok', false, 'err', 'nf'); end if;
  if c.status not in ('redeemed', 'refunded', 'nominee') then return jsonb_build_object('ok', false, 'err', 'state', 'status', c.status); end if;
  select coalesce(jsonb_agg(to_jsonb(p) - 'customer_id' order by p.paid_on), '[]'::jsonb), coalesce(sum(p.amount), 0), count(*)
    into pj, tot, n from public.gold_payments p where p.customer_id = p_id;
  insert into public.gold_scheme_history (customer_id, scheme, monthly_amount, start_date, status, closed_on, close_info, closed_by, payments, total, installments, archived_by)
  values (p_id, c.scheme, c.monthly_amount, c.start_date, c.status, c.closed_on, c.close_info, c.closed_by, pj, tot, n, me);
  delete from public.gold_payments where customer_id = p_id;
  update public.gold_customers set scheme = p_scheme, monthly_amount = p_monthly,
    start_date = coalesce(p_start, (now() at time zone 'Asia/Kolkata')::date),
    status = 'active', closed_on = null, close_info = null, closed_by = me
  where id = p_id;
  return jsonb_build_object('ok', true, 'archived_installments', n);
end $$;
revoke all on function public.gold_restart_scheme(uuid, text, numeric, date) from public, anon;
grant execute on function public.gold_restart_scheme(uuid, text, numeric, date) to authenticated;

-- Customer: my earlier (finished) schemes — summary only.
create or replace function public.gold_history(p_mobile text, p_pin text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v jsonb; cid uuid; r jsonb;
begin
  v := public.gold_login(p_mobile, p_pin);
  if v is null or v ? 'wrong' or v ? 'locked' or v ? 'locked_otp' or not (v ? 'name') then
    return jsonb_build_object('ok', false, 'err', 'auth');
  end if;
  select id into cid from public.gold_customers where mobile = trim(p_mobile) limit 1;
  select coalesce(jsonb_agg(jsonb_build_object('scheme', scheme, 'start', start_date, 'status', status, 'closed_on', closed_on,
           'total', total, 'n', installments) order by id desc), '[]'::jsonb)
    into r from public.gold_scheme_history where customer_id = cid;
  return jsonb_build_object('ok', true, 'history', r);
end $$;
revoke all on function public.gold_history(text, text) from public;
grant execute on function public.gold_history(text, text) to anon, authenticated;

-- Deletion frees the mobile number (kept inside close_info for the records), so the person can register again later.
create or replace function public.gold_erase_customer(p_id uuid, p_note text default null)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare m text;
begin
  if not public.gold_can('cust.delete') then return jsonb_build_object('ok', false, 'err', 'perm'); end if;
  select mobile into m from public.gold_customers where id = p_id and status <> 'deleted';
  if m is null then return jsonb_build_object('ok', false, 'err', 'nf'); end if;
  update public.gold_customers set
    status = 'deleted', deleted_at = now(),
    closed_on = coalesce(closed_on, (now() at time zone 'Asia/Kolkata')::date),
    closed_by = coalesce(auth.jwt() ->> 'email', closed_by),
    close_info = coalesce(close_info, '{}'::jsonb) || jsonb_build_object('erase_note', left(coalesce(p_note, ''), 300), 'mobile', m),
    mobile = 'DEL-' || m || '-' || floor(extract(epoch from now()))::bigint,
    pin = encode(gen_random_bytes(24), 'hex'), act_code = null, pin_set = false,
    email = null, address = null, nominee = null, nominee_rel = null, dob = null, anniv = null, pan = null, aadhaar_last4 = null
  where id = p_id;
  delete from public.gold_chat where customer_id = p_id;
  delete from public.gold_visits where customer_id = p_id;
  delete from public.gold_push_subs where customer_id = p_id::text;
  delete from public.gold_likes where customer_id = p_id;
  delete from public.gold_requests where mobile = m;
  delete from public.gold_email_otp where mobile = m;
  delete from public.gold_otp_log where mobile = m;
  delete from public.gold_pin_lock where mobile = m;
  delete from public.gold_attempts where mobile in (m, 'act:' || m);
  return jsonb_build_object('ok', true);
end $$;
