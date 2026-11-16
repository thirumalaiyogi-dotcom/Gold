-- Category gallery: jewellery photos per category (owner approved 16 Nov 2026)
create table if not exists public.gold_category_photos (
  id bigserial primary key,
  category_id bigint not null references public.gold_categories(id) on delete cascade,
  image_url text not null,
  title text,
  note text,
  sort int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists gold_category_photos_cat on public.gold_category_photos(category_id, sort);
alter table public.gold_category_photos enable row level security;
create policy catp_read on public.gold_category_photos for select to anon, authenticated using (active);
create policy catp_staff_read on public.gold_category_photos for select to authenticated using (is_gold_staff());
create policy catp_write on public.gold_category_photos for all to authenticated using (gold_can('settings.write')) with check (gold_can('settings.write'));
revoke all on public.gold_category_photos from anon;
grant select on public.gold_category_photos to anon;
grant select, insert, update, delete on public.gold_category_photos to authenticated;
grant usage, select on sequence public.gold_category_photos_id_seq to authenticated;
