-- Morning reminder (push v7, kind "rate") to staff phones if today's gold/silver rate is not entered.
-- 09:45 IST and 11:30 IST. Data: Nov 13-21 rates were added the same day from Groww (Chennai) at the user's request.
select cron.schedule('stm_rate_1', '15 4 * * *', $$select public.gold_cron_push('rate')$$);
select cron.schedule('stm_rate_2', '0 6 * * *', $$select public.gold_cron_push('rate')$$);
