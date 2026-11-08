/* ===== STM Admin Pro =====
   1) Staff roles: role-aware panel + "Staff" tab (owner only) backed by the staff-admin edge function
   2) New-customer requests: modern cards, approve → prefilled form in Customers tab, reject with confirm
   3) Excel report (4 sheets) built in the browser from the data the panel already loaded (window.CU)
   The database enforces permissions (gold_can + restrictive RLS); hiding here is only for a clean UI. */
(function () {
  "use strict";
  const doc = document, SBU = typeof SB_URL !== "undefined" ? SB_URL : "", SBK = typeof SB_KEY !== "undefined" ? SB_KEY : "";
  const E = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const N = (n) => Math.round(+n || 0).toLocaleString("en-IN");
  const SCH = (k) => { try { return SN[k] || k || ""; } catch (e) { return k || ""; } };
  const MONS = (k) => { try { return MON(k); } catch (e) { return 11; } };
  const GRS = (k) => { try { return GR(k); } catch (e) { return false; } };
  const istNow = () => new Date(Date.now() + 330 * 60000);
  const ym = (d) => String(d).slice(0, 7);
  const TAM = ["ஜன", "பிப்", "மார்", "ஏப்", "மே", "ஜூன்", "ஜூலை", "ஆக", "செப்", "அக்", "நவ", "டிச"];
  const ymLabel = (s) => TAM[+s.slice(5, 7) - 1] + " " + s.slice(0, 4);
  const ini = (n) => (String(n || "?").trim().split(/\s+/).map((w) => w[0]).join("").slice(0, 2) || "?").toUpperCase();
  const ICON = {
    plus: '<path d="M12 5v14M5 12h14"/>',
    ok: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    x: '<path d="M6 6l12 12M18 6L6 18"/>',
    key: '<circle cx="8" cy="15" r="4"/><path d="M11 12l9-9M17 6l3 3"/>',
    copy: '<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/>',
    wa: '<path d="M4 20l1.3-4A8 8 0 1 1 8 18.7z"/>',
    dl: '<path d="M12 3v12M7 10l5 5 5-5M5 21h14"/>',
    xl: '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18"/>',
    staff: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/><path d="M17 3.5l1 1.8 2 .3-1.5 1.4.4 2-1.9-1-1.9 1 .4-2L14 5.6l2-.3z"/>',
    call: '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2"/>',
  };
  const svg = (k) => `<svg viewBox="0 0 24 24" aria-hidden="true">${ICON[k]}</svg>`;

  // ---------- roles ----------
  const ROLE = {
    super_admin: ["உரிமையாளர்", "Owner", "எல்லா வசதியும் + staff சேர்க்க / நீக்க"],
    admin: ["நிர்வாகி", "Admin", "Staff நிர்வாகம் தவிர எல்லாமே"],
    manager: ["மேலாளர்", "Manager", "Customer, தவணை பதிவு, விலை, அறிவிப்பு, App அமைப்பு"],
    accounts: ["கணக்காளர்", "Accounts", "தவணை பதிவு / நீக்கம், விலை, Excel report"],
    support: ["உதவியாளர்", "Support", "புதிய கோரிக்கைகள், அறிவிப்பு அனுப்ப"],
  };
  const PERM = {
    super_admin: () => true,
    admin: (p) => p !== "staff.manage",
    manager: (p) => ["cust.write", "pay.write", "rate.write", "settings.write", "notify.send", "req.handle", "report"].includes(p),
    accounts: (p) => ["pay.write", "pay.delete", "rate.write", "report"].includes(p),
    support: (p) => ["req.handle", "notify.send"].includes(p),
  };
  let MY = undefined; // undefined = not loaded, null = roles not set up in DB (legacy: everything allowed)
  const can = (p) => (MY == null ? true : !!(PERM[MY] && PERM[MY](p))); // roles not set up yet → behave exactly as before

  async function fn(name, body) {
    const { data } = await sb.auth.getSession();
    const t = data && data.session && data.session.access_token;
    if (!t) return { ok: false, err: "login" };
    try {
      const r = await fetch(SBU + "/functions/v1/" + name, { method: "POST", headers: { "Content-Type": "application/json", apikey: SBK, Authorization: "Bearer " + t }, body: JSON.stringify(body) });
      return await r.json().catch(() => ({ ok: false, err: "http" + r.status }));
    } catch (e) {
      return { ok: false, err: "net" };
    }
  }

  // ---------- small UI helpers ----------
  let toastEl;
  function toast(m) {
    if (!toastEl) { toastEl = doc.createElement("div"); toastEl.style.cssText = "position:fixed;left:50%;bottom:calc(24px + env(safe-area-inset-bottom));transform:translateX(-50%);background:#2A0A10;color:#fff;padding:12px 18px;border-radius:12px;font-size:14px;z-index:10000;max-width:90vw;box-shadow:0 8px 24px rgba(0,0,0,.25);transition:opacity .2s;opacity:0;pointer-events:none"; doc.body.appendChild(toastEl); }
    toastEl.textContent = m; toastEl.style.opacity = "1"; clearTimeout(toastEl._t); toastEl._t = setTimeout(() => (toastEl.style.opacity = "0"), 2600);
  }
  function sheet(html, onReady) {
    const ov = doc.createElement("div"); ov.className = "ap ap-ov"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true");
    ov.innerHTML = `<div class="ap-sheet"><div class="ap-grab"></div>${html}</div>`;
    const close = () => { ov.classList.remove("on"); setTimeout(() => ov.remove(), 220); doc.removeEventListener("keydown", esc); };
    const esc = (e) => { if (e.key === "Escape") close(); };
    ov.addEventListener("click", (e) => { if (e.target === ov || e.target.closest("[data-close]")) close(); });
    doc.addEventListener("keydown", esc);
    doc.body.appendChild(ov); requestAnimationFrame(() => ov.classList.add("on"));
    onReady && onReady(ov.querySelector(".ap-sheet"), close);
    return close;
  }
  function confirmSheet(title, text, okLabel, danger) {
    return new Promise((res) => {
      sheet(`<h3>${E(title)}</h3><p class="ap-sub">${E(text)}</p><div class="ap-row"><button type="button" class="ap-btn o" data-close>வேண்டாம்</button><button type="button" class="ap-btn ${danger ? "no" : ""}" data-yes>${E(okLabel)}</button></div>`,
        (s, close) => { s.querySelector("[data-yes]").onclick = () => { close(); res(true); }; s.querySelectorAll("[data-close]").forEach((b) => b.addEventListener("click", () => res(false))); });
    });
  }
  const genPass = () => Array.from(crypto.getRandomValues(new Uint8Array(10)), (b) => "ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789"[b % 55]).join("");
  const cardByTitle = (t) => [...doc.querySelectorAll("#adm .card")].find((c) => { const h = c.querySelector("h2"); return h && h.textContent.replace(/[^஀-௿A-Za-z0-9 ]/g, "").trim().startsWith(t); });

  // ---------- role-aware panel ----------
  async function loadRole() {
    try {
      const { data, error } = await sb.rpc("gold_role");
      MY = error ? null : (data || "none");
    } catch (e) { MY = null; }
    applyRole();
  }
  function applyRole() {
    const bar = doc.getElementById("stabs"); if (!bar) return;
    const hideTab = (g, hide) => { const b = bar.querySelector(`[data-g="${g}"]`); if (b) b.style.display = hide ? "none" : ""; };
    hideTab("set", !can("settings.write"));
    hideTab("notify", !can("notify.send"));
    const hideCard = (t, hide) => { const c = cardByTitle(t); if (c) c.style.display = hide ? "none" : ""; };
    hideCard("இன்றைய 22K விலை", !can("rate.write"));
    hideCard("பழைய விலை சேர்க்க", !can("rate.write"));
    hideCard("தவணை பதிவு", !can("pay.write"));
    hideCard("புதிய Customer", !(can("cust.write") || can("req.handle")));
    hideCard("புதிய கோரிக்கைகள்", !can("req.handle"));
    hideCard("Refer & Earn அமைப்பு", !can("settings.write"));
    const xl = doc.getElementById("apxl"); if (xl) xl.style.display = can("report") || MY == null ? "" : "none";
    // the active tab may have just been hidden
    const on = bar.querySelector("[data-g].on");
    if (on && on.style.display === "none" && window.staffTab) window.staffTab("today");
    staffTabButton();
    // role chip under the tab bar
    let me = doc.getElementById("apme");
    if (!me) { me = doc.createElement("div"); me.id = "apme"; me.className = "ap ap-me"; bar.after(me); }
    me.innerHTML = MY && ROLE[MY] ? `நீங்கள்: <span class="ap-chip r-${MY}">${ROLE[MY][0]} · ${ROLE[MY][1]}</span>` : "";
    if (MY === "none") me.innerHTML = '<span class="ap-chip off">இந்த கணக்குக்கு அனுமதி இல்ல. Owner-ஐ அணுகவும்.</span>';
  }

  // ---------- Staff tab ----------
  let staffPanel;
  function staffTabButton() {
    const bar = doc.getElementById("stabs"); if (!bar) return;
    let b = bar.querySelector('[data-ap="staff"]');
    const show = MY === "super_admin" || MY === null;
    if (!b && show) {
      b = doc.createElement("button"); b.type = "button"; b.dataset.ap = "staff"; b.setAttribute("role", "tab");
      b.innerHTML = doc.documentElement.hasAttribute("data-a5") ? `${svg("staff")}<span>Staff</span>` : "👤 Staff";
      const sp = bar.querySelector(".sp"); bar.insertBefore(b, sp || null);
      staffPanel = doc.createElement("div"); staffPanel.className = "sgrp"; staffPanel.id = "g_staff"; staffPanel.setAttribute("role", "tabpanel");
      staffPanel.innerHTML = `<div class="card ap" id="apstaff"></div>`;
      doc.getElementById("adm").appendChild(staffPanel);
      b.addEventListener("click", () => {
        bar.querySelectorAll("[data-g],[data-ap]").forEach((x) => { const on = x === b; x.classList.toggle("on", on); x.setAttribute("aria-selected", on); });
        doc.querySelectorAll("#adm .sgrp").forEach((g) => g.classList.toggle("on", g === staffPanel));
        scrollTo({ top: 0 }); renderStaff();
      });
      bar.addEventListener("click", (e) => { if (e.target.closest("[data-g]")) { b.classList.remove("on"); staffPanel.classList.remove("on"); } });
    }
    if (b) b.style.display = show ? "" : "none";
    bar.classList.toggle("ap5", !!b && show);
  }

  async function renderStaff() {
    const box = doc.getElementById("apstaff"); if (!box) return;
    const head = `<div class="ap-h"><h2>Staff & அனுமதிகள்</h2><button type="button" class="ap-btn sm" id="apadd">${svg("plus")}புது Staff</button></div>
      <p class="ap-sub">ஒவ்வொரு staff-க்கும் அவங்க வேலைக்கு ஏத்த அனுமதி (role) கொடுங்க. அனுமதி database-லயே சரிபார்க்கப்படும்.</p>`;
    if (MY === null) {
      box.innerHTML = head.replace(/<button[^]*?<\/button>/, "") + `<div class="ap-empty"><b>Staff roles இன்னும் database-ல இயக்கப்படல</b>Owner அனுமதி கொடுத்ததும் இங்கே staff சேர்க்க, role மாற்ற முடியும்.</div>`;
      return;
    }
    box.innerHTML = head + `<div class="ap-list"><div class="ap-empty">ஏற்றுகிறது…</div></div>`;
    box.querySelector("#apadd").onclick = () => staffSheet();
    const d = await fn("staff-admin", { action: "list" });
    const list = box.querySelector(".ap-list");
    if (!d.ok) { list.innerHTML = `<div class="ap-empty"><b>Staff பட்டியல் ஏற்ற முடியல</b>${E(d.err === "owner" ? "இது Owner-க்கு மட்டும்." : d.err || "")}</div>`; return; }
    const ago = (t) => { if (!t) return "இன்னும் login பண்ணல"; const h = (Date.now() - new Date(t)) / 36e5; return h < 1 ? "சற்று முன் login" : h < 24 ? Math.round(h) + " மணி நேரம் முன் login" : Math.round(h / 24) + " நாள் முன் login"; };
    list.innerHTML = d.staff.map((s) => {
      const r = ROLE[s.role] || [s.role, "", ""], self = s.email === d.me;
      return `<div class="ap-item" data-em="${E(s.email)}"><div class="ap-av">${E(ini(s.name || s.email))}</div><div class="ap-main">
        <b>${E(s.name || s.email.split("@")[0])}${self ? " (நீங்கள்)" : ""}</b><small>${E(s.email)}</small><small>${E(ago(s.last_sign_in))}</small>
        <div class="ap-chips"><span class="ap-chip r-${E(s.role)}">${E(r[0])} · ${E(r[1])}</span>${s.active ? "" : '<span class="ap-chip off">நிறுத்தப்பட்டது</span>'}</div>
        ${self ? "" : `<div class="ap-acts"><button type="button" class="ap-btn sm o" data-act="edit">Role மாற்ற</button><button type="button" class="ap-btn sm o" data-act="pw">${svg("key")}Password</button>${s.active ? '<button type="button" class="ap-btn sm no" data-act="stop">நிறுத்து</button>' : '<button type="button" class="ap-btn sm ok" data-act="start">மீண்டும் இயக்கு</button>'}</div>`}
      </div></div>`;
    }).join("");
    list.onclick = async (e) => {
      const b = e.target.closest("[data-act]"); if (!b) return;
      const em = b.closest("[data-em]").dataset.em, s = d.staff.find((x) => x.email === em);
      if (b.dataset.act === "edit") return staffSheet(s);
      if (b.dataset.act === "pw") return passSheet(s);
      const stop = b.dataset.act === "stop";
      if (!(await confirmSheet(stop ? "Staff-ஐ நிறுத்தவா?" : "மீண்டும் இயக்கவா?", stop ? `${s.name || s.email} இனிமே admin panel-ல login பண்ண முடியாது. பின்னாடி மீண்டும் இயக்கலாம்.` : `${s.name || s.email} மீண்டும் login பண்ணலாம்.`, stop ? "நிறுத்து" : "இயக்கு", stop))) return;
      const r = await fn("staff-admin", { action: "update", email: em, active: !stop });
      toast(r.ok ? (stop ? "நிறுத்தப்பட்டது" : "மீண்டும் இயக்கப்பட்டது") : errText(r.err)); renderStaff();
    };
  }
  const errText = (e) => ({ owner: "இது Owner-க்கு மட்டும்", email: "Email சரியா இல்ல", password: "Password குறைஞ்சது 8 எழுத்து", last_owner: "கடைசி Owner-ஐ மாற்ற முடியாது", self: "உங்க சொந்த role-ஐ மாற்ற முடியாது", auth: "Login உருவாக்க முடியல", net: "இணைய இணைப்பு இல்ல" }[e] || "முடியல: " + (e || ""));

  function staffSheet(s) {
    const edit = !!s, pass = genPass();
    const roles = Object.keys(ROLE).map((k) => `<label class="ap-role"><input type="radio" name="aprole" value="${k}" ${(s ? s.role : "support") === k ? "checked" : ""}><span><b>${ROLE[k][0]} · ${ROLE[k][1]}</b><small>${ROLE[k][2]}</small></span></label>`).join("");
    sheet(`<h3>${edit ? "Role மாற்ற" : "புது Staff சேர்க்க"}</h3><p class="ap-sub">${edit ? E(s.email) : "Staff-ஓட email-ம் ஒரு தற்காலிக password-ம் கொடுங்க. முதல் login-க்கு பிறகு அவங்க மாத்திக்கலாம்."}</p>
      <label class="ap-f"><span>பெயர்</span><input id="apn" maxlength="60" value="${E(s ? s.name || "" : "")}" placeholder="உதா: முருகன்"></label>
      ${edit ? "" : `<label class="ap-f"><span>Email</span><input id="ape" type="email" inputmode="email" autocomplete="off" placeholder="staff@gmail.com"></label>
      <label class="ap-f"><span>தற்காலிக Password</span><span class="ap-pw"><input id="appw" value="${pass}" autocomplete="off"><button type="button" class="ap-btn o sm" id="apcp">${svg("copy")}</button></span></label>`}
      <div class="ap-f"><span>Role (அனுமதி)</span><div class="ap-roles">${roles}</div></div>
      <div class="ap-msg" id="apm"></div>
      <div class="ap-row"><button type="button" class="ap-btn o" data-close>ரத்து</button><button type="button" class="ap-btn" id="apsv">${edit ? "சேமி" : "சேர்"}</button></div>`,
      (sh, close) => {
        const cp = sh.querySelector("#apcp"); if (cp) cp.onclick = () => { navigator.clipboard && navigator.clipboard.writeText(sh.querySelector("#appw").value); toast("Password copy ஆச்சு"); };
        sh.querySelector("#apsv").onclick = async (ev) => {
          const btn = ev.currentTarget, m = sh.querySelector("#apm");
          const role = (sh.querySelector('input[name="aprole"]:checked') || {}).value, name = sh.querySelector("#apn").value.trim();
          const body = edit ? { action: "update", email: s.email, role, name } : { action: "add", email: sh.querySelector("#ape").value.trim(), password: sh.querySelector("#appw").value, role, name };
          if (!edit && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)) { m.className = "ap-msg e"; m.textContent = "சரியான email போடுங்க"; return; }
          btn.disabled = true; m.className = "ap-msg"; m.textContent = "சேமிக்கிறது…";
          const r = await fn("staff-admin", body); btn.disabled = false;
          if (!r.ok) { m.className = "ap-msg e"; m.textContent = errText(r.err); return; }
          close(); renderStaff();
          if (!edit) shareLogin(body.email, body.password, name, role); else toast("சேமிச்சாச்சு ✅");
        };
      });
  }
  function shareLogin(email, pw, name, role) {
    const url = location.origin + location.pathname;
    const msg = `வணக்கம் ${name || ""},\nசுப்புலட்சுமி தங்க மாளிகை Admin panel:\n${url}\nEmail: ${email}\nPassword: ${pw}\nRole: ${ROLE[role][0]}\nமுதல் login-க்கு பிறகு password-ஐ மாத்திக்கோங்க.`;
    sheet(`<h3>Staff சேர்ந்தாச்சு ✅</h3><p class="ap-sub">இந்த login விவரத்தை staff-க்கு அனுப்புங்க. Password இப்போ மட்டும் தான் தெரியும்.</p>
      <div class="ap-note" style="white-space:pre-wrap;font-family:ui-monospace,Menlo,monospace">${E(msg)}</div>
      <div class="ap-row"><button type="button" class="ap-btn o" id="apc2">${svg("copy")}Copy</button><a class="ap-btn" style="text-decoration:none" target="_blank" rel="noopener" href="https://api.whatsapp.com/send?text=${encodeURIComponent(msg)}">${svg("wa")}WhatsApp</a></div>
      <div class="ap-row" style="margin-top:8px"><button type="button" class="ap-btn o" data-close>சரி</button></div>`,
      (sh) => { sh.querySelector("#apc2").onclick = () => { navigator.clipboard && navigator.clipboard.writeText(msg); toast("Copy ஆச்சு"); }; });
  }
  function passSheet(s) {
    const pass = genPass();
    sheet(`<h3>புது Password</h3><p class="ap-sub">${E(s.name || s.email)} · பழைய password வேலை செய்யாது.</p>
      <label class="ap-f"><span>புது Password</span><span class="ap-pw"><input id="appw" value="${pass}" autocomplete="off"></span></label>
      <div class="ap-msg" id="apm"></div>
      <div class="ap-row"><button type="button" class="ap-btn o" data-close>ரத்து</button><button type="button" class="ap-btn" id="apsv">மாற்று</button></div>`,
      (sh, close) => {
        sh.querySelector("#apsv").onclick = async () => {
          const pw = sh.querySelector("#appw").value, m = sh.querySelector("#apm");
          const r = await fn("staff-admin", { action: "password", email: s.email, password: pw });
          if (!r.ok) { m.className = "ap-msg e"; m.textContent = errText(r.err); return; }
          close(); shareLogin(s.email, pw, s.name, s.role);
        };
      });
  }

  // ---------- requests (approve / reject) ----------
  function renderRequests() {
    const box = doc.getElementById("rq"); if (!box || !Array.isArray(window.RQ)) return;
    const card = box.closest(".card"); const h = card && card.querySelector("h2");
    if (h && !h.querySelector(".ap-badge")) h.insertAdjacentHTML("beforeend", ' <span class="ap-badge" id="aprqn"></span>');
    const bd = doc.getElementById("aprqn"); if (bd) { bd.textContent = RQ.length; bd.style.display = RQ.length ? "" : "none"; }
    box.classList.add("ap");
    if (!RQ.length) { box.innerHTML = '<div class="ap-empty"><b>புது கோரிக்கை இல்ல ✨</b>App-ல யாராவது சேர விண்ணப்பிச்சா இங்கே வரும்.</div>'; return; }
    const ago = (t) => { const h = (Date.now() - new Date(t)) / 36e5; return h < 1 ? "இப்போது" : h < 24 ? Math.round(h) + " மணி நேரம் முன்" : Math.round(h / 24) + " நாள் முன்"; };
    box.innerHTML = '<div class="ap-list">' + RQ.map((q) => `<div class="ap-item" data-q="${E(q.id)}"><div class="ap-av">${E(ini(q.name))}</div><div class="ap-main">
      <b>${E(q.name)}</b><small><a href="tel:${E(q.mobile)}" style="color:inherit">${E(q.mobile)}</a>${q.email ? " · " + E(q.email) : ""} · ${E(ago(q.created_at))}</small>
      <div class="ap-chips"><span class="ap-chip">${E(SCH(q.scheme))}</span>${q.monthly_amount ? `<span class="ap-chip">₹${N(q.monthly_amount)} / மாதம்</span>` : ""}${q.ref_code ? `<span class="ap-chip">Refer: ${E(q.ref_code)}</span>` : ""}</div>
      <small style="margin-top:6px">${E([q.address, q.city, q.pincode].filter(Boolean).join(", "))}${q.nominee ? `<br>Nominee: ${E(q.nominee)}${q.nominee_rel ? " (" + E(q.nominee_rel) + ")" : ""}` : ""}</small>
      <div class="ap-acts"><button type="button" class="ap-btn sm ok" data-ap="${E(q.id)}">${svg("ok")}ஏற்க</button><button type="button" class="ap-btn sm no" data-rj="${E(q.id)}">${svg("x")}நிராகரி</button><a class="ap-btn sm o" style="text-decoration:none" target="_blank" rel="noopener" href="https://api.whatsapp.com/send?phone=91${E(q.mobile)}">${svg("wa")}</a></div>
    </div></div>`).join("") + "</div>";
  }
  function hookRequests() {
    const box = doc.getElementById("rq"); if (!box || box._ap) return; box._ap = 1;
    // capture: runs before the old handler, which we stop for these two buttons
    box.addEventListener("click", async (e) => {
      const ap = e.target.closest("[data-ap]"), rj = e.target.closest("[data-rj]");
      if (!ap && !rj) return;
      e.stopPropagation(); e.preventDefault();
      if (rj) {
        const q = RQ.find((x) => String(x.id) === rj.dataset.rj);
        if (!(await confirmSheet("கோரிக்கையை நிராகரிக்கவா?", `${q ? q.name : ""} · ${q ? q.mobile : ""}. இது பட்டியல்ல இருந்து போயிடும்.`, "நிராகரி", true))) return;
        const { error } = await sb.from("gold_requests").update({ status: "rejected" }).eq("id", rj.dataset.rj);
        toast(error ? "முடியல: " + error.message : "நிராகரிக்கப்பட்டது"); loadReq(); return;
      }
      const q = RQ.find((x) => String(x.id) === ap.dataset.ap); if (!q) return;
      window.REQD = q;
      const set = (id, v) => { const el = doc.getElementById(id); if (el) el.value = v || ""; };
      set("nn", q.name); set("nm", q.mobile); set("ne", q.email); set("ns", q.scheme); set("na", q.monthly_amount); set("nr", q.ref_code); set("ndob", q.dob); set("nanv", q.anniv);
      if (window.S6) window.S6.go("newcust"); else if (window.staffTab) window.staffTab("cust");
      const f = cardByTitle("புதிய Customer");
      if (f) { f.style.display = ""; f.scrollIntoView({ behavior: "smooth", block: "start" }); f.style.boxShadow = "0 0 0 3px #E5C98B"; setTimeout(() => (f.style.boxShadow = ""), 2500); }
      toast("விவரம் நிரப்பியாச்சு. ID proof பார்த்து 'சேர்' அழுத்துங்க.");
    }, true);
  }
  if (typeof loadReq === "function") {
    const orig = loadReq;
    loadReq = async function () { await orig.apply(this, arguments); hookRequests(); renderRequests(); }; // eslint-disable-line no-global-assign
  }

  // ---------- Excel report ----------
  function xlCard() {
    if (doc.getElementById("apxl")) return;
    const host = cardByTitle("வசூல் விவரம்") || cardByTitle("Customers"); if (!host) return;
    const c = doc.createElement("div"); c.className = "card ap"; c.id = "apxl";
    let opts = '<option value="">எல்லா திட்டங்களும்</option>';
    try { const keys = [...new Set((window.CU || []).map((x) => x.scheme))]; keys.forEach((k) => (opts += `<option value="${E(k)}">${E(SCH(k))}</option>`)); } catch (e) {}
    c.innerHTML = `<div class="ap-h"><span class="ap-xlic">${svg("xl")}</span><div style="flex:1"><h2 style="margin:0">Excel Report</h2><small style="color:#777">யார் எந்த திட்டத்துல எவ்வளவு கட்டியிருக்காங்க</small></div></div>
      <div class="ap-xl" style="margin-top:12px"><label class="ap-f"><span>திட்டம்</span><select id="apxs">${opts}</select></label>
      <div class="ap-sheets"><label><input type="checkbox" value="sum" checked>திட்ட வாரி சுருக்கம்</label><label><input type="checkbox" value="cust" checked>Customer பட்டியல்</label><label><input type="checkbox" value="grid" checked>மாத வாரி அட்டவணை</label><label><input type="checkbox" value="pay" checked>எல்லா தவணைகளும்</label></div>
      <button type="button" class="ap-btn" id="apxg">${svg("dl")}Excel பதிவிறக்கம்</button><div class="ap-msg" id="apxm"></div></div>`;
    host.after(c);
    c.querySelector("#apxg").onclick = buildExcel;
  }
  function loadXLSX() {
    if (window.XLSX) return Promise.resolve(window.XLSX);
    return new Promise((res, rej) => { const s = doc.createElement("script"); s.src = "https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"; s.onload = () => res(window.XLSX); s.onerror = rej; doc.head.appendChild(s); });
  }
  async function buildExcel() {
    const m = doc.getElementById("apxm"), btn = doc.getElementById("apxg");
    const CU = window.CU; if (!Array.isArray(CU)) { m.className = "ap-msg e"; m.textContent = "Customer விவரம் இன்னும் ஏறல. சில நொடி கழிச்சு முயற்சிக்கவும்."; return; }
    const pick = [...doc.querySelectorAll("#apxl .ap-sheets input:checked")].map((x) => x.value);
    if (!pick.length) { m.className = "ap-msg e"; m.textContent = "குறைஞ்சது ஒரு sheet தேர்வு பண்ணுங்க"; return; }
    btn.disabled = true; m.className = "ap-msg"; m.textContent = "Report தயாராகுது…";
    let X; try { X = await loadXLSX(); } catch (e) { btn.disabled = false; m.className = "ap-msg e"; m.textContent = "Excel tool ஏற்ற முடியல. இணையத்தை சரிபார்க்கவும்."; return; }
    const sch = doc.getElementById("apxs").value;
    const list = CU.filter((c) => !sch || c.scheme === sch);
    const today = istNow().toISOString().slice(0, 10), cym = today.slice(0, 7);
    const pays = (c) => (c.gold_payments || []).slice().sort((a, b) => String(a.paid_on).localeCompare(String(b.paid_on)));
    const silver = (k) => /சில்வர்|வெள்ளி|silver/i.test(SCH(k));
    const paidN = (c) => silver(c.scheme) ? new Set(pays(c).map((p) => ym(p.paid_on))).size : pays(c).length;
    const MODE = { cash: "பணம்", upi: "UPI", card: "Card", bank: "Bank", online: "Online (app)" };
    const wb = X.utils.book_new();
    const add = (name, rows, widths) => { const ws = X.utils.aoa_to_sheet(rows); ws["!cols"] = widths.map((w) => ({ wch: w })); if (rows.length > 1) ws["!autofilter"] = { ref: X.utils.encode_range({ s: { r: 0, c: 0 }, e: { r: rows.length - 1, c: rows[0].length - 1 } }) }; X.utils.book_append_sheet(wb, ws, name); };

    if (pick.includes("sum")) {
      const keys = [...new Set(list.map((c) => c.scheme))];
      const rows = [["திட்டம்", "Customers", "நடப்பில்", "முடிந்தது", "இந்த மாதம் கட்டியவர்", "இந்த மாதம் நிலுவை", "இந்த மாத வசூல் (₹)", "மொத்த வசூல் (₹)", "மொத்த தங்கம் (கி)"]];
      let T = [0, 0, 0, 0, 0, 0, 0, 0];
      keys.forEach((k) => {
        const cs = list.filter((c) => c.scheme === k);
        const done = cs.filter((c) => paidN(c) >= MONS(k)).length;
        const paidNow = cs.filter((c) => pays(c).some((p) => ym(p.paid_on) === cym)).length;
        const monthSum = cs.reduce((s, c) => s + pays(c).filter((p) => ym(p.paid_on) === cym).reduce((a, p) => a + (+p.amount || 0), 0), 0);
        const tot = cs.reduce((s, c) => s + pays(c).reduce((a, p) => a + (+p.amount || 0), 0), 0);
        const g = cs.reduce((s, c) => s + pays(c).reduce((a, p) => a + (+p.grams || 0), 0), 0);
        const r = [cs.length, cs.length - done, done, paidNow, cs.length - done - paidNow, monthSum, tot, +g.toFixed(3)];
        r.forEach((v, i) => (T[i] += v)); rows.push([SCH(k), ...r]);
      });
      rows.push(["மொத்தம்", ...T.map((v, i) => (i === 7 ? +v.toFixed(3) : v))]);
      rows.push([]); rows.push(["Report தேதி", today]); rows.push(["சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி"]);
      add("திட்ட சுருக்கம்", rows, [26, 11, 10, 11, 18, 17, 18, 16, 16]);
    }
    if (pick.includes("cust")) {
      const rows = [["#", "பெயர்", "மொபைல்", "திட்டம்", "மாதத் தொகை (₹)", "சேர்ந்த நாள்", "கட்டிய தவணை", "மொத்த தவணை", "மீதி", "மொத்தம் (₹)", "தங்கம் (கி)", "கடைசி தவணை", "இந்த மாதம்", "நிலை", "Referral code", "Nominee", "முகவரி"]];
      list.forEach((c, i) => {
        const ps = pays(c), n = paidN(c), mo = MONS(c.scheme), last = ps.length ? ps[ps.length - 1].paid_on : "";
        const tot = ps.reduce((a, p) => a + (+p.amount || 0), 0), g = ps.reduce((a, p) => a + (+p.grams || 0), 0);
        rows.push([i + 1, c.name || "", c.mobile || "", SCH(c.scheme), +c.monthly_amount || 0, c.start_date || "", n, mo, Math.max(0, mo - n), tot, GRS(c.scheme) ? +g.toFixed(3) : "", last ? String(last).slice(0, 10) : "",
          n >= mo ? "—" : ps.some((p) => ym(p.paid_on) === cym) ? "கட்டியாச்சு" : "நிலுவை", n >= mo ? "முடிந்தது" : n ? "நடப்பில்" : "தொடங்கல", c.ref_code || "", c.nominee ? c.nominee + (c.nominee_rel ? " (" + c.nominee_rel + ")" : "") : "", c.address || ""]);
      });
      add("Customers", rows, [5, 24, 13, 22, 14, 13, 12, 12, 8, 13, 11, 13, 12, 11, 13, 22, 36]);
    }
    if (pick.includes("grid")) {
      const all = list.flatMap((c) => pays(c).map((p) => ym(p.paid_on))).concat(list.map((c) => ym(c.start_date || cym))).filter(Boolean).sort();
      const months = []; // plain "YYYY-MM" arithmetic (no Date / timezone shifts)
      if (all.length) { let y = +all[0].slice(0, 4), mo = +all[0].slice(5, 7); const ey = +cym.slice(0, 4), em = +cym.slice(5, 7);
        while ((y < ey || (y === ey && mo <= em)) && months.length < 60) { months.push(y + "-" + String(mo).padStart(2, "0")); if (++mo > 12) { mo = 1; y++; } } }
      const rows = [["பெயர்", "மொபைல்", "திட்டம்", ...months.map(ymLabel), "மொத்தம் (₹)", "தவணை"]];
      const colT = months.map(() => 0);
      list.forEach((c) => {
        const by = {}; pays(c).forEach((p) => { const k = ym(p.paid_on); by[k] = (by[k] || 0) + (+p.amount || 0); });
        const cells = months.map((k, i) => { colT[i] += by[k] || 0; return by[k] || ""; });
        rows.push([c.name || "", c.mobile || "", SCH(c.scheme), ...cells, Object.values(by).reduce((a, b) => a + b, 0), paidN(c) + "/" + MONS(c.scheme)]);
      });
      rows.push(["மாத மொத்தம்", "", "", ...colT, colT.reduce((a, b) => a + b, 0), ""]);
      add("மாத அட்டவணை", rows, [24, 13, 20, ...months.map(() => 10), 13, 8]);
    }
    if (pick.includes("pay")) {
      const rows = [["தேதி", "பெயர்", "மொபைல்", "திட்டம்", "தவணை எண்", "தொகை (₹)", "அன்றைய விலை (₹/கி)", "தங்கம் (கி)", "முறை"]];
      const all = [];
      list.forEach((c) => pays(c).forEach((p, i) => all.push([String(p.paid_on).slice(0, 10), c.name || "", c.mobile || "", SCH(c.scheme), i + 1, +p.amount || 0, p.gold_rate ? +p.gold_rate : "", p.grams ? +(+p.grams).toFixed(3) : "", MODE[p.mode] || p.mode || ""])));
      all.sort((a, b) => b[0].localeCompare(a[0]));
      rows.push(...all); rows.push([]); rows.push(["மொத்தம்", "", "", "", all.length + " தவணை", all.reduce((a, r) => a + r[5], 0)]);
      add("எல்லா தவணைகள்", rows, [12, 24, 13, 22, 10, 12, 16, 11, 13]);
    }
    const fname = `STM-Report-${sch ? SCH(sch).replace(/\s+/g, "-") + "-" : ""}${today}.xlsx`;
    try { X.writeFile(wb, fname); m.className = "ap-msg s"; m.textContent = `✅ ${fname} பதிவிறக்கம் ஆச்சு · ${list.length} customer`; }
    catch (e) { m.className = "ap-msg e"; m.textContent = "File உருவாக்க முடியல: " + (e.message || e); }
    btn.disabled = false;
  }

  // ---------- start when the admin panel is shown ----------
  function boot() {
    const adm = doc.getElementById("adm"); if (!adm) return;
    if (adm.classList.contains("hide")) { adm._ap = 0; MY = undefined; return; } // logged out → reload role on next login
    if (adm._ap) return;
    adm._ap = 1; loadRole();
    let n = 0; const t = setInterval(() => { n++; if (Array.isArray(window.CU) || n > 40) { clearInterval(t); xlCard(); applyRole(); hookRequests(); if (Array.isArray(window.RQ)) renderRequests(); } }, 400);
  }
  const adm = doc.getElementById("adm");
  if (adm) { new MutationObserver(boot).observe(adm, { attributes: true, attributeFilter: ["class"] }); boot(); }
  window.APRO = { can, role: () => MY, renderStaff };
})();
