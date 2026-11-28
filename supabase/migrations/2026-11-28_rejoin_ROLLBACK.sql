-- Note: rolling back loses nothing only if no scheme was restarted yet (history rows hold old payments).
drop function if exists public.gold_history(text, text);
drop function if exists public.gold_restart_scheme(uuid, text, numeric, date);
drop table if exists public.gold_scheme_history;
-- gold_erase_customer: re-apply the version in 2026-11-28_account_close.sql if needed.
