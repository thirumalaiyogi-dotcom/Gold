// Supabase Edge Function: staff-admin
// Staff (ஊழியர்) நிர்வாகம் — Owner (super_admin) மட்டும்: பட்டியல், சேர்க்க, role மாற்ற, நிறுத்த / மீண்டும் தொடங்க, password மாற்ற.
// Login = Supabase Auth (email + password). புது staff-க்கு auth user இங்கேயே உருவாகும் (service role, server-side மட்டும்).
// "Verify JWT" ON. Secrets தேவையில்ல (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY தானா இருக்கும்).

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

const SB = Deno.env.get("SUPABASE_URL")!;
const KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const H = { apikey: KEY, Authorization: `Bearer ${KEY}`, "Content-Type": "application/json" };
const ROLES = ["super_admin", "admin", "manager", "accounts", "support"];

async function rest(path: string, init: RequestInit = {}) {
  const r = await fetch(`${SB}/rest/v1/${path}`, { ...init, headers: { ...H, ...(init.headers || {}) } });
  return { ok: r.ok, status: r.status, data: await r.json().catch(() => null) };
}
async function authAdmin(path: string, init: RequestInit = {}) {
  const r = await fetch(`${SB}/auth/v1/admin/${path}`, { ...init, headers: { ...H, ...(init.headers || {}) } });
  return { ok: r.ok, status: r.status, data: await r.json().catch(() => null) };
}

// caller = active super_admin?
async function owner(req: Request): Promise<string | null> {
  const tok = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!tok || tok.split(".").length !== 3) return null;
  const u = await fetch(`${SB}/auth/v1/user`, { headers: { apikey: KEY, Authorization: `Bearer ${tok}` } });
  if (!u.ok) return null;
  const email = String((await u.json().catch(() => ({})))?.email || "").toLowerCase();
  if (!email) return null;
  const s = await rest(`gold_staff?select=email,role,active&email=eq.${encodeURIComponent(email)}`);
  const me = Array.isArray(s.data) ? s.data[0] : null;
  return me && me.active && me.role === "super_admin" ? email : null;
}

async function findUser(email: string): Promise<any | null> {
  for (let page = 1; page <= 20; page++) {
    const r = await authAdmin(`users?page=${page}&per_page=200`);
    const list: any[] = r.data?.users || [];
    const u = list.find((x) => String(x.email || "").toLowerCase() === email);
    if (u) return u;
    if (list.length < 200) break;
  }
  return null;
}

const okEmail = (e: string) => /^[^\s@]{1,64}@[^\s@]{1,190}\.[a-z]{2,}$/i.test(e);
const okPass = (p: string) => typeof p === "string" && p.length >= 8 && p.length <= 72;
const clip = (s: unknown, n: number) => String(s ?? "").trim().slice(0, n);

async function superCount(): Promise<number> {
  const r = await rest("gold_staff?select=email&role=eq.super_admin&active=eq.true");
  return Array.isArray(r.data) ? r.data.length : 0;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, err: "method" }, 405);
  try {
    const me = await owner(req);
    if (!me) return json({ ok: false, err: "owner" }, 403);
    const b = await req.json().catch(() => ({}));
    const action = String(b.action || "");
    const email = String(b.email || "").trim().toLowerCase();

    if (action === "list") {
      const r = await rest("gold_staff?select=email,name,role,active,added_at&order=added_at.asc");
      const rows: any[] = Array.isArray(r.data) ? r.data : [];
      // last sign-in time (helps the owner see who actually uses the panel)
      const out = [];
      for (const s of rows) {
        const u = await findUser(String(s.email));
        out.push({ ...s, last_sign_in: u?.last_sign_in_at || null, has_login: !!u });
      }
      return json({ ok: true, me, staff: out });
    }

    if (!okEmail(email)) return json({ ok: false, err: "email" }, 400);

    if (action === "add") {
      const role = ROLES.includes(b.role) ? b.role : "support";
      const name = clip(b.name, 60);
      const password = String(b.password || "");
      if (!okPass(password)) return json({ ok: false, err: "password" }, 400);
      let u = await findUser(email);
      if (!u) {
        const c = await authAdmin("users", { method: "POST", body: JSON.stringify({ email, password, email_confirm: true }) });
        if (!c.ok) return json({ ok: false, err: "auth", detail: c.data?.msg || c.data?.message || c.status }, 400);
        u = c.data;
      } else {
        await authAdmin(`users/${u.id}`, { method: "PUT", body: JSON.stringify({ password, ban_duration: "none" }) });
      }
      const r = await rest("gold_staff", {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates" },
        body: JSON.stringify({ email, name: name || null, role, active: true }),
      });
      return json({ ok: r.ok, err: r.ok ? undefined : "db" }, r.ok ? 200 : 500);
    }

    if (action === "update") {
      if (email === me && (b.role !== undefined || b.active === false)) return json({ ok: false, err: "self" }, 400);
      const patch: Record<string, unknown> = {};
      if (b.role !== undefined) {
        if (!ROLES.includes(b.role)) return json({ ok: false, err: "role" }, 400);
        patch.role = b.role;
      }
      if (b.name !== undefined) patch.name = clip(b.name, 60) || null;
      if (b.active !== undefined) patch.active = !!b.active;
      if (!Object.keys(patch).length) return json({ ok: false, err: "nothing" }, 400);
      const cur = await rest(`gold_staff?select=role,active&email=eq.${encodeURIComponent(email)}`);
      const row = Array.isArray(cur.data) ? cur.data[0] : null;
      if (!row) return json({ ok: false, err: "notfound" }, 404);
      // never leave the shop without an active owner
      const losingOwner = row.role === "super_admin" && row.active && (patch.role && patch.role !== "super_admin" || patch.active === false);
      if (losingOwner && (await superCount()) <= 1) return json({ ok: false, err: "last_owner" }, 400);
      const r = await rest(`gold_staff?email=eq.${encodeURIComponent(email)}`, { method: "PATCH", body: JSON.stringify(patch) });
      if (patch.active !== undefined) {
        const u = await findUser(email);
        // stopped staff cannot sign in at all (and their current session stops at the next token refresh)
        if (u) await authAdmin(`users/${u.id}`, { method: "PUT", body: JSON.stringify({ ban_duration: patch.active ? "none" : "876000h" }) });
      }
      return json({ ok: r.ok }, r.ok ? 200 : 500);
    }

    if (action === "password") {
      const password = String(b.password || "");
      if (!okPass(password)) return json({ ok: false, err: "password" }, 400);
      const u = await findUser(email);
      if (!u) return json({ ok: false, err: "notfound" }, 404);
      const r = await authAdmin(`users/${u.id}`, { method: "PUT", body: JSON.stringify({ password }) });
      return json({ ok: r.ok }, r.ok ? 200 : 500);
    }

    return json({ ok: false, err: "action" }, 400);
  } catch (e) {
    return json({ ok: false, err: String((e as Error)?.message || e) }, 500);
  }
});
