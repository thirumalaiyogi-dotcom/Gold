-- User-approved 2026-11-28: existing customers can add / change their optional KYC from "என் விவரம்".
-- mobile + mPIN checked through gold_login (same lock rules). Returns only masked values.
create or replace function public.gold_kyc(p_mobile text, p_pin text, p_save boolean default false, p_pan text default null, p_aadhaar_last4 text default null)
returns jsonb language plpgsql security definer set search_path to 'public' as $$
declare v jsonb; cid uuid; pn text := nullif(upper(btrim(coalesce(p_pan,''))), ''); ad text := nullif(btrim(coalesce(p_aadhaar_last4,'')), ''); c record;
begin
  v := public.gold_login(p_mobile, p_pin);
  if v is null or v ? 'wrong' or v ? 'locked' or v ? 'locked_otp' or not (v ? 'name') then
    return jsonb_build_object('ok', false, 'err', 'auth');
  end if;
  select id into cid from public.gold_customers where mobile = trim(p_mobile) limit 1;
  if cid is null then return jsonb_build_object('ok', false, 'err', 'auth'); end if;
  if p_save then
    if pn is not null and pn !~ '^[A-Z]{5}[0-9]{4}[A-Z]$' then return jsonb_build_object('ok', false, 'err', 'pan'); end if;
    if ad is not null and ad !~ '^[0-9]{4}$' then return jsonb_build_object('ok', false, 'err', 'aadhaar'); end if;
    -- PAN: not sent (null) = keep the current one; Aadhaar: empty = remove
    update public.gold_customers set pan = case when p_pan is null then pan else pn end, aadhaar_last4 = ad where id = cid;
  end if;
  select pan, aadhaar_last4 into c from public.gold_customers where id = cid;
  return jsonb_build_object('ok', true,
    'pan', case when c.pan is null then null else substr(c.pan,1,2) || '•••••' || substr(c.pan,8,3) end,
    'aadhaar', c.aadhaar_last4);
end $$;
revoke all on function public.gold_kyc(text, text, boolean, text, text) from public;
grant execute on function public.gold_kyc(text, text, boolean, text, text) to anon, authenticated;
