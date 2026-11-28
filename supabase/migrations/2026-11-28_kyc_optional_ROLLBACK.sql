revoke insert (pan, aadhaar_last4) on public.gold_requests from anon;
alter table public.gold_requests drop column if exists pan, drop column if exists aadhaar_last4;
alter table public.gold_customers drop column if exists pan, drop column if exists aadhaar_last4;
