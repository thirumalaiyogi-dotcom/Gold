-- Chat photos (user-approved 12-11): private bucket; customers go through the chat-img edge function (PIN-checked, signed URLs); staff read directly.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('chat', 'chat', false, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;
create policy gold_chat_obj_staff_read on storage.objects for select to authenticated using (bucket_id = 'chat' and is_gold_staff());
alter table public.gold_chat add column if not exists image text;

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
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 's', sender, 'b', body, 'i', image, 't', created_at) order by id), '[]'::jsonb)
    into msgs from (select * from public.gold_chat where customer_id = cid and id > coalesce(p_after, 0) order by id desc limit 200) x;
  if p_mark then update public.gold_chat set seen = true where customer_id = cid and sender = 's' and not seen; end if;
  return jsonb_build_object('ok', true, 'msgs', msgs, 'unread', unread);
end $$;
