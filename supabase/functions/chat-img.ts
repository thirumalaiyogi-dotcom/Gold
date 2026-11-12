// Supabase Edge Function: chat-img
// Customer chat photos: upload (PIN-checked) into the PRIVATE "chat" bucket, and short-lived signed links to view them.
// Staff read the same files directly from the staff panel (storage policy: is_gold_staff()).
// No secrets needed (uses the project's service role inside the function).

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

const SB = Deno.env.get("SUPABASE_URL")!;
const KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const H = { apikey: KEY, Authorization: `Bearer ${KEY}` };
const MAX = 2 * 1024 * 1024, PER_DAY = 10;

async function rest(path: string, init: RequestInit = {}) {
  const r = await fetch(`${SB}/rest/v1/${path}`, { ...init, headers: { ...H, "Content-Type": "application/json", ...(init.headers || {}) } });
  return { ok: r.ok, data: await r.json().catch(() => null) };
}

// mobile + mPIN → customer id (same check as gold_chat_get / gold_chat_send)
async function customer(m: string, pin: string): Promise<string | null> {
  if (!/^[6-9][0-9]{9}$/.test(m) || !/^[0-9]{4,6}$/.test(pin)) return null;
  const lg = await rest("rpc/gold_login", { method: "POST", body: JSON.stringify({ p_mobile: m, p_pin: pin }) });
  const d = lg.data;
  if (!lg.ok || !d || !d.name || d.wrong || d.locked || d.locked_otp) return null;
  const c = await rest(`gold_customers?select=id&mobile=eq.${m}&limit=1`);
  return Array.isArray(c.data) && c.data[0] ? String(c.data[0].id) : null;
}

function kind(b: Uint8Array): string | null {
  if (b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff) return "image/jpeg";
  if (b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return "image/png";
  if (b[0] === 0x52 && b[1] === 0x49 && b[2] === 0x46 && b[3] === 0x46 && b[8] === 0x57 && b[9] === 0x45) return "image/webp";
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, err: "method" }, 405);
  try {
    const b = await req.json().catch(() => ({}));
    const cid = await customer(String(b.mobile || "").trim(), String(b.pin || "").trim());
    if (!cid) return json({ ok: false, err: "auth" }, 401);

    if (b.action === "upload") {
      const raw = String(b.data || "").replace(/^data:[^,]+,/, "");
      if (raw.length < 100 || raw.length > MAX * 1.4) return json({ ok: false, err: "size" }, 400);
      let bytes: Uint8Array;
      try { bytes = Uint8Array.from(atob(raw), (c) => c.charCodeAt(0)); } catch { return json({ ok: false, err: "data" }, 400); }
      const type = kind(bytes);
      if (!type || bytes.length > MAX) return json({ ok: false, err: "type" }, 400);
      const since = new Date(Date.now() - 864e5).toISOString();
      const n = await rest(`gold_chat?select=id&customer_id=eq.${cid}&sender=eq.c&image=not.is.null&created_at=gte.${since}`);
      if (Array.isArray(n.data) && n.data.length >= PER_DAY) return json({ ok: false, err: "too_many" }, 429);
      const path = `${cid}/${Date.now()}-${crypto.randomUUID().slice(0, 8)}.${type.split("/")[1].replace("jpeg", "jpg")}`;
      const up = await fetch(`${SB}/storage/v1/object/chat/${path}`, { method: "POST", headers: { ...H, "Content-Type": type, "x-upsert": "false" }, body: bytes });
      if (!up.ok) return json({ ok: false, err: "store" }, 500);
      const caption = String(b.caption || "").trim().slice(0, 500) || "📷 படம்";
      const ins = await rest("gold_chat", {
        method: "POST",
        headers: { Prefer: "return=representation" },
        body: JSON.stringify({ customer_id: cid, sender: "c", body: caption, image: path }),
      });
      if (!ins.ok) return json({ ok: false, err: "db" }, 500);
      return json({ ok: true, id: Array.isArray(ins.data) && ins.data[0] ? ins.data[0].id : null });
    }

    // signed view links (1 hour) — only for this customer's own files
    if (b.action === "sign") {
      const paths = (Array.isArray(b.paths) ? b.paths : []).map(String).filter((p: string) => p.startsWith(cid + "/") && /^[0-9a-f-]{36}\/[\w.-]{5,80}$/i.test(p)).slice(0, 50);
      if (!paths.length) return json({ ok: true, urls: {} });
      const r = await fetch(`${SB}/storage/v1/object/sign/chat`, {
        method: "POST",
        headers: { ...H, "Content-Type": "application/json" },
        body: JSON.stringify({ expiresIn: 3600, paths }),
      });
      const arr = await r.json().catch(() => []);
      const urls: Record<string, string> = {};
      (Array.isArray(arr) ? arr : []).forEach((x: any) => { if (x?.path && x?.signedURL) urls[x.path] = `${SB}/storage/v1${x.signedURL}`; });
      return json({ ok: true, urls });
    }

    return json({ ok: false, err: "action" }, 400);
  } catch (e) {
    return json({ ok: false, err: String((e as Error)?.message || e) }, 500);
  }
});
