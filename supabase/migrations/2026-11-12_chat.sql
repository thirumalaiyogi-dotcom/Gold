-- Owner/user-approved 2026-11-12: WhatsApp-style private chat customer ↔ shop.
create table if not exists public.gold_chat (
  id bigserial primary key,
  customer_id uuid not null references public.gold_customers(id) on delete cascade,
  sender text not null check (sender in ('c','s')),      -- c = customer, s = shop staff
  body text not null check (char_length(body) between 1 and 1000),
  staff_email text,
  seen boolean not null default false,                    -- read by the other side
  created_at timestamptz not null default now()
);
create index if not exists gold_chat_cust_idx on public.gold_chat (customer_id, id);
alter table public.gold_chat enable row level security;
-- staff only (customers go through the PIN-checked RPCs below)
create policy chat_staff_read on public.gold_chat for select to authenticated using (is_gold_staff());
create policy chat_staff_write on public.gold_chat for insert to authenticated with check (is_gold_staff() and sender = 's');
create policy chat_staff_update on public.gold_chat for update to authenticated using (is_gold_staff()) with check (is_gold_staff());
revoke all on public.gold_chat from anon;
grant select, insert, update on public.gold_chat to authenticated;
grant usage, select on sequence public.gold_chat_id_seq to authenticated;

-- staff browsers/phones that want "new question" pushes
alter table public.gold_push_subs add column if not exists staff_email text;

create or replace function public.gold_chat_get(p_mobile text, p_pin text, p_after bigint default 0, p_mark boolean default true)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v jsonb; cid uuid; msgs jsonb; unread int;
begin
  v := public.gold_login(p_mobile, p_pin);
  if v is null or v ? 'wrong' or v ? 'locked' or v ? 'locked_otp' or not (v ? 'name') then
    return jsonb_build_object('ok', false, 'err', 'auth');
  end if;
  select id into cid from public.gold_customers where mobile = trim(p_mobile) limit 1;
  if cid is null then return jsonb_build_object('ok', false, 'err', 'auth'); end if;
  select count(*) into unread from public.gold_chat where customer_id = cid and sender = 's' and not seen;
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 's', sender, 'b', body, 't', created_at) order by id), '[]'::jsonb)
    into msgs from (select * from public.gold_chat where customer_id = cid and id > coalesce(p_after, 0) order by id desc limit 200) x;
  if p_mark then update public.gold_chat set seen = true where customer_id = cid and sender = 's' and not seen; end if;
  return jsonb_build_object('ok', true, 'msgs', msgs, 'unread', unread);
end $$;

create or replace function public.gold_chat_send(p_mobile text, p_pin text, p_body text)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v jsonb; cid uuid; b text := btrim(coalesce(p_body, '')); n int; nid bigint;
begin
  if char_length(b) < 1 or char_length(b) > 1000 then return jsonb_build_object('ok', false, 'err', 'body'); end if;
  v := public.gold_login(p_mobile, p_pin);
  if v is null or v ? 'wrong' or v ? 'locked' or v ? 'locked_otp' or not (v ? 'name') then
    return jsonb_build_object('ok', false, 'err', 'auth');
  end if;
  select id into cid from public.gold_customers where mobile = trim(p_mobile) limit 1;
  if cid is null then return jsonb_build_object('ok', false, 'err', 'auth'); end if;
  select count(*) into n from public.gold_chat where customer_id = cid and sender = 'c' and created_at > now() - interval '1 day';
  if n >= 30 then return jsonb_build_object('ok', false, 'err', 'too_many'); end if;
  insert into public.gold_chat (customer_id, sender, body) values (cid, 'c', b) returning id into nid;
  return jsonb_build_object('ok', true, 'id', nid);
end $$;

revoke all on function public.gold_chat_get(text, text, bigint, boolean) from public;
revoke all on function public.gold_chat_send(text, text, text) from public;
grant execute on function public.gold_chat_get(text, text, bigint, boolean) to anon, authenticated;
grant execute on function public.gold_chat_send(text, text, text) to anon, authenticated;
