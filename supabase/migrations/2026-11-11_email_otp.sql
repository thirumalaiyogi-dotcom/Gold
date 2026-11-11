-- Email OTP (owner-approved 2026-11-11): one pending code per mobile, server-only.
create table if not exists public.gold_email_otp (
  mobile     text primary key,
  code_hash  text not null,
  expires_at timestamptz not null,
  tries      int not null default 0,
  created_at timestamptz not null default now()
);
alter table public.gold_email_otp enable row level security;
-- no policies: anon / authenticated cannot read or write; only the email-otp edge function (service_role).
revoke all on public.gold_email_otp from anon, authenticated;
