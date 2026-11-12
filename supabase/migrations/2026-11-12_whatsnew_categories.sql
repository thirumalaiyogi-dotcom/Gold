-- Owner-approved 2026-11-12: "புதுசு என்ன" stories + நகை வகைகள் (swipe cards). Images live in the existing public 'slides' bucket.
create table if not exists public.gold_whatsnew (
  id bigserial primary key,
  title text not null,
  image_url text not null,
  body text,
  btn_label text,
  btn_link text,            -- 'wa' | 'schemes' | 'rate' | https://…
  sort int not null default 0,
  active boolean not null default true,
  ends_on date,
  created_at timestamptz not null default now()
);
create table if not exists public.gold_categories (
  id bigserial primary key,
  name text not null,
  image_url text not null,
  wa_text text,
  sort int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.gold_whatsnew enable row level security;
alter table public.gold_categories enable row level security;
-- customers (anon) read only active rows; staff read all; only settings.write staff change
create policy wn_read on public.gold_whatsnew for select to anon, authenticated using (active and (ends_on is null or ends_on >= (now() at time zone 'Asia/Kolkata')::date));
create policy wn_staff_read on public.gold_whatsnew for select to authenticated using (is_gold_staff());
create policy wn_write on public.gold_whatsnew for all to authenticated using (gold_can('settings.write')) with check (gold_can('settings.write'));
create policy cat_read on public.gold_categories for select to anon, authenticated using (active);
create policy cat_staff_read on public.gold_categories for select to authenticated using (is_gold_staff());
create policy cat_write on public.gold_categories for all to authenticated using (gold_can('settings.write')) with check (gold_can('settings.write'));
revoke all on public.gold_whatsnew, public.gold_categories from anon;
grant select on public.gold_whatsnew, public.gold_categories to anon;
grant select, insert, update, delete on public.gold_whatsnew, public.gold_categories to authenticated;
grant usage, select on sequence public.gold_whatsnew_id_seq, public.gold_categories_id_seq to authenticated;
