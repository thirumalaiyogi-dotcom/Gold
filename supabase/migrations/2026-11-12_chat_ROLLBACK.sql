drop function if exists public.gold_chat_send(text, text, text);
drop function if exists public.gold_chat_get(text, text, bigint, boolean);
alter table public.gold_push_subs drop column if exists staff_email;
drop table if exists public.gold_chat;
