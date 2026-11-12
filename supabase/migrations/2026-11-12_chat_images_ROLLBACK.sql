drop policy if exists gold_chat_obj_staff_read on storage.objects;
alter table public.gold_chat drop column if exists image;
-- empty the bucket in the dashboard first, then: delete from storage.buckets where id = 'chat';
