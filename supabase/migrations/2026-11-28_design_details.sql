-- User-approved 2026-11-28 ("ப்ரொபஷனலா வரதுக்கு என்ன தேவையோ அதனை ஆட் பண்ணு"):
-- design details for each jewellery photo (one photo row = one design). All optional; old apps ignore them.
alter table public.gold_category_photos
  add column if not exists code text check (code is null or char_length(code) <= 30),
  add column if not exists weight_g numeric(8,3) check (weight_g is null or (weight_g > 0 and weight_g < 5000)),
  add column if not exists purity text check (purity is null or char_length(purity) <= 20),
  add column if not exists size text check (size is null or char_length(size) <= 30),
  add column if not exists tag text check (tag is null or char_length(tag) <= 24),
  add column if not exists badge text check (badge is null or badge in ('new','best')),
  add column if not exists hallmark boolean not null default false,
  add column if not exists more_images text[] not null default '{}' check (cardinality(more_images) <= 8);
-- RLS unchanged: public reads active rows (catp_read), staff with settings.write edit (catp_write).
