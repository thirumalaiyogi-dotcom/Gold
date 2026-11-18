-- பிடித்தவை (likes / wishlist) for stories + category photos. Owner approved 18 Nov 2026.
-- Customers never touch the table directly: two security-definer RPCs; staff read via RLS.
create table if not exists public.gold_likes (
  id bigserial primary key,
  item_type text not null check (item_type in ('story','photo')),
  item_id bigint not null,
  device_id text not null check (device_id ~ '^[A-Za-z0-9-]{16,64}$'),
  customer_id uuid references public.gold_customers(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (item_type, item_id, device_id)
);
create index if not exists gold_likes_item on public.gold_likes(item_type, item_id);
create index if not exists gold_likes_dev on public.gold_likes(device_id);
alter table public.gold_likes enable row level security;
create policy likes_staff_read on public.gold_likes for select to authenticated using (is_gold_staff());
revoke all on public.gold_likes from anon, authenticated;
grant select on public.gold_likes to authenticated;

-- toggle like; mobile+pin optional (only then the customer's name is attached)
create or replace function public.gold_like_toggle(p_type text, p_id bigint, p_device text, p_mobile text default null, p_pin text default null)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v jsonb; cid uuid; n int; ok boolean;
begin
  if p_type not in ('story','photo') or p_device !~ '^[A-Za-z0-9-]{16,64}$' then return jsonb_build_object('ok', false, 'err', 'bad'); end if;
  if p_type = 'story' then select exists(select 1 from public.gold_whatsnew where id = p_id and active) into ok;
  else select exists(select 1 from public.gold_category_photos where id = p_id and active) into ok; end if;
  if not ok then return jsonb_build_object('ok', false, 'err', 'item'); end if;
  if exists(select 1 from public.gold_likes where item_type = p_type and item_id = p_id and device_id = p_device) then
    delete from public.gold_likes where item_type = p_type and item_id = p_id and device_id = p_device;
    return jsonb_build_object('ok', true, 'liked', false);
  end if;
  select count(*) into n from public.gold_likes where device_id = p_device and created_at > now() - interval '1 day';
  if n >= 100 then return jsonb_build_object('ok', false, 'err', 'too_many'); end if;
  if coalesce(p_mobile, '') <> '' and coalesce(p_pin, '') <> '' then
    v := public.gold_login(p_mobile, p_pin);
    if v is not null and (v ? 'name') and not (v ? 'wrong' or v ? 'locked' or v ? 'locked_otp') then
      select id into cid from public.gold_customers where mobile = trim(p_mobile) limit 1;
    end if;
  end if;
  insert into public.gold_likes(item_type, item_id, device_id, customer_id) values (p_type, p_id, p_device, cid);
  return jsonb_build_object('ok', true, 'liked', true);
end $$;

-- this device's liked items with image/title (for "என் பிடித்தவை")
create or replace function public.gold_likes_mine(p_device text)
returns jsonb language sql security definer set search_path to 'public' as $$
  select coalesce(jsonb_agg(x order by x->>'at' desc), '[]'::jsonb) from (
    select jsonb_build_object('type', l.item_type, 'id', l.item_id, 'at', l.created_at,
      'image', coalesce(w.image_url, p.image_url), 'title', coalesce(w.title, p.title, c.name), 'cat', c.name) x
    from public.gold_likes l
    left join public.gold_whatsnew w on l.item_type = 'story' and w.id = l.item_id and w.active
    left join public.gold_category_photos p on l.item_type = 'photo' and p.id = l.item_id and p.active
    left join public.gold_categories c on c.id = p.category_id
    where p_device ~ '^[A-Za-z0-9-]{16,64}$' and l.device_id = p_device and (w.id is not null or p.id is not null)
    limit 200) s;
$$;

revoke all on function public.gold_like_toggle(text, bigint, text, text, text) from public;
revoke all on function public.gold_likes_mine(text) from public;
grant execute on function public.gold_like_toggle(text, bigint, text, text, text) to anon, authenticated;
grant execute on function public.gold_likes_mine(text) to anon, authenticated;
