alter table public.gold_category_photos
  drop column if exists code, drop column if exists weight_g, drop column if exists purity, drop column if exists size,
  drop column if exists tag, drop column if exists badge, drop column if exists hallmark, drop column if exists more_images;
