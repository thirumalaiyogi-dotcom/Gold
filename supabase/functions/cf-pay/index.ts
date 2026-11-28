// Supabase Edge Function: cf-pay
// Cashfree வழியா online தவணை: order உருவாக்கும் → Cashfree-இடமே status கேட்டு "PAID"-ஆ இருந்தா மட்டும் தவணை பதியும்.
// Supabase → Edge Functions → Deploy a new function → Via Editor → பெயர்: cf-pay → இதை முழுசா paste → Deploy
// Deploy ஆன பிறகு: function → Settings (Details) → "Verify JWT" / "Enforce JWT verification" → OFF → Save
//   (Cashfree அனுப்பற webhook-ல நம்ம key இருக்காது. பாதுகாப்பு: order உருவாக்க மொபைல் + PIN கட்டாயம்;
//    பதிவு Cashfree server-இடம் நேரடியா சரிபார்த்த பிறகு மட்டும்.)
// Secrets: CASHFREE_APP_ID , CASHFREE_SECRET , CASHFREE_ENV (sandbox / production)
// 2026-11-28: closed accounts (நகை வாங்கியது / பணம் திருப்பி / nominee / நீக்கம்) cannot start a new payment.

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

const SB = Deno.env.get("SUPABASE_URL")!;
const KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const H = { apikey: KEY, Authorization: `Bearer ${KEY}`, "Content-Type": "application/json" };
const ENV = (Deno.env.get("CASHFREE_ENV") || "sandbox").trim().toLowerCase() === "production" ? "production" : "sandbox";
const CF = ENV === "production" ? "https://api.cashfree.com/pg" : "https://sandbox.cashfree.com/pg";
const CFH = () => ({
  "x-client-id": (Deno.env.get("CASHFREE_APP_ID") || "").trim(),
  "x-client-secret": (Deno.env.get("CASHFREE_SECRET") || "").trim(),
  "x-api-version": "2025-01-01",
  "Content-Type": "application/json",
});
const MIN = 1000, MAX = 100000;
const BASE: Record<string, { months: number; fixed: boolean }> = {
  dhana: { months: 11, fixed: false },
  kubera: { months: 11, fixed: true },
};

async function rest(path: string, init: RequestInit = {}) {
  const r = await fetch(`${SB}/rest/v1/${path}`, { ...init, headers: { ...H, ...(init.headers || {}) } });
  return { ok: r.ok, data: await r.json().catch(() => null) };
}
const ymIST = (d: Date) => new Date(d.getTime() + 330 * 60000).toISOString().slice(0, 7);

