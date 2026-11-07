// Supabase Edge Function: push
// படத்தோட Push Notification: customer app பதிவு (sub) + staff அனுப்புதல் (send)
// Supabase → Edge Functions → Deploy a new function → Via Editor → பெயர்: push → இதை முழுசா paste → Deploy
// Secrets எதுவும் தேவையில்ல — அனுப்பும் key-ஐ function முதல் தடவை தானே உருவாக்கி gold_push_cfg-ல வைக்கும்.
// "Verify JWT" ON-ஆவே இருக்கட்டும்.
// v4: Native app (Android) phone-களுக்கு Firebase (FCM) வழியா அனுப்புதல்.
//     FCM token-கள் அதே gold_push_subs table-ல endpoint = "fcm:<token>" ஆ சேமிக்கப்படும் (புது table இல்ல).
//     FCM அனுப்ப secret: FCM_SERVICE_ACCOUNT = Firebase service account JSON (முழுசா). இல்லைன்னா FCM phone-கள் தவிர்க்கப்படும்.
import webpush from "npm:web-push@3.6.7";

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
const SUBJECT = "mailto:noreply@subbulakshmi-gold.app";
// Push சேவைகள் மட்டும் (வேற எந்த URL-க்கும் இந்த function request அனுப்பாது)
const PUSH_HOSTS = [/\.googleapis\.com$/, /\.mozilla\.com$/, /\.push\.apple\.com$/, /\.notify\.windows\.com$/];

async function rest(path: string, init: RequestInit = {}) {
  const r = await fetch(`${SB}/rest/v1/${path}`, { ...init, headers: { ...H, ...(init.headers || {}) } });
  return { ok: r.ok, status: r.status, data: await r.json().catch(() => null) };
}

let VAPID: { pub: string; priv: string } | null = null;
async function vapid() {
  if (VAPID) return VAPID;
  const g = await rest("gold_push_cfg?select=vapid_public,vapid_private&id=eq.1");
  let row = Array.isArray(g.data) ? g.data[0] : null;
  if (!row) {
    const k = webpush.generateVAPIDKeys();
    await rest("gold_push_cfg", {
      method: "POST",
      headers: { Prefer: "resolution=ignore-duplicates" },
      body: JSON.stringify({ id: 1, vapid_public: k.publicKey, vapid_private: k.privateKey }),
    });
    const g2 = await rest("gold_push_cfg?select=vapid_public,vapid_private&id=eq.1");
    row = Array.isArray(g2.data) ? g2.data[0] : null;
    if (!row) throw new Error("cfg");
  }
  VAPID = { pub: row.vapid_public, priv: row.vapid_private };
  webpush.setVapidDetails(SUBJECT, VAPID.pub, VAPID.priv);
  return VAPID;
}

// Staff தானா? (login token → email → gold_staff)
async function staffEmail(req: Request): Promise<string | null> {
  const tok = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!tok || tok.split(".").length !== 3) return null;
  const u = await fetch(`${SB}/auth/v1/user`, { headers: { apikey: KEY, Authorization: `Bearer ${tok}` } });
  if (!u.ok) return null;
  const email = String((await u.json().catch(() => ({})))?.email || "").toLowerCase();
  if (!email) return null;
  const s = await rest(`gold_staff?select=email&email=eq.${encodeURIComponent(email)}`);
  return Array.isArray(s.data) && s.data.length ? email : null;
}

const okEndpoint = (e: string) => {
  try {
    const u = new URL(e);
    return u.protocol === "https:" && PUSH_HOSTS.some((r) => r.test(u.hostname));
  } catch { return false; }
};
const clip = (s: unknown, n: number) => String(s ?? "").trim().slice(0, n);
const ymIST = () => new Date(Date.now() + 330 * 60000).toISOString().slice(0, 7);


