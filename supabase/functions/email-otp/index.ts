// Supabase Edge Function: email-otp
// வாடிக்கையாளர் பதிவில் உள்ள email-க்கு 6 இலக்க OTP அனுப்பி, சரிபார்த்து, புது mPIN அமைக்கும்.
// Secrets (Supabase → Edge Functions → Secrets):
//   GMAIL_USER + GMAIL_APP_PASSWORD = (இருந்தால்) Gmail வழியா அனுப்பும் — Google App Password (16 எழுத்து)
//   இல்லையென்றால் Brevo:
//   BREVO_API_KEY = Brevo → SMTP & API → API keys
//   MAIL_FROM     = Brevo-ல verify செய்த sender email (உதா: stmgold2021@gmail.com)
// Code DB-ல hash-ஆ மட்டும் (gold_email_otp, service_role மட்டும்). 10 நிமிடம் செல்லும், 5 தவறு வரை.

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

const TTL_MS = 10 * 60 * 1000, MAX_TRIES = 5;
const PER_MOBILE_DAY = 5, GAP_MS = 60 * 1000, ALL_DAY = 280; // Brevo free ≈ 300/day
const SHOP = "சுப்புலட்சுமி தங்க மாளிகை";

const SB = () => ({ url: Deno.env.get("SUPABASE_URL")!, key: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")! });
async function sbReq(path: string, init: RequestInit = {}) {
  const { url, key } = SB();
  return await fetch(`${url}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: key, Authorization: `Bearer ${key}`, "Content-Type": "application/json", ...(init.headers || {}) },
  });
}
async function rpc(fn: string, args: Record<string, unknown>) {
  const r = await sbReq(`rpc/${fn}`, { method: "POST", body: JSON.stringify(args) });
  return { ok: r.ok, data: await r.json().catch(() => null) };
}

async function hashCode(mobile: string, code: string) {
  const k = await crypto.subtle.importKey("raw", new TextEncoder().encode(SB().key), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(`email-otp:${mobile}:${code}`));
  return Array.from(new Uint8Array(sig)).map((b) => b.toString(16).padStart(2, "0")).join("");
}
function sixDigits() {
  const a = new Uint32Array(1);
  crypto.getRandomValues(a);
  return String(a[0] % 1000000).padStart(6, "0");
}
function mask(e: string) {
  const [u, d] = e.split("@");
  return (u.length <= 2 ? u[0] + "•" : u.slice(0, 2) + "•".repeat(Math.min(6, u.length - 2))) + "@" + d;
}

// வரம்பு கணக்கு இந்திய நேரப்படி இன்று நள்ளிரவு 12 முதல் (மறுநாள் 12 மணிக்கு reset).
function istMidnight() {
  const IST = 5.5 * 3600 * 1000;
  const d = new Date(Date.now() + IST);
  d.setUTCHours(0, 0, 0, 0);
  return new Date(d.getTime() - IST).toISOString();
}
async function rateOk(m: string): Promise<string | null> {
  const since = istMidnight();
  const r = await sbReq(`gold_otp_log?select=sent_at&mobile=eq.${m}&sent_at=gte.${since}&order=sent_at.desc&limit=10`);
  if (!r.ok) return "rate_db";
  const rows = await r.json().catch(() => []);
  if (rows.length && Date.now() - new Date(rows[0].sent_at).getTime() < GAP_MS) return "wait";
  if (rows.length >= PER_MOBILE_DAY) return "too_many";
  const a = await sbReq(`gold_otp_log?select=mobile&sent_at=gte.${since}&limit=1`, { headers: { Prefer: "count=exact" } });
  const total = Number((a.headers.get("content-range") || "").split("/")[1] || 0);
  if (total >= ALL_DAY) return "too_many";
  await sbReq("gold_otp_log", { method: "POST", body: JSON.stringify({ mobile: m }) });
  return null;
}

const mailReady = () =>
  !!(Deno.env.get("GMAIL_USER") && Deno.env.get("GMAIL_APP_PASSWORD")) || !!(Deno.env.get("BREVO_API_KEY") && Deno.env.get("MAIL_FROM"));

// Gmail SMTP (465, TLS) — சின்ன நேரடி client; தமிழ் subject/body சரியா encode ஆகும் (base64).
const enc = new TextEncoder(), dec = new TextDecoder();
const b64 = (s: string) => {
  const b = enc.encode(s);
  let r = "";
  for (let i = 0; i < b.length; i += 0x8000) r += String.fromCharCode(...b.subarray(i, i + 0x8000));
  return btoa(r);
};
const wrap76 = (s: string) => s.replace(/.{1,76}/g, "$&\r\n");
function encWord(s: string) {
  // RFC 2047: ஒவ்வொரு encoded-word-ம் 75 எழுத்துக்குள்; UTF-8 எழுத்தை நடுவில் உடைக்காம.
  const parts: string[] = [];
  let cur = "";
  for (const ch of s) {
    if (enc.encode(cur + ch).length > 39) { parts.push(cur); cur = ch; } else cur += ch;
  }
  if (cur) parts.push(cur);
  return parts.map((p) => `=?UTF-8?B?${b64(p)}?=`).join("\r\n ");
}

async function gmailSend(to: string, _name: string, subject: string, html: string, text: string) {
  const user = Deno.env.get("GMAIL_USER")!.trim(), pass = Deno.env.get("GMAIL_APP_PASSWORD")!.replace(/\s/g, "");
  const conn = await Deno.connectTls({ hostname: "smtp.gmail.com", port: 465 });
  let buf = "";
  const read = async (): Promise<string> => {
    const chunk = new Uint8Array(4096);
    while (true) {
      const lines = buf.split("\r\n");
      for (let k = 0; k < lines.length - 1; k++) {
        if (/^\d{3} /.test(lines[k])) {
          const out = lines.slice(0, k + 1).join("\n");
          buf = lines.slice(k + 1).join("\r\n");
          return out;
        }
      }
      const n = await conn.read(chunk);
      if (n === null) throw new Error("closed");
      buf += dec.decode(chunk.subarray(0, n));
    }
  };
  const cmd = async (line: string | null, want: string) => {
    if (line !== null) await conn.write(enc.encode(line + "\r\n"));
    const r = await read();
    if (!r.split("\n").pop()!.startsWith(want)) throw new Error(r.slice(0, 160));
    return r;
  };
  try {
    await cmd(null, "220");
    await cmd("EHLO stmgold", "250");
    await cmd("AUTH LOGIN", "334");
    await cmd(b64(user), "334");
    await cmd(b64(pass), "235");
    await cmd(`MAIL FROM:<${user}>`, "250");
    await cmd(`RCPT TO:<${to}>`, "250");
    await cmd("DATA", "354");
    const bnd = "stm" + crypto.randomUUID().replace(/-/g, "");
    const msg = [
      `From: ${encWord("Subbulakshmi Thanga Maligai")} <${user}>`,
      `To: <${to}>`,
      `Subject: ${encWord(subject)}`,
      `Date: ${new Date().toUTCString()}`,
      `Message-ID: <${crypto.randomUUID()}@stmgold.otp>`,
      "MIME-Version: 1.0",
      `Content-Type: multipart/alternative; boundary="${bnd}"`,
      "",
      `--${bnd}`,
      'Content-Type: text/plain; charset="UTF-8"',
      "Content-Transfer-Encoding: base64",
      "",
      wrap76(b64(text)),
      `--${bnd}`,
      'Content-Type: text/html; charset="UTF-8"',
      "Content-Transfer-Encoding: base64",
      "",
      wrap76(b64(html)),
      `--${bnd}--`,
      ".",
    ].join("\r\n");
    await cmd(msg, "250");
    await conn.write(enc.encode("QUIT\r\n")).catch(() => {});
  } catch (e) {
    const m = String((e as Error)?.message || e).toLowerCase();
    console.log("gmail", m.slice(0, 200));
    throw new Error(/^535|username and password|badcredentials/.test(m) ? "mail:gmail_login" : "mail:gmail");
  } finally {
    try { conn.close(); } catch (_) { /* ignore */ }
  }
}

async function sendMail(to: string, name: string, code: string) {
  const key = Deno.env.get("BREVO_API_KEY"), from = Deno.env.get("MAIL_FROM");
  const useGmail = !!(Deno.env.get("GMAIL_USER") && Deno.env.get("GMAIL_APP_PASSWORD"));
  if (!useGmail && (!key || !from)) throw new Error("not_ready");
  const html = `<!doctype html><html><body style="margin:0;background:#FAF7EF;font-family:Arial,sans-serif;color:#392027">
<div style="max-width:440px;margin:0 auto;padding:24px 16px">
<div style="background:#4A0D18;color:#F1E4D0;border-radius:16px 16px 0 0;padding:18px 20px;font-size:18px;font-weight:bold">${SHOP}</div>
<div style="background:#fff;border:1px solid #E8D9B9;border-top:0;border-radius:0 0 16px 16px;padding:22px 20px">
<p style="margin:0 0 12px;font-size:15px">Your OTP code is <b>${code}</b></p>
<p style="margin:0 0 10px">வணக்கம் ${name},</p>
<p style="margin:0 0 16px;line-height:1.6">உங்கள் தங்க சேமிப்பு App-ல் mPIN அமைக்க இந்த OTP-ஐ போடுங்கள்:</p>
<div style="font-size:32px;letter-spacing:8px;font-weight:bold;color:#6E1423;text-align:center;background:#F5F0E5;border-radius:12px;padding:14px 0">${code}</div>
<p style="margin:16px 0 0;font-size:13px;color:#81747A;line-height:1.6">இந்த OTP 10 நிமிடம் மட்டும் செல்லும். இதை யாரிடமும் (கடை ஊழியர் உட்பட) பகிர வேண்டாம். நீங்கள் கேட்கவில்லை என்றால் இந்த email-ஐ விட்டுவிடுங்கள்.</p>
</div></div></body></html>`;
  const subject = `${code} is your OTP – ${SHOP}`;
  const text = `Your OTP code is ${code}\n\nவணக்கம் ${name}, உங்கள் OTP: ${code} (10 நிமிடம் செல்லும்). யாரிடமும் பகிர வேண்டாம். – ${SHOP}`;
  if (useGmail) return await gmailSend(to, name, subject, html, text);
  if (key!.trim().startsWith("xsmtpsib")) throw new Error("mail:smtp_key"); // SMTP key ≠ API key
  if (!key!.trim().startsWith("xkeysib")) throw new Error("mail:key_format");
  const r = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: { "api-key": key!.trim(), "Content-Type": "application/json", accept: "application/json" },
    body: JSON.stringify({
      sender: { name: "Subbulakshmi Thanga Maligai", email: from!.trim() },
      to: [{ email: to, name }],
      subject,
      htmlContent: html,
      textContent: text,
    }),
  });
  if (!r.ok) {
    const t = (await r.text().catch(() => "")).toLowerCase();
    const why = /ip address|unrecogni[sz]ed ip|authorised ip|authorized ip/.test(t) ? "ip"
      : /sender|from/.test(t) ? "sender"
      : /key not found|api key|unauthori[sz]ed|invalid key/.test(t) ? "key"
      : /credit|plan|suspend|blocked/.test(t) ? "account" : "other";
    console.log("brevo", r.status, t.slice(0, 200));
    throw new Error(`mail:${r.status}:${why}`);
  }
}

// code சரியா? (consume=true ஆனா பயன்படுத்திய பின் அழிக்கும்)
async function check(m: string, code: string, consume: boolean): Promise<string | null> {
  const r = await sbReq(`gold_email_otp?select=code_hash,expires_at,tries&mobile=eq.${m}&limit=1`);
  const rows = r.ok ? await r.json().catch(() => []) : [];
  const row = rows[0];
  if (!row) return "expired";
  if (new Date(row.expires_at).getTime() < Date.now()) return "expired";
  if (row.tries >= MAX_TRIES) return "code_max_attempts_exceeded";
  if ((await hashCode(m, code)) !== row.code_hash) {
    await sbReq(`gold_email_otp?mobile=eq.${m}`, { method: "PATCH", body: JSON.stringify({ tries: row.tries + 1 }) });
    return row.tries + 1 >= MAX_TRIES ? "code_max_attempts_exceeded" : "code_invalid";
  }
  if (consume) await sbReq(`gold_email_otp?mobile=eq.${m}`, { method: "DELETE" });
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, err: "method" }, 405);
  try {
    const b = await req.json();
    const action = String(b.action || "");
    const m = String(b.mobile || "").trim();
    if (!/^[6-9][0-9]{9}$/.test(m)) return json({ ok: false, err: "mobile" }, 400);

    if (action === "send") {
      const c = await sbReq(`gold_customers?select=name,email&mobile=eq.${m}&limit=1`);
      const rows = c.ok ? await c.json().catch(() => []) : [];
      if (!rows.length) return json({ ok: false, err: "nomatch" }, 400);
      const email = String(rows[0].email || "").trim().toLowerCase();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return json({ ok: false, err: "noemail" }, 400);
      if (!mailReady()) return json({ ok: false, err: "not_ready" }, 503);
      const lim = await rateOk(m);
      if (lim) return json({ ok: false, err: lim }, 429);
      const code = sixDigits();
      const up = await sbReq("gold_email_otp", {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates" },
        body: JSON.stringify({ mobile: m, code_hash: await hashCode(m, code), expires_at: new Date(Date.now() + TTL_MS).toISOString(), tries: 0, created_at: new Date().toISOString() }),
      });
      if (!up.ok) return json({ ok: false, err: "db" }, 500);
      try {
        await sendMail(email, String(rows[0].name || ""), code);
      } catch (e) {
        await sbReq(`gold_email_otp?mobile=eq.${m}`, { method: "DELETE" });
        return json({ ok: false, err: String((e as Error).message) }, 502);
      }
      return json({ ok: true, to: mask(email) });
    }

    const code = String(b.code || "");
    if (!/^[0-9]{6}$/.test(code)) return json({ ok: false, err: "code_invalid" }, 400);

    if (action === "check") {
      const e = await check(m, code, false);
      return json({ ok: !e, err: e ?? undefined }, e ? 400 : 200);
    }

    if (action === "set") {
      const pin = String(b.pin || "");
      if (!/^[0-9]{6}$/.test(pin)) return json({ ok: false, err: "pin" }, 400);
      const e = await check(m, code, true);
      if (e) return json({ ok: false, err: e }, 400);
      const r = await rpc("gold_otp_set_pin", { p_mobile: m, p_pin: pin });
      if (!r.ok || !r.data) return json({ ok: false, err: "db" }, 500);
      return json(r.data, r.data.ok ? 200 : 400);
    }

    return json({ ok: false, err: "action" }, 400);
  } catch (e) {
    return json({ ok: false, err: String((e as Error)?.message || e) }, 500);
  }
});