// Cashfree-இடம் நேரடியா status கேட்டு, PAID-ஆ இருந்தா தவணை பதிய
async function settle(order_id: string) {
  if (!/^STM_[A-Za-z0-9_]{6,40}$/.test(order_id)) return { ok: false, err: "order" };
  const r = await fetch(`${CF}/orders/${encodeURIComponent(order_id)}`, { headers: CFH() });
  const o = await r.json().catch(() => null);
  if (!r.ok || !o) return { ok: false, err: "cf" + r.status };
  if (o.order_status !== "PAID") return { ok: true, paid: false, status: o.order_status };
  const rec = await rest("rpc/gold_pay_record", {
    method: "POST",
    body: JSON.stringify({ p_order: order_id, p_cf_amount: Number(o.order_amount) }),
  });
  if (!rec.ok || !rec.data) return { ok: false, err: "db" };
  return rec.data.ok ? { ok: true, paid: true } : { ok: false, err: rec.data.err };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, err: "method" }, 405);
  try {
    const raw = await req.text();
    let b: any = {};
    try { b = JSON.parse(raw || "{}"); } catch { b = {}; }

    // ---- Cashfree webhook (notify_url): body-ஐ நம்பாம order_id எடுத்து நேரடியா சரிபார்ப்பு ----
    if (!b.action && b?.data?.order?.order_id) {
      const s = await settle(String(b.data.order.order_id));
      return json(s, 200);
    }

    const action = String(b.action || "");

    if (action === "verify") {
      const s = await settle(String(b.order_id || ""));
      return json(s, s.ok ? 200 : 400);
    }

    if (action === "create") {
      const m = String(b.mobile || "").trim(), pin = String(b.pin || "").trim();
      const amount = Math.round(Number(b.amount));
      if (!/^[6-9][0-9]{9}$/.test(m) || !/^[0-9]{4,6}$/.test(pin)) return json({ ok: false, err: "auth" }, 400);
      if (!Number.isFinite(amount) || amount < 100 || amount > MAX) return json({ ok: false, err: "amount" }, 400);
      if (!CFH()["x-client-id"] || !CFH()["x-client-secret"]) return json({ ok: false, err: "no_keys" }, 500);

      // 1) மொபைல் + PIN சரியா (5 தவறு பூட்டு அப்படியே)
      const lg = await rest("rpc/gold_login", { method: "POST", body: JSON.stringify({ p_mobile: m, p_pin: pin }) });
      const d = lg.data;
      if (!lg.ok || !d || d.wrong || d.locked || d.locked_otp || !d.name) return json({ ok: false, err: "auth" }, 401);
      // முடிந்த / நீக்கப்பட்ட கணக்கு → புதிய பணம் இல்லை
      if (d.status && d.status !== "active") return json({ ok: false, err: "closed", status: d.status }, 400);

      // 2) Customer + திட்டம்
      const cs = await rest(`gold_customers?select=id,name,scheme,mobile,monthly_amount,status&mobile=like.*${m}&limit=1`);
      const c = Array.isArray(cs.data) ? cs.data[0] : null;
      if (!c) return json({ ok: false, err: "nocust" }, 400);
      if (c.status && c.status !== "active") return json({ ok: false, err: "closed", status: c.status }, 400);
      let sc = BASE[c.scheme];
      let flex = false; // வெள்ளி திட்டம்: ₹100 முதல், மாசத்துக்கு பல தடவை
      if (!sc) {
        const s = await rest(`gold_schemes?select=months,fixed,name,tagline,tags&key=eq.${encodeURIComponent(c.scheme)}&limit=1`);
        const x = Array.isArray(s.data) ? s.data[0] : null;
        sc = { months: Number(x?.months) || 12, fixed: !!x?.fixed };
        flex = /சில்வர்|வெள்ளி|silver/i.test(`${x?.name || ""} ${x?.tagline || ""} ${x?.tags || ""}`);
      }
      if (amount < (flex ? 100 : MIN)) return json({ ok: false, err: "amount", min: flex ? 100 : MIN }, 400);

      // 3) விதிகள்: தவணை பாக்கி இருக்கணும் · இந்த மாசம் ஏற்கனவே கட்டியிருக்கக் கூடாது · நிலையான திட்டம் = முதல் மாதத் தொகை
      const ps = await rest(`gold_payments?select=amount,paid_on&customer_id=eq.${encodeURIComponent(String(c.id))}&order=paid_on.asc`);
      const pays = Array.isArray(ps.data) ? ps.data : [];
      const now = ymIST(new Date());
      const mset = new Set(pays.map((p: any) => String(p.paid_on || "").slice(0, 7)));
      if (flex) {
        if (mset.size >= sc.months && !mset.has(now)) return json({ ok: false, err: "done" }, 400);
      } else {
        if (pays.length >= sc.months) return json({ ok: false, err: "done" }, 400);
        if (mset.has(now)) return json({ ok: false, err: "paid_month" }, 400);
      }
      if (sc.fixed && pays.length && Math.round(Number(pays[0].amount)) !== amount)
        return json({ ok: false, err: "fixed", amount: Number(pays[0].amount) }, 400);
      // நிலையான திட்டம் · முதல் தவணை: staff approve பண்ணின மாதத் தொகை மட்டும்
      const fm = Math.round(Number(c.monthly_amount) || 0);
      if (sc.fixed && !pays.length && fm > 0 && fm !== amount)
        return json({ ok: false, err: "fixed", amount: fm }, 400);

      // 4) Cashfree order
      const order_id = "STM_" + Date.now().toString(36) + "_" + crypto.randomUUID().replace(/-/g, "").slice(0, 8);
      const ret = String(b.return_url || "");
      const meta: Record<string, string> = { notify_url: `${SB}/functions/v1/cf-pay` };
      if (/^https:\/\/[^\s]{5,200}$/.test(ret)) meta.return_url = ret + (ret.includes("?") ? "&" : "?") + "cfo=" + order_id;

      const ins = await rest("gold_pay_orders", {
        method: "POST",
        body: JSON.stringify({ order_id, customer_id: String(c.id), mobile: m, amount, env: ENV }),
      });
      if (!ins.ok) return json({ ok: false, err: "db" }, 500);

      const r = await fetch(`${CF}/orders`, {
        method: "POST",
        headers: CFH(),
        body: JSON.stringify({
          order_id,
          order_amount: amount,
          order_currency: "INR",
          customer_details: {
            customer_id: ("C" + String(c.id).replace(/[^A-Za-z0-9]/g, "")).slice(0, 50),
            customer_phone: m,
            customer_name: String(c.name || "").slice(0, 100),
          },
          order_meta: meta,
          order_note: "STM தவணை " + (flex ? (mset.has(now) ? mset.size : mset.size + 1) : pays.length + 1) + "/" + sc.months,
        }),
      });
      const o = await r.json().catch(() => null);
      if (!r.ok || !o?.payment_session_id) {
        await rest(`gold_pay_orders?order_id=eq.${order_id}`, { method: "PATCH", body: JSON.stringify({ status: "FAILED" }) });
        return json({ ok: false, err: "cf" + r.status, msg: o?.message || "" }, 502);
      }
      return json({ ok: true, order_id, session: o.payment_session_id, env: ENV, n: flex ? (mset.has(now) ? mset.size : mset.size + 1) : pays.length + 1, of: sc.months });
    }

    return json({ ok: false, err: "action" }, 400);
  } catch (e) {
    return json({ ok: false, err: String((e as Error)?.message || e) }, 500);
  }
});
