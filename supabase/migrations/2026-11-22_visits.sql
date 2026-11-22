-- User-approved 2026-11-22: "நகை வாங்க வருகை" — customer books a shop visit (date + time of day).
-- The booking also drops a line into the customer's chat, so staff get the existing chat push and can reply / confirm there.
create table if not exists public.gold_visits (
  id bigserial primary key,
  customer_id uuid not null references public.gold_customers(id) on delete cascade,
  visit_on date not null,
  slot text not null check (slot in ('m','e')),             -- m = காலை, e = மாலை
  note text check (note is null or char_length(note) <= 300),
  status text not null default 'new' check (status in ('new','ok','done','cancel')),
  staff_email text,
  created_at timestamptz not null default now()
);
create index if not exists gold_visits_day_idx on public.gold_visits (visit_on, status);
create index if not exists gold_visits_cust_idx on public.gold_visits (customer_id, id);
alter table public.gold_visits enable row level security;
create policy visits_staff_read on public.gold_visits for select to authenticated using (is_gold_staff());
create policy visits_staff_update on public.gold_visits for update to authenticated using (is_gold_staff()) with check (is_gold_staff());
revoke all on public.gold_visits from anon;
grant select, update on public.gold_visits to authenticated;

-- customer: book (mobile + PIN checked; tomorrow .. +60 days; at most 2 open bookings)
create or replace function public.gold_visit_book(p_mobile text, p_pin text, p_date date, p_slot text, p_note text default null)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v jsonb; cid uuid; n int; today date := (now() at time zone 'Asia/Kolkata')::date; nid bigint; nt text := nullif(btrim(coalesce(p_note,'')), '');
begin
  if p_slot not in ('m','e') then return jsonb_build_object('ok', false, 'err', 'slot'); end if;
  if p_date is null or p_date < today or p_date > today + 60 then return jsonb_build_object('ok', false, 'err', 'date'); end if;
  if nt is not null and char_length(nt) > 300 then return jsonb_build_object('ok', false, 'err', 'note'); end if;
  v := public.gold_login(p_mobile, p_pin);
  if v is null or v ? 'wrong' or v ? 'locked' or v ? 'locked_otp' or not (v ? 'name') then
    return jsonb_build_object('ok', false, 'err', 'auth');
  end if;
  select id into cid from public.gold_customers where mobile = trim(p_mobile) limit 1;
  if cid is null then return jsonb_build_object('ok', false, 'err', 'auth'); end if;
  select count(*) into n from public.gold_visits where customer_id = cid and status in ('new','ok') and visit_on >= today;
  if n >= 2 then return jsonb_build_object('ok', false, 'err', 'too_many'); end if;
  insert into public.gold_visits (customer_id, visit_on, slot, note) values (cid, p_date, p_slot, nt) returning id into nid;
  insert into public.gold_chat (customer_id, sender, body) values (cid, 'c',
    '📅 நகை வாங்க கடைக்கு வருகிறேன்: ' || to_char(p_date, 'DD-MM-YYYY') || ' · ' || case when p_slot = 'm' then 'காலை' else 'மாலை' end
    || coalesce(E'\n' || nt, ''));
  return jsonb_build_object('ok', true, 'id', nid);
end $$;

-- customer: my upcoming bookings (+ cancel)
create or replace function public.gold_visit_mine(p_mobile text, p_pin text, p_cancel bigint default null)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v jsonb; cid uuid; today date := (now() at time zone 'Asia/Kolkata')::date; r jsonb;
begin
  v := public.gold_login(p_mobile, p_pin);
  if v is null or v ? 'wrong' or v ? 'locked' or v ? 'locked_otp' or not (v ? 'name') then
    return jsonb_build_object('ok', false, 'err', 'auth');
  end if;
  select id into cid from public.gold_customers where mobile = trim(p_mobile) limit 1;
  if cid is null then return jsonb_build_object('ok', false, 'err', 'auth'); end if;
  if p_cancel is not null then
    update public.gold_visits set status = 'cancel' where id = p_cancel and customer_id = cid and status in ('new','ok');
    if found then
      insert into public.gold_chat (customer_id, sender, body) values (cid, 'c', '❌ கடை வருகை பதிவை ரத்து செய்தேன்.');
    end if;
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'd', visit_on, 's', slot, 'n', note, 'st', status) order by visit_on), '[]'::jsonb)
    into r from public.gold_visits where customer_id = cid and status in ('new','ok') and visit_on >= today;
  return jsonb_build_object('ok', true, 'visits', r);
end $$;

revoke all on function public.gold_visit_book(text, text, date, text, text) from public;
revoke all on function public.gold_visit_mine(text, text, bigint) from public;
grant execute on function public.gold_visit_book(text, text, date, text, text) to anon, authenticated;
grant execute on function public.gold_visit_mine(text, text, bigint) to anon, authenticated;