// ---------- FCM (native app) ----------
let SA: any = undefined;
function fcmSA() {
  if (SA !== undefined) return SA;
  try { SA = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") || ""); } catch { SA = null; }
  if (!SA?.private_key || !SA?.client_email || !SA?.project_id) SA = null;
  return SA;
}
const b64u = (u: Uint8Array) => btoa(String.fromCharCode(...u)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const b64uStr = (s: string) => b64u(new TextEncoder().encode(s));
let FCM_TOK: { t: string; exp: number } | null = null;
async function fcmAccess(): Promise<string> {
  const s = fcmSA();
  if (!s) throw new Error("no_fcm");
  if (FCM_TOK && FCM_TOK.exp > Date.now() + 60_000) return FCM_TOK.t;
  const now = Math.floor(Date.now() / 1000);
  const head = b64uStr(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64uStr(JSON.stringify({ iss: s.client_email, scope: "https://www.googleapis.com/auth/firebase.messaging", aud: "https://oauth2.googleapis.com/token", iat: now, exp: now + 3600 }));
  const pem = String(s.private_key).replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(head + "." + claim)));
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: "grant_type=" + encodeURIComponent("urn:ietf:params:oauth:grant-type:jwt-bearer") + "&assertion=" + head + "." + claim + "." + b64u(sig),
  });
  const o = await r.json().catch(() => ({}));
  if (!o.access_token) throw new Error("fcm_auth");
  FCM_TOK = { t: o.access_token, exp: Date.now() + (Number(o.expires_in) || 3600) * 1000 };
  return FCM_TOK.t;
}
async function sendFcm(token: string, payload: string) {
  const p = JSON.parse(payload);
  const due = String(p.tag || "").startsWith("due");
  const notification: Record<string, string> = { title: clip(p.title, 80), body: clip(p.body, 240) };
  if (p.image) notification.image = p.image;
  const r = await fetch(`https://fcm.googleapis.com/v1/projects/${fcmSA().project_id}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${await fcmAccess()}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        token,
        notification,
        data: { url: String(p.url || "/"), tag: String(p.tag || "") },
        android: {
          priority: "high",
          ttl: "86400s",
          notification: { channel_id: due ? "stm_due" : "stm_notice", icon: "ic_stat_stm", color: "#6E1423", notification_count: 1 },
        },
      },
    }),
  });
  if (!r.ok) {
    const t = await r.text().catch(() => "");
    const gone = r.status === 404 || /UNREGISTERED|registration token is not a valid/i.test(t);
    throw { statusCode: gone ? 410 : r.status };
  }
}
const isFcm = (s: any) => String(s.endpoint || "").startsWith("fcm:");

// ஒவ்வொரு phone-க்கும் அனுப்பு; போகாத / நீக்கப்பட்ட subscription-களை சுத்தம் செய்
async function deliver(subs: any[], payloadFor: (s: any) => string) {
  let sent = 0, failed = 0;
  if (!fcmSA()) subs = subs.filter((s) => !isFcm(s)); // FCM secret இல்லைன்னா native phone-களை தொடாதே
  for (let i = 0; i < subs.length; i += 25) {
    await Promise.all(subs.slice(i, i + 25).map(async (s) => {
      try {
        if (isFcm(s)) await sendFcm(String(s.endpoint).slice(4), payloadFor(s));
        else await webpush.sendNotification({ endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } }, payloadFor(s), { TTL: 86400, urgency: "normal" });
        sent++;
        await rest(`gold_push_subs?endpoint=eq.${encodeURIComponent(s.endpoint)}`, {
          method: "PATCH", body: JSON.stringify({ last_ok: new Date().toISOString(), fails: 0 }),
        });
      } catch (e: any) {
        failed++;
        const code = e?.statusCode || 0;
        const gone = code === 404 || code === 410 || (s.fails || 0) >= 4;
        await rest(`gold_push_subs?endpoint=eq.${encodeURIComponent(s.endpoint)}`, gone
          ? { method: "DELETE" }
          : { method: "PATCH", body: JSON.stringify({ fails: (s.fails || 0) + 1 }) });
      }
    }));
  }
  return { sent, failed };
}

const MONTHS: Record<string, number> = { dhana: 11, kubera: 11 };
// தானியங்கி: 1-ம் / 5-ம் தேதி தவணை நினைவூட்டல், தினமும் பிறந்தநாள் / திருமண நாள் வாழ்த்து
async function cronRun(kind: string) {
  const sr = await rest("gold_push_subs?select=endpoint,p256dh,auth,customer_id,fails&customer_id=not.is.null");
  const subs: any[] = Array.isArray(sr.data) ? sr.data : [];
  if (!subs.length) return { sent: 0, failed: 0, total: 0 };
  const ids = [...new Set(subs.map((s) => String(s.customer_id)))];
  const cr = await rest(`gold_customers?select=id,name,scheme,dob,anniv&id=in.(${ids.map(encodeURIComponent).join(",")})`);
  const cust = new Map((Array.isArray(cr.data) ? cr.data : []).map((c: any) => [String(c.id), c]));
  const today = new Date(Date.now() + 330 * 60000).toISOString().slice(0, 10), md = today.slice(5), ym = today.slice(0, 7);
  const msgs = new Map<string, { title: string; body: string; url: string }>();

  if (kind === "due1" || kind === "due5") {
    const sch = await rest("gold_schemes?select=key,months");
    (Array.isArray(sch.data) ? sch.data : []).forEach((x: any) => { if (x.months) MONTHS[x.key] = Number(x.months); });
    const pr = await rest(`gold_payments?select=customer_id,paid_on&customer_id=in.(${ids.map(encodeURIComponent).join(",")})`);
    const pays = Array.isArray(pr.data) ? pr.data : [];
    for (const [id, c] of cust) {
      const mine = pays.filter((p: any) => String(p.customer_id) === id);
      const mo = MONTHS[c.scheme] || 12;
      if (mine.length >= mo) continue;                                                     // திட்டம் முடிஞ்சது
      const paidNow = mine.some((p: any) => new Date(new Date(p.paid_on).getTime() + 330 * 60000).toISOString().slice(0, 7) === ym);
      if (paidNow) continue;                                                              // இந்த மாசம் கட்டியாச்சு
      const n = mine.length + 1, nm = String(c.name || "").split(" ")[0];
      msgs.set(id, kind === "due1"
        ? { title: "தவணை நினைவூட்டல் 🔔", body: `${nm}, இந்த மாத தவணை (${n}/${mo}) கட்ட நேரம் வந்தாச்சு. 7-ம் தேதிக்குள் கடையிலோ app-லயோ கட்டுங்க.`, url: "/#p" }
        : { title: "தவணை நினைவூட்டல்", body: `${nm}, இந்த மாத தவணை (${n}/${mo}) இன்னும் கட்டல. 7-ம் தேதிக்குள் கட்டுங்க. ஏற்கனவே கட்டியிருந்தா இதை கவனிக்க வேண்டாம்.`, url: "/#p" });
    }
  } else if (kind === "greet") {
    for (const [id, c] of cust) {
      const nm = String(c.name || "").split(" ")[0];
      if (c.dob && String(c.dob).slice(5, 10) === md)
        msgs.set(id, { title: `பிறந்தநாள் வாழ்த்துகள் ${nm}! 🎂`, body: "இனிய பிறந்தநாள் வாழ்த்துகள். எல்லா வளமும் நலமும் பெற்று வாழ்க! — சுப்புலட்சுமி தங்க மாளிகை", url: "/" });
      else if (c.anniv && String(c.anniv).slice(5, 10) === md)
        msgs.set(id, { title: `திருமண நாள் வாழ்த்துகள் ${nm}! 💐`, body: "இனிய திருமண நாள் வாழ்த்துகள். என்றும் மகிழ்ச்சியா வாழ்க! — சுப்புலட்சுமி தங்க மாளிகை", url: "/" });
    }
  } else return { sent: 0, failed: 0, total: 0, err: "kind" };

  const target = subs.filter((s) => msgs.has(String(s.customer_id)));
  if (!target.length) return { sent: 0, failed: 0, total: 0 };
  await vapid();
  const r = await deliver(target, (s) => JSON.stringify({ ...msgs.get(String(s.customer_id))!, tag: kind }));
  const first = msgs.values().next().value!;
  await rest("gold_push_log", {
    method: "POST",
    body: JSON.stringify({ title: kind === "greet" ? "வாழ்த்து (தானியங்கி)" : first.title + " (தானியங்கி)", body: `${msgs.size} customer`, url: first.url, target: "auto:" + kind, sent: r.sent, failed: r.failed, by_email: "auto" }),
  });
  return { ...r, total: target.length };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, err: "method" }, 405);
  try {
    const b = await req.json().catch(() => ({}));
    const action = String(b.action || "");

    if (action === "key") return json({ ok: true, key: (await vapid()).pub });

    if (action === "sub") {
      const s = b.sub || {};
      const endpoint = String(s.endpoint || ""), p256dh = String(s.keys?.p256dh || ""), auth = String(s.keys?.auth || "");
      if (!okEndpoint(endpoint) || endpoint.length > 1000 || !/^[A-Za-z0-9_-]{40,200}$/.test(p256dh) || !/^[A-Za-z0-9_-]{8,60}$/.test(auth))
        return json({ ok: false, err: "sub" }, 400);
      let customer_id: string | null = null;
      const m = String(b.mobile || "").trim(), pin = String(b.pin || "").trim();
      if (/^[6-9][0-9]{9}$/.test(m) && /^[0-9]{4,6}$/.test(pin)) {
        const lg = await rest("rpc/gold_login", { method: "POST", body: JSON.stringify({ p_mobile: m, p_pin: pin }) });
        const d = lg.data;
        if (lg.ok && d && d.name && !d.wrong && !d.locked && !d.locked_otp) {
          const c = await rest(`gold_customers?select=id&mobile=like.*${m}&limit=1`);
          if (Array.isArray(c.data) && c.data[0]) customer_id = String(c.data[0].id);
        }
      }
      const row: Record<string, unknown> = { endpoint, p256dh, auth, fails: 0 };
      if (customer_id) row.customer_id = customer_id;
      const r = await rest("gold_push_subs", {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates" },
        body: JSON.stringify(row),
      });
      return json({ ok: r.ok, linked: !!customer_id }, r.ok ? 200 : 500);
    }

    // Native app: FCM token பதிவு (mobile + mPIN சரியா இருந்தா customer-ஓட இணைக்கும் — web "sub" மாதிரியே)
    if (action === "fcm_sub") {
      const token = String(b.token || "");
      if (!/^[A-Za-z0-9_:.-]{100,4096}$/.test(token)) return json({ ok: false, err: "token" }, 400);
      let customer_id: string | null = null;
      const m = String(b.mobile || "").trim(), pin = String(b.pin || "").trim();
      if (/^[6-9][0-9]{9}$/.test(m) && /^[0-9]{4,6}$/.test(pin)) {
        const lg = await rest("rpc/gold_login", { method: "POST", body: JSON.stringify({ p_mobile: m, p_pin: pin }) });
        const d = lg.data;
        if (lg.ok && d && d.name && !d.wrong && !d.locked && !d.locked_otp) {
          const c = await rest(`gold_customers?select=id&mobile=like.*${m}&limit=1`);
          if (Array.isArray(c.data) && c.data[0]) customer_id = String(c.data[0].id);
        }
      }
      const row: Record<string, unknown> = { endpoint: "fcm:" + token, p256dh: "fcm", auth: "fcm", fails: 0 };
      if (customer_id) row.customer_id = customer_id;
      const r = await rest("gold_push_subs", { method: "POST", headers: { Prefer: "resolution=merge-duplicates" }, body: JSON.stringify(row) });
      return json({ ok: r.ok, linked: !!customer_id, fcm: !!fcmSA() }, r.ok ? 200 : 500);
    }

    if (action === "unsub") {
      const endpoint = String(b.endpoint || "");
      if (okEndpoint(endpoint) || /^fcm:[A-Za-z0-9_:.-]{100,4096}$/.test(endpoint)) await rest(`gold_push_subs?endpoint=eq.${encodeURIComponent(endpoint)}`, { method: "DELETE" });
      return json({ ok: true });
    }

    if (action === "cron") {
      const t = String(b.token || "");
      const cfg = await rest("gold_cron_cfg?select=token&id=eq.1");
      const real = Array.isArray(cfg.data) && cfg.data[0] ? String(cfg.data[0].token) : "";
      if (!real || t.length !== real.length || t !== real) return json({ ok: false, err: "token" }, 401);
      return json({ ok: true, ...(await cronRun(String(b.kind || ""))) });
    }

    if (action === "count" || action === "send") {
      const email = await staffEmail(req);
      if (!email) return json({ ok: false, err: "staff" }, 401);
      const target = ["all", "customers", "due"].includes(b.target) ? b.target : "all";

      const sr = await rest("gold_push_subs?select=endpoint,p256dh,auth,customer_id,fails");
      let subs: any[] = Array.isArray(sr.data) ? sr.data : [];
      if (target !== "all") subs = subs.filter((s) => s.customer_id);
      if (target === "due") {
        const since = ymIST() + "-01";
        const pr = await rest(`gold_payments?select=customer_id&paid_on=gte.${since}`);
        const paid = new Set((Array.isArray(pr.data) ? pr.data : []).map((p: any) => String(p.customer_id)));
        subs = subs.filter((s) => !paid.has(String(s.customer_id)));
      }
      if (action === "count") return json({ ok: true, count: subs.length });

      const title = clip(b.title, 80);
      if (!title) return json({ ok: false, err: "title" }, 400);
      const body = clip(b.body, 240);
      const image = /^https:\/\/\S{5,600}$/.test(String(b.image || "")) ? String(b.image) : "";
      const url = ["/", "/#p", "/#scx", "/#e", "/#n"].includes(b.url) ? b.url : "/";
      const payload = JSON.stringify({ title, body, image, url });

      await vapid();
      const { sent, failed } = await deliver(subs, () => payload);
      await rest("gold_push_log", {
        method: "POST",
        body: JSON.stringify({ title, body, image: image || null, url, target, sent, failed, by_email: email }),
      });
      return json({ ok: true, sent, failed, total: subs.length });
    }

    return json({ ok: false, err: "action" }, 400);
  } catch (e) {
    return json({ ok: false, err: String((e as Error)?.message || e) }, 500);
  }
});
