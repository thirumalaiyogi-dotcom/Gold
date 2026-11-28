-- Restores the previous gold_login / gold_mobile_ok and removes the new columns + erase function.
drop function if exists public.gold_erase_customer(uuid, text);
create or replace function public.gold_mobile_ok(p_mobile text)
returns boolean language sql stable security definer set search_path to 'public' as $$
  select exists (select 1 from public.gold_customers where mobile = trim(p_mobile));
$$;
create or replace function public.gold_login(p_mobile text, p_pin text)
returns jsonb language plpgsql security definer set search_path to 'public' as $function$
declare m text := trim(p_mobile); r public.gold_pin_lock%rowtype; v jsonb; n int; ma numeric;
begin
  select * into r from public.gold_pin_lock where mobile = m;
  if found and r.locked then return jsonb_build_object('locked_otp', true); end if;
  v := to_jsonb(public.gold_get_passbook(p_mobile => m, p_pin => trim(p_pin)));
  if v is not null and v ? 'locked' then return v; end if;
  if v is null or v = 'null'::jsonb then
    insert into public.gold_pin_lock as l (mobile, fails, locked, updated_at) values (m, 1, false, now())
    on conflict (mobile) do update set fails = l.fails + 1, locked = (l.fails + 1) >= 5, updated_at = now()
    returning fails into n;
    return jsonb_build_object('wrong', true, 'left', greatest(0, 5 - n), 'locked_otp', n >= 5);
  end if;
  delete from public.gold_pin_lock where mobile = m;
  select c.monthly_amount into ma from public.gold_customers c where c.mobile = m limit 1;
  if jsonb_typeof(v) = 'object' and not (v ? 'monthly_amount') then v := v || jsonb_build_object('monthly_amount', ma); end if;
  return v;
end;
$function$;
alter table public.gold_customers drop column if exists status, drop column if exists closed_on, drop column if exists close_info,
  drop column if exists closed_by, drop column if exists deleted_at;
drop trigger if exists gold_close_cleanup on public.gold_customers;
drop function if exists public.gold_close_cleanup();
