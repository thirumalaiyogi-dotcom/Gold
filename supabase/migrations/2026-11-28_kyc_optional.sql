-- User-approved 2026-11-28: optional KYC in the join form ("விருப்பம்" tick → PAN + Aadhaar).
-- Aadhaar: ONLY the last 4 digits are stored (UIDAI rules: a shop must not keep full Aadhaar numbers).
-- PAN: full 10-character format checked. Both optional.
alter table public.gold_requests
  add column if not exists pan text check (pan is null or pan ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'),
  add column if not exists aadhaar_last4 text check (aadhaar_last4 is null or aadhaar_last4 ~ '^[0-9]{4}$');
alter table public.gold_customers
  add column if not exists pan text check (pan is null or pan ~ '^[A-Z]{5}[0-9]{4}[A-Z]$'),
  add column if not exists aadhaar_last4 text check (aadhaar_last4 is null or aadhaar_last4 ~ '^[0-9]{4}$');
grant insert (pan, aadhaar_last4) on public.gold_requests to anon;
-- reads stay staff-only (existing RLS on both tables).
