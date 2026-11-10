-- Referral rule from the company owner (10 Nov 2026):
-- the referrer gets 5% of each referred friend's FIRST instalment, shown as a separate
-- "பரிசுத் தொகை" balance (not added to savings). Old flat ₹200 (both sides) and the
-- 5 / 10-friend milestone gifts are retired.
alter table public.gold_refer_cfg add column if not exists pct numeric(5,2) not null default 5;
alter table public.gold_refer_cfg drop constraint if exists gold_refer_cfg_pct_chk;
alter table public.gold_refer_cfg add constraint gold_refer_cfg_pct_chk check (pct >= 0 and pct <= 50);
update public.gold_refer_cfg set pct = 5, ms5 = null, ms10 = null where id = 1;

create or replace function public.gold_get_passbook(p_mobile text, p_pin text)
 returns json
 language plpgsql
 security definer
 set search_path to 'public', 'extensions'
as $function$
declare c gold_customers; a gold_attempts; cfg gold_refer_cfg;
  pc numeric := 5; cnt int; earned int;
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
    if found and cfg.pct is not null then pc := cfg.pct; end if;
    -- friends who joined with this customer's code and paid at least one instalment
    select count(*), coalesce(sum(round(fp.amount * pc / 100.0)), 0)::int into cnt, earned
      from gold_customers x
      join lateral (select p.amount from gold_payments p where p.customer_id = x.id
                    order by p.paid_on, p.id limit 1) fp on true
      where x.ref_by = c.id;
    return json_build_object('name', c.name, 'scheme', c.scheme, 'start', c.start_date,
      'payments', coalesce((select json_agg(json_build_object('on',p.paid_on,'amount',p.amount,'grams',p.grams,'rate',p.gold_rate) order by p.paid_on)
        from gold_payments p where p.customer_id = c.id), '[]'::json),
      'refer', json_build_object('code', coalesce(c.ref_code, c.mobile), 'count', cnt, 'pct', pc,
        'earned', earned, 'given', coalesce(c.ref_given, 0), 'pending', greatest(earned - coalesce(c.ref_given, 0), 0),
        -- kept for older app / website builds: no flat bonus, no milestones any more
        'bonus', false, 'per', 0, 'ms5', null, 'ms10', null));
  end if;

  insert into gold_attempts(mobile, fails) values (p_mobile, 1)
    on conflict (mobile) do update set fails = gold_attempts.fails + 1;
  update gold_attempts set locked_until = now() + interval '15 minutes', fails = 0
    where mobile = p_mobile and fails >= 5;
  return null;
end $function$;
