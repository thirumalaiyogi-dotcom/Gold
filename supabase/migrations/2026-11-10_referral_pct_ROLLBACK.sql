-- Rollback of 2026-11-10_referral_pct.sql: flat ₹200 + milestones, original passbook function.
update public.gold_refer_cfg set ms5 = 'வெள்ளி நாணயம்', ms10 = '₹1,000 தள்ளுபடி' where id = 1;
create or replace function public.gold_get_passbook(p_mobile text, p_pin text)
 returns json
 language plpgsql
 security definer
 set search_path to 'public', 'extensions'
as $function$
declare c gold_customers; a gold_attempts; cfg gold_refer_cfg;
  per int := 200; m5 text := 'வெள்ளி நாணயம்'; m10 text := '₹1,000 தள்ளுபடி'; cnt int; bon boolean;
begin
  select * into c from gold_customers where mobile = p_mobile;
  if not found then return null; end if;

  select * into a from gold_attempts where mobile = p_mobile;
  if found and a.locked_until is not null then
    if a.locked_until > now() then
      return json_build_object('locked', true, 'minutes', ceil(extract(epoch from (a.locked_until - now()))/60));
    end if;
    update gold_attempts set fails = 0, locked_until = null where mobile = p_mobile;
  end if;

  if c.pin = crypt(p_pin, c.pin) then
    delete from gold_attempts where mobile = p_mobile;
    select * into cfg from gold_refer_cfg where id = 1;
    if found then per := cfg.per_ref; m5 := cfg.ms5; m10 := cfg.ms10; end if;
    select count(*) into cnt from gold_customers x
      where x.ref_by = c.id and exists (select 1 from gold_payments p where p.customer_id = x.id);
    bon := c.ref_by is not null and exists (select 1 from gold_payments p where p.customer_id = c.id);
    return json_build_object('name', c.name, 'scheme', c.scheme, 'start', c.start_date,
      'payments', coalesce((select json_agg(json_build_object('on',p.paid_on,'amount',p.amount,'grams',p.grams,'rate',p.gold_rate) order by p.paid_on)
        from gold_payments p where p.customer_id = c.id), '[]'::json),
      'refer', json_build_object('code', coalesce(c.ref_code, c.mobile), 'count', cnt, 'bonus', bon, 'per', per, 'ms5', m5, 'ms10', m10));
  end if;

  insert into gold_attempts(mobile, fails) values (p_mobile, 1)
    on conflict (mobile) do update set fails = gold_attempts.fails + 1;
  update gold_attempts set locked_until = now() + interval '15 minutes', fails = 0
    where mobile = p_mobile and fails >= 5;
  return null;
end $function$;
alter table public.gold_refer_cfg drop constraint if exists gold_refer_cfg_pct_chk;
alter table public.gold_refer_cfg drop column if exists pct;
