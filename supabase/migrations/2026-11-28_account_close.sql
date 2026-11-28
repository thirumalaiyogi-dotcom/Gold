-- User-approved 2026-11-28 ("Ellam pannum"): close an account (jewellery / refund / nominee) and fulfil deletion requests.
-- Deletion = erase personal data but keep the money records the shop must keep by law (name, mobile, payments).

alter table public.gold_customers
  add column if not exists status text not null default 'active' check (status in ('active','redeemed','refunded','nominee','deleted')),
  add column if not exists closed_on date,
  add column if not exists close_info jsonb,
  add column if not exists closed_by text,
  add column if not exists deleted_at timestamptz;

-- Deleted accounts are "not registered" for the app / website login screen.
create or replace function public.gold_mobile_ok(p_mobile text)
returns boolean language sql stable security definer set search_path to 'public' as $$
  select exists (select 1 from public.gold_customers where mobile = trim(p_mobile) and status <> 'deleted');
$$;

-- Login: unchanged rules; deleted accounts never log in; the passbook now also carries the closure status.
create or replace function public.gold_login(p_mobile text, p_pin text)
returns jsonb language plpgsql security definer set search_path to 'public' as $function$
declare
  m text := trim(p_mobile);
  r public.gold_pin_lock%rowtype;
  v jsonb;
  n int;
  cu record;
begin
  select monthly_amount, status, closed_on, close_info into cu from public.gold_customers c where c.mobile = m limit 1;
  if found and cu.status = 'deleted' then
    return jsonb_build_object('wrong', true, 'left', 0, 'deleted', true);
  end if;

  select * into r from public.gold_pin_lock where mobile = m;
  if found and r.locked then
    return jsonb_build_object('locked_otp', true);
  end if;

  v := to_jsonb(public.gold_get_passbook(p_mobile => m, p_pin => trim(p_pin)));

  if v is not null and v ? 'locked' then
    return v;
  end if;

  if v is null or v = 'null'::jsonb then
    insert into public.gold_pin_lock as l (mobile, fails, locked, updated_at)
    values (m, 1, false, now())
    on conflict (mobile) do update
      set fails = l.fails + 1, locked = (l.fails + 1) >= 5, updated_at = now()
    returning fails into n;
    return jsonb_build_object('wrong', true, 'left', greatest(0, 5 - n), 'locked_otp', n >= 5);
  end if;

  delete from public.gold_pin_lock where mobile = m;

  if jsonb_typeof(v) = 'object' then
    if not (v ? 'monthly_amount') then v := v || jsonb_build_object('monthly_amount', cu.monthly_amount); end if;
    v := v || jsonb_build_object('status', coalesce(cu.status, 'active'), 'closed_on', cu.closed_on,
      'close_info', case when cu.close_info is null then null else cu.close_info - 'erase_note' - 'staff_note' end);
  end if;
  return v;
end;
$function$;

-- Staff: fulfil a deletion request (needs the cust.delete permission).
create or replace function public.gold_erase_customer(p_id uuid, p_note text default null)
returns jsonb language plpgsql security definer set search_path to 'public', 'extensions' as $$
declare m text;
begin
  if not public.gold_can('cust.delete') then return jsonb_build_object('ok', false, 'err', 'perm'); end if;
  select mobile into m from public.gold_customers where id = p_id;
  if m is null then return jsonb_build_object('ok', false, 'err', 'nf'); end if;
  update public.gold_customers set
    status = 'deleted', deleted_at = now(),
    closed_on = coalesce(closed_on, (now() at time zone 'Asia/Kolkata')::date),
    closed_by = coalesce(auth.jwt() ->> 'email', closed_by),
    close_info = coalesce(close_info, '{}'::jsonb) || jsonb_build_object('erase_note', left(coalesce(p_note, ''), 300)),
    pin = encode(gen_random_bytes(24), 'hex'), act_code = null, pin_set = false,
    email = null, address = null, nominee = null, nominee_rel = null, dob = null, anniv = null, pan = null, aadhaar_last4 = null
  where id = p_id;
  delete from public.gold_chat where customer_id = p_id;
  delete from public.gold_visits where customer_id = p_id;
  delete from public.gold_push_subs where customer_id = p_id;
  delete from public.gold_likes where customer_id = p_id;
  delete from public.gold_requests where mobile = m;
  delete from public.gold_email_otp where mobile = m;
  delete from public.gold_otp_log where mobile = m;
  delete from public.gold_pin_lock where mobile = m;
  delete from public.gold_attempts where mobile in (m, 'act:' || m);
  return jsonb_build_object('ok', true);
end $$;
revoke all on function public.gold_erase_customer(uuid, text) from public, anon;
grant execute on function public.gold_erase_customer(uuid, text) to authenticated;

-- Closed by refund / nominee: stop due reminders by removing that customer's push subscriptions (no edge-function change needed).
-- Deleted accounts are cleaned in gold_erase_customer. Redeemed accounts have all instalments, so no reminder is due anyway.
create or replace function public.gold_close_cleanup() returns trigger language plpgsql security definer set search_path to 'public' as $$
begin
  if new.status in ('refunded','nominee') and coalesce(old.status, 'active') = 'active' then
    delete from public.gold_push_subs where customer_id = new.id;
  end if;
  return new;
end $$;
drop trigger if exists gold_close_cleanup on public.gold_customers;
create trigger gold_close_cleanup after update of status on public.gold_customers for each row execute function public.gold_close_cleanup();
