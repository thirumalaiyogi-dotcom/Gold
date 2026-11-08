-- 2026-11-08 · staff with notify.send may delete rows from the notification history (gold_push_log)
-- Rollback: drop policy push_log_staff_del on public.gold_push_log; revoke delete on public.gold_push_log from authenticated;
grant delete on public.gold_push_log to authenticated;
drop policy if exists push_log_staff_del on public.gold_push_log;
create policy push_log_staff_del on public.gold_push_log for delete to authenticated using (public.gold_can('notify.send'));
