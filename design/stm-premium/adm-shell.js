/* ===== STM Staff v6 shell =====
   Moves the panel's existing cards (same elements, same ids, same event listeners) into a new
   app shell: bottom nav on phones, sidebar on desktop, dashboard widgets, customer search,
   grouped settings, in-app dialogs. No Supabase call, RLS rule or business calculation changes here. */
(function () {
  "use strict";
  if (!document.documentElement.hasAttribute("data-s6")) return;
  const doc = document;
  const $i = (id) => doc.getElementById(id);
  const E = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const N = (n) => Math.round(+n || 0).toLocaleString("en-IN");
  const T = (f, d) => { try { return f(); } catch (e) { return d; } };
  const istNow = () => new Date(Date.now() + 330 * 60000);
  const TAM = ["ஜன", "பிப்", "மார்", "ஏப்", "மே", "ஜூன்", "ஜூலை", "ஆக", "செப்", "அக்", "நவ", "டிச"];
  const ini = (n) => (String(n || "?").trim().split(/[\s@._]+/).filter(Boolean).map((w) => w[0]).join("").slice(0, 2) || "?").toUpperCase();
  const I = {
    dash: '<rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/>',
    cust: '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M21.5 20a6.5 6.5 0 0 0-4-6"/>',
    chat: '<path d="M21 12a8 8 0 0 1-11.8 7L4 20l1.1-4A8 8 0 1 1 21 12z"/>',
    bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/>',
    set: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/>',
    back: '<path d="M15 5l-7 7 7 7"/>',
    chev: '<path d="M9 5l7 7-7 7"/>',
    pay: '<rect x="2.5" y="5" width="19" height="14" rx="2.5"/><path d="M2.5 10h19M7 15h4"/>',
    add: '<circle cx="10" cy="8" r="4"/><path d="M3 20a7 7 0 0 1 12.5-4.3M19 14v6M16 17h6"/>',
    rate: '<path d="M3 17l6-6 4 4 8-8"/><path d="M15 7h6v6"/>',
    xl: '<rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M3 15h18M9 3v18"/>',
    remind: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2.5M5 3 2 6M19 3l3 3"/>',
    gift: '<rect x="3" y="8" width="18" height="13" rx="2"/><path d="M12 8v13M3 12h18M12 8S10.5 3 8 3.5 7 8 12 8zm0 0s1.5-5 4-4.5S17 8 12 8z"/>',
    poster: '<rect x="4" y="3" width="16" height="18" rx="2"/><path d="m4 16 4.5-4.5L13 16l3-3 4 4"/><circle cx="15" cy="8" r="1.6"/>',
    scheme: '<path d="M6 3h12l3 6-9 12L3 9z"/><path d="M3 9h18M9 3l3 6 3-6M12 21 9 9M12 21l3-12"/>',
    img: '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="m21 16-5-5-9 9"/>',
    link: '<path d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1"/><path d="M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/>',
    staff: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    key: '<circle cx="8" cy="15" r="4"/><path d="M10.8 12.2 20 3M16 7l3 3M14 9l2 2"/>',
    dev: '<path d="m8 9-4 3 4 3M16 9l4 3-4 3M14 5l-4 14"/>',
    more: '<circle cx="5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="19" cy="12" r="1.5"/>',
    out: '<path d="M15 4h4v16h-4M10 8l-4 4 4 4M6 12h11"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    eye: '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
    eyeoff: '<path d="M3 3l18 18M10.6 5.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3.2 4.1M6.6 6.6C3.8 8.3 2 12 2 12s3.5 7 10 7c1.8 0 3.3-.5 4.6-1.2M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 8h.01M11 12h1v5h1"/>',
    ok: '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 2.8 2.8L16.5 9.5"/>',
    warn: '<path d="M12 3 2 20h20L12 3z"/><path d="M12 10v4M12 17h.01"/>',
    wa: '<path d="M4 20l1.3-4A8 8 0 1 1 8 18.7z"/>',
  };
  const svg = (k) => `<svg viewBox="0 0 24 24" aria-hidden="true">${I[k] || ""}</svg>`;

  // =============== in-app dialogs (replace native alert / confirm / prompt) ===============
  let toastEl;
  function toast(msg, kind) {
    if (!toastEl) { toastEl = doc.createElement("div"); toastEl.className = "s6toast"; toastEl.setAttribute("role", "status"); doc.body.appendChild(toastEl); }
    toastEl.className = "s6toast " + (kind || ""); toastEl.textContent = msg;
    requestAnimationFrame(() => toastEl.classList.add("on"));
    clearTimeout(toastEl._t); toastEl._t = setTimeout(() => toastEl.classList.remove("on"), msg.length > 40 ? 3800 : 2400);
  }
  function dialog(msg, opt) {
    opt = opt || {};
    return new Promise((res) => {
      const ov = doc.createElement("div"); ov.className = "s6ov s6"; ov.setAttribute("role", opt.cancel ? "alertdialog" : "dialog"); ov.setAttribute("aria-modal", "true");
      const ic = opt.kind === "err" ? "warn" : opt.kind === "ok" ? "ok" : "info";
      ov.innerHTML = `<div class="s6dlg"><div class="ic ${opt.kind || ""}">${svg(ic)}</div><p>${E(msg)}</p>${opt.input !== undefined ? `<input value="${E(opt.input)}">` : ""}<div class="bt">${opt.cancel ? `<button type="button" class="o" data-v="0">${E(opt.cancel)}</button>` : ""}<button type="button" data-v="1">${E(opt.ok || "சரி")}</button></div></div>`;
      const inp = ov.querySelector("input");
      const done = (v) => { ov.classList.remove("on"); doc.removeEventListener("keydown", key); setTimeout(() => ov.remove(), 180); res(opt.input !== undefined ? (v ? inp.value : null) : v); };
      const key = (e) => { if (e.key === "Escape") done(false); if (e.key === "Enter" && (inp || !opt.cancel)) done(true); };
      ov.addEventListener("click", (e) => { const b = e.target.closest("[data-v]"); if (b) done(b.dataset.v === "1"); else if (e.target === ov && opt.cancel) done(false); });
      doc.addEventListener("keydown", key);
      doc.body.appendChild(ov); requestAnimationFrame(() => ov.classList.add("on"));
      setTimeout(() => (inp || ov.querySelector('[data-v="1"]')).focus(), 60);
    });
  }
  const isErr = (m) => /தவறு|முடியல|முடியவில்லை|வேண்டும்|இல்ல|போகல|error|failed|denied|violates|permission|மறுக்க/i.test(m);
  const nativeAlert = window.alert.bind(window);
  window.alert = function (m) {
    m = String(m ?? "");
    const err = isErr(m) && !/✅/.test(m);
    if (!err && m.length <= 70 && !m.includes("\n")) return toast(m, /✅/.test(m) ? "ok" : "");
    dialog(m, { kind: err ? "err" : /✅/.test(m) ? "ok" : "" });
  };
  window.ASK = (m) => dialog(m, { cancel: "வேண்டாம்", ok: "ஆம்" });
  window.ASKTXT = (m, d) => dialog(m, { cancel: "ரத்து", ok: "சேமி", input: d || "" });
  window.S6UI = { toast, dialog, nativeAlert };

  // =============== login screen ===============
  function enhanceLogin() {
    const lg = $i("lg"); if (!lg || lg._s6) return; lg._s6 = 1;
    const hero = doc.createElement("div"); hero.className = "s6lgh"; hero.id = "s6lgh";
    hero.innerHTML = `<img src="${T(() => LOGO, "icon-192.png")}" alt=""><b>Staff Panel</b><small>சுப்புலட்சுமி தங்க மாளிகை · புளியங்குடி</small>`;
    lg.before(hero);
    const h = lg.querySelector("h2"); if (h) { h.textContent = "உள்நுழைய"; h.insertAdjacentHTML("afterend", '<p class="s6lsub">Staff email, password போட்டு உள்ளே போங்க.</p><div class="s6lerr" id="s6lerr" role="alert"></div>'); }
    const se = $i("se"), sp = $i("sp");
    se.setAttribute("autocomplete", "username"); se.setAttribute("inputmode", "email"); sp.setAttribute("autocomplete", "current-password");
    const w = doc.createElement("div"); w.className = "s6pw s6"; sp.before(w); w.appendChild(sp);
    w.insertAdjacentHTML("beforeend", `<button type="button" aria-label="Password காட்ட">${svg("eye")}</button>`);
    w.querySelector("button").onclick = (e) => { const show = sp.type === "password"; sp.type = show ? "text" : "password"; e.currentTarget.innerHTML = svg(show ? "eyeoff" : "eye"); e.currentTarget.setAttribute("aria-label", show ? "Password மறைக்க" : "Password காட்ட"); };
    [se, sp].forEach((x) => x.addEventListener("keydown", (e) => { if (e.key === "Enter") window.login(); }));
  }
  window.login = async function () {
    const err = $i("s6lerr"), btn = doc.querySelector("#lg .btn");
    const show = (m) => { if (err) { err.textContent = m; err.classList.add("on"); } else alert(m); };
    if (err) err.classList.remove("on");
    const e = ($i("se").value || "").trim(), p = $i("sp").value || "";
    if (!e || !p) return show("Email, password இரண்டும் போடுங்க");
    if (btn) { btn.disabled = true; btn.textContent = "சரிபார்க்கிறது…"; }
    try {
      const { error } = await sb.auth.signInWithPassword({ email: e, password: p });
      if (error) {
        const m = String(error.message || "");
        return show(/invalid|credentials/i.test(m) ? "Email அல்லது password தவறு" : /banned/i.test(m) ? "இந்த கணக்கு நிறுத்தப்பட்டிருக்கு. Owner-ஐ அணுகவும்." : /fetch|network/i.test(m) ? "இணைய இணைப்பு இல்ல. மீண்டும் முயற்சிக்கவும்." : "Login முடியல: " + m);
      }
      show_();
    } finally { if (btn) { btn.disabled = false; btn.textContent = "Login"; } }
  };
  function show_() { T(() => show(), null); }

  // =============== shell ===============
  const PAGES = {
    dash: { t: "Dashboard", nav: "dash" },
    cust: { t: "Customers", nav: "cust", cards: ["Customers"] },
    notify: { t: "அறிவிப்பு", nav: "notify" },
    chat: { t: "கேள்விகள்", nav: "chat", cards: ["கேள்விகள்"] },
    nsend: { t: "Notification அனுப்பு", sub: 1, cards: ["Notification அனுப்பு"] },
    nposter: { t: "App Poster", sub: 1, cards: ["App திறக்கும்போது Poster"] },
    nstory: { t: "புதுசு என்ன", sub: 1, cards: ["புதுசு என்ன"] },
    ncat: { t: "நகை வகைகள்", sub: 1, cards: ["நகை வகைகள்"] },
    nnotice: { t: "அறிவிப்புகள்", sub: 1, cards: ["புதிய அறிவிப்பு"] },
    nlog: { t: "அனுப்பிய வரலாறு", sub: 1 },
    set: { t: "அமைப்பு", nav: "set" },
    pay: { t: "தவணை பதிவு", sub: 1, cards: ["தவணை பதிவு"] },
    rate: { t: "தங்கம் / வெள்ளி விலை", sub: 1, cards: ["இன்றைய 22K விலை", "பழைய விலை சேர்க்க"] },
    newcust: { t: "புதிய Customer", sub: 1, cards: ["புதிய Customer"] },
    remind: { t: "இந்த மாத நினைவூட்டல்", sub: 1, cards: ["இந்த மாத நினைவூட்டல்"] },
    refer: { t: "Refer & Earn", sub: 1, cards: ["Refer & Earn அமைப்பு", "Refer பரிசுகள்"] },
    schemes: { t: "திட்டங்கள்", sub: 1, cards: ["புதிய திட்டம் சேர்க்க"] },
    images: { t: "App படங்கள்", sub: 1, cards: ["கடை புகைப்படம்", "நகை படங்கள்", "Maroon பின்னணி படம்", "Header பின்னணி படம்", "திட்ட card படங்கள்", "Banner படங்கள்", "Onboarding படங்கள்"], cols: 1 },
    links: { t: "Social / Website links", sub: 1, cards: ["Social  Website links", "Social / Website links"] },
    staff: { t: "Staff & அனுமதிகள்", sub: 1 },
    more: { t: "மற்றவை", sub: 1 },
  };
  const NAV = [["dash", "Dashboard", "dash"], ["cust", "Customers", "cust"], ["chat", "கேள்விகள்", "chat"], ["notify", "அறிவிப்பு", "bell"], ["set", "அமைப்பு", "set"]];
  const norm = (t) => String(t || "").replace(/[^஀-௿A-Za-z0-9& ]/g, "").replace(/\s+/g, " ").trim();
  const cardBy = (t) => [...doc.querySelectorAll("#adm .card")].find((c) => { const h = c.querySelector(":scope>h2"); return h && norm(h.textContent).startsWith(norm(t)); });
  let built = false, cur = "dash", stack = [];
  const can = (p) => T(() => window.APRO.can(p), true);
  const role = () => T(() => window.APRO.role(), undefined);

  function build() {
    if (built) return; built = true;
    const adm = $i("adm");
    // top bar + menu
    const top = doc.createElement("div"); top.className = "s6top s6"; top.id = "s6top";
    top.innerHTML = `<button type="button" class="s6back" aria-label="பின் செல்ல">${svg("back")}</button><img class="lg" src="${T(() => LOGO, "icon-192.png")}" alt=""><h1 id="s6title">Dashboard</h1><button type="button" class="s6me" id="s6me" aria-haspopup="menu"><i>?</i><span>Staff</span></button><div class="s6menu" id="s6menu" role="menu"></div>`;
    adm.before(top);
    top.querySelector(".s6back").onclick = () => back();
    $i("s6me").onclick = (e) => { e.stopPropagation(); $i("s6menu").classList.toggle("on"); };
    doc.addEventListener("click", () => $i("s6menu").classList.remove("on"));
    // bottom nav
    const nav = doc.createElement("div"); nav.className = "s6nav s6"; nav.id = "s6nav"; nav.setAttribute("role", "navigation"); nav.setAttribute("aria-label", "முதன்மை");
    nav.innerHTML = NAV.map(([k, l, ic]) => `<button type="button" data-n="${k}"><span class="ic">${svg(ic)}</span>${l}<span class="s6dot" data-dot="${k}"></span></button>`).join("");
    nav.onclick = (e) => { const b = e.target.closest("[data-n]"); if (b) navTo(b.dataset.n); };
    doc.body.appendChild(nav);
    // sidebar
    const side = doc.createElement("div"); side.setAttribute("role", "navigation"); side.className = "s6side s6"; side.id = "s6side";
    const it = (k, l, ic) => `<button type="button" data-n="${k}">${svg(ic)}<span>${l}</span><span class="s6dot" data-dot="${k}"></span></button>`;
    side.innerHTML = `<div class="brand"><img src="${T(() => LOGO, "icon-192.png")}" alt=""><div><b>Staff Panel</b><small>சுப்புலட்சுமி தங்க மாளிகை</small></div></div>
      <h6>முதன்மை</h6>${it("dash", "Dashboard", "dash")}${it("cust", "Customers", "cust")}${it("pay", "தவணை பதிவு", "pay")}${it("newcust", "புதிய Customer", "add")}${it("remind", "நினைவூட்டல்", "remind")}
      <h6>தொடர்பு</h6>${it("chat", "கேள்விகள்", "chat")}${it("notify", "அறிவிப்பு & Poster", "bell")}${it("refer", "Refer & Earn", "gift")}
      <h6>அமைப்பு</h6>${it("rate", "தங்கம் / வெள்ளி விலை", "rate")}${it("schemes", "திட்டங்கள்", "scheme")}${it("images", "App படங்கள்", "img")}${it("links", "Links", "link")}${it("staff", "Staff & அனுமதிகள்", "staff")}${it("set", "எல்லா அமைப்பும்", "set")}`;
    side.onclick = (e) => { const b = e.target.closest("[data-n]"); if (b) navTo(b.dataset.n); };
    doc.body.appendChild(side);
    // pages
    const pages = doc.createElement("div"); pages.className = "s6pages"; pages.id = "s6pages";
    pages.innerHTML = Object.keys(PAGES).map((k) => `<section class="s6p${PAGES[k].cols ? " cols" : ""}" data-p="${k}" aria-label="${E(PAGES[k].t)}"></section>`).join("");
    adm.appendChild(pages);
    placeCards();
    buildDash(); buildCust(); buildSettings(); buildNotify(); buildPicker();
    navTo("dash", true);
    window.S6NAV = (k) => navTo(k);
    if (location.hash === "#chat") navTo("chat", true); // opened from a "new question" push
    try { history.replaceState({ s6base: 1 }, ""); } catch (e) {}
    armHistory();
    // the old tab switcher is still used by other code (staffTab) → route it here
    window.staffTab = (k) => navTo({ today: "dash", cust: "cust", notify: "notify", set: "set" }[k] || "dash", true);
    window.S6 = { go: navTo };
    // late cards (dashboard card, Excel card, Staff panel) are created after load → place them when they appear
    new MutationObserver(() => placeLate()).observe(adm, { childList: true, subtree: true });
    placeLate();
    whoAmI();
  }
  const P = (k) => doc.querySelector(`.s6p[data-p="${k}"]`);
  function placeCards() {
    Object.entries(PAGES).forEach(([k, p]) => (p.cards || []).forEach((t) => { const c = cardBy(t); if (c && !c._s6) { c._s6 = 1; P(k).appendChild(c); } }));
    const acb = $i("acb"); if (acb) P("cust").prepend(acb);
    const dsw = doc.querySelector("#adm .devsw"); if (dsw) { dsw._s6 = 1; P("images").prepend(dsw); }
    // anything left over stays reachable under "மற்றவை"
    [...doc.querySelectorAll("#adm .card")].forEach((c) => { if (!c._s6 && !c.closest(".s6p") && !c.closest("#lg") && c.id !== "lg") { c._s6 = 1; P("more").appendChild(c); } });
  }
  function placeLate() {
    const d = P("dash"); if (!d) return;
    const a5 = $i("adm5"); if (a5 && a5.parentNode !== d) { a5._s6 = 1; d.querySelector("#s6after") ? d.querySelector("#s6after").before(a5) : d.appendChild(a5); }
    const rq = cardBy("புதிய கோரிக்கைகள்"); if (rq && rq.parentNode !== d) { rq._s6 = 1; rq.classList.add("s6half"); d.appendChild(rq); }
    const col = cardBy("வசூல் விவரம்"); if (col && col.parentNode !== d) { col._s6 = 1; col.classList.add("s6half"); d.appendChild(col); }
    const xl = $i("apxl"); if (xl && xl.parentNode !== d) { xl._s6 = 1; d.appendChild(xl); }
    const st = $i("apstaff"); if (st && st.parentNode !== P("staff")) { st._s6 = 1; P("staff").appendChild(st); }
    const sb = doc.querySelector('#stabs [data-ap="staff"]'); if (sb) sb.style.display = "none";
  }

  // Parent of each sub page (used when it was opened directly, e.g. from the desktop sidebar)
  const PARENT = { nsend: "notify", nposter: "notify", nstory: "notify", ncat: "notify", nnotice: "notify", nlog: "notify", pay: "dash", newcust: "cust", remind: "cust", rate: "set", refer: "set", schemes: "set", images: "set", links: "set", staff: "set", more: "set" };
  function navTo(k, replace) {
    if (!PAGES[k]) k = "dash";
    if (k === "set") { const g = doc.querySelector('#stabs [data-g="set"]'); if (g) g.click(); } // keeps the 10-tap developer unlock working
    if (k === "staff") T(() => window.APRO.renderStaff(), null);
    if (k === "cust") renderCust();
    if (k === "pay") { buildPicker(); paintSel(); }
    if (k === "dash") renderDash();
    if (!replace && k !== cur) { if (PAGES[k].sub) stack.push(cur); else stack = []; }
    if (!PAGES[k].sub) stack = [];
    cur = k;
    closeOverlays();
    doc.querySelectorAll(".s6p").forEach((p) => p.classList.toggle("on", p.dataset.p === k));
    const navKey = PAGES[k].sub ? (stack.find((x) => !PAGES[x].sub) || PARENT[k] || "set") : k;
    doc.querySelectorAll("#s6nav [data-n]").forEach((b) => b.classList.toggle("on", b.dataset.n === navKey));
    doc.querySelectorAll("#s6side [data-n]").forEach((b) => b.classList.toggle("on", b.dataset.n === k));
    $i("s6title").textContent = PAGES[k].t;
    $i("s6top").classList.toggle("sub", !!PAGES[k].sub); // every sub page has a back button
    scrollTo({ top: 0 });
  }

  // ---------- one back logic for the top-bar back button AND the phone's back button ----------
  // order: open popup / sheet → sub page → its parent → Dashboard → (twice) leave the panel
  function openOverlay() {
    const cdv = $i("cdv"); if (cdv && !cdv.classList.contains("hide")) return () => T(() => closeCD(), cdv.classList.add("hide"));
    const dlg = doc.querySelector(".s6ov"); if (dlg) return () => (dlg.querySelector('[data-v="0"]') || dlg.querySelector('[data-v="1"]')).click();
    const sh = [...doc.querySelectorAll(".ap-ov")].pop(); if (sh) return () => sh.click();
    const wlc = $i("wlc"); if (wlc) return () => wlc.remove();
    const mn = $i("s6menu"); if (mn && mn.classList.contains("on")) return () => mn.classList.remove("on");
    return null;
  }
  function closeOverlays() { let n = 0, c; while ((c = openOverlay()) && n++ < 5) c(); }
  let exitArmed = 0;
  function back() {
    const ov = openOverlay(); if (ov) { ov(); return true; }
    if (PAGES[cur] && PAGES[cur].sub) { const p = stack.pop(); navTo(p || PARENT[cur] || "set", true); return true; }
    if (cur !== "dash") { navTo("dash", true); return true; }
    return false; // already on Dashboard
  }
  // keep one extra history entry so the phone's back button comes to us first
  function armHistory() { try { if (!(history.state && history.state.s6)) history.pushState({ s6: 1 }, ""); } catch (e) {} }
  window.addEventListener("popstate", () => {
    if (!built || $i("adm").classList.contains("hide")) return;
    if (back()) { armHistory(); return; }
    if (Date.now() - exitArmed < 2500) { try { history.back(); } catch (e) {} return; } // second back on Dashboard → leave
    exitArmed = Date.now(); toast("வெளியேற மீண்டும் back அழுத்துங்க"); armHistory();
  });

  // =============== who am I / role ===============
  const ROLE_TA = { super_admin: "உரிமையாளர்", admin: "நிர்வாகி", manager: "மேலாளர்", accounts: "கணக்காளர்", support: "உதவியாளர்" };
  async function whoAmI() {
    const s = await T(() => sb.auth.getSession(), null);
    const email = T(() => s.data.session.user.email, "") || "";
    const nm = email.split("@")[0];
    const paint = () => {
      const r = role();
      const me = $i("s6me"); me.querySelector("i").textContent = ini(nm); me.querySelector("span").textContent = r && ROLE_TA[r] ? ROLE_TA[r] : "Staff";
      $i("s6menu").innerHTML = `<div class="who"><b>${E(nm)}</b><small>${E(email)}</small>${r && ROLE_TA[r] ? `<br><small>${ROLE_TA[r]}</small>` : ""}</div>
        ${can("staff.manage") && r !== null ? `<button type="button" data-m="staff">${svg("staff")}Staff & அனுமதிகள்</button>` : ""}
        <button type="button" data-m="set">${svg("set")}அமைப்பு</button><button type="button" class="out" data-m="out">${svg("out")}வெளியேறு</button>`;
      $i("s6menu").onclick = (e) => { const b = e.target.closest("[data-m]"); if (!b) return; if (b.dataset.m === "out") out(); else navTo(b.dataset.m); };
      const h = $i("s6hello"); if (h) h.innerHTML = `<div class="av">${E(ini(nm))}</div><div><small>${greet()}</small><b>${E(nm)}</b><small>${r && ROLE_TA[r] ? ROLE_TA[r] + " · " : ""}${istNow().getUTCDate()} ${TAM[istNow().getUTCMonth()]} ${istNow().getUTCFullYear()}</small></div>`;
      // nav by permission
      const hideN = (k, hide) => doc.querySelectorAll(`[data-n="${k}"]`).forEach((b) => (b.style.display = hide ? "none" : ""));
      hideN("notify", !can("notify.send")); hideN("pay", !can("pay.write")); hideN("newcust", !(can("cust.write") || can("req.handle")));
      hideN("rate", !can("rate.write")); hideN("schemes", !can("settings.write")); hideN("images", !can("settings.write")); hideN("links", !can("settings.write")); hideN("refer", !can("settings.write"));
      hideN("staff", !(r === "super_admin")); hideN("remind", false);
      $i("s6nav").style.gridTemplateColumns = `repeat(${[...$i("s6nav").children].filter((b) => b.style.display !== "none").length},1fr)`;
      buildSettings(); buildQA();
    };
    paint();
    let n = 0; const t = setInterval(() => { n++; if (role() !== undefined || n > 30) { clearInterval(t); paint(); } }, 300);
  }
  const greet = () => { const h = istNow().getUTCHours(); return h < 12 ? "காலை வணக்கம்" : h < 16 ? "மதிய வணக்கம்" : h < 19 ? "மாலை வணக்கம்" : "இனிய இரவு"; };

  // =============== dashboard ===============
  function buildDash() {
    const d = P("dash");
    d.insertAdjacentHTML("afterbegin", `<div class="s6hello" id="s6hello"></div><div class="s6rate" id="s6rate"></div><div class="s6qa" id="s6qa"></div>
      <div class="card s6chart s6half" id="s6chart"></div><div class="card s6due s6half" id="s6due"></div><div id="s6after" style="display:none"></div>`);
    buildQA();
    d.addEventListener("click", (e) => { const b = e.target.closest("[data-go]"); if (b) navTo(b.dataset.go); });
  }
  function buildQA() {
    const q = $i("s6qa"); if (!q) return;
    const items = [["pay", "தவணை பதிவு", "pay", "pay.write"], ["newcust", "புதிய Customer", "add", "cust.write"], ["rate", "இன்றைய விலை", "rate", "rate.write"], ["xl", "Excel Report", "xl", "report"], ["remind", "நினைவூட்டல்", "remind", ""]];
    const ok = items.filter((x) => !x[3] || can(x[3]) || (x[3] === "cust.write" && can("req.handle"))).slice(0, 4);
    q.style.gridTemplateColumns = `repeat(${ok.length},1fr)`;
    q.innerHTML = ok.map(([k, l, ic]) => `<button type="button" data-q="${k}"><i>${svg(ic)}</i>${l}</button>`).join("");
    q.onclick = (e) => { const b = e.target.closest("[data-q]"); if (!b) return; if (b.dataset.q === "xl") { const x = $i("apxl"); if (x) x.scrollIntoView({ behavior: "smooth", block: "start" }); } else navTo(b.dataset.q); };
  }
  function custStat(c) {
    const ps = c.gold_payments || [], cym = istNow().toISOString().slice(0, 7);
    const silver = T(() => SILV(c.scheme), false), mo = T(() => MON(c.scheme), 11);
    const months = new Set(ps.map((p) => String(p.paid_on).slice(0, 7)));
    const n = silver ? months.size : ps.length;
    const paidNow = months.has(cym);
    const done = n >= mo && !(silver && paidNow);
    return { n, mo, paidNow, done, due: !done && !paidNow, np: c.pin_set === false, tot: ps.reduce((a, p) => a + (+p.amount || 0), 0), g: ps.reduce((a, p) => a + (+p.grams || 0), 0) };
  }
  function renderDash() {
    const C = window.CU;
    // rate strip (from the panel's own rate fields)
    const r = $i("s6rate");
    if (r) {
      const RT = window.RT || {}, today = istNow().toISOString().slice(0, 10), stale = RT.updated_on && String(RT.updated_on).slice(0, 10) !== today;
      const dt = RT.updated_on ? String(RT.updated_on).slice(0, 10).split("-").reverse().join("-") : "";
      r.innerHTML = `<div><small>22K தங்கம் · 1 கிராம்</small><b>${RT.rate22 ? "₹" + N(RT.rate22) : "—"}</b><em class="${stale ? "stale" : ""}">${RT.updated_on ? (stale ? "கடைசி விலை · " + dt : "இன்றைய விலை") : ""}</em></div>
        <div><small>வெள்ளி · 1 கிராம்</small><b>${RT.silver ? "₹" + (+RT.silver % 1 ? (+RT.silver).toFixed(2) : N(RT.silver)) : "—"}</b><em>${can("rate.write") ? '<button type="button" class="s6link" data-go="rate" style="padding:0">விலை மாற்ற ›</button>' : ""}</em></div>`;
    }
    if (!Array.isArray(C)) return;
    // 6-month collection chart (real payments only)
    const now = istNow(), months = [];
    for (let i = 5; i >= 0; i--) { const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - i, 1)); months.push(d.toISOString().slice(0, 7)); }
    const sum = Object.fromEntries(months.map((m) => [m, 0]));
    C.forEach((c) => (c.gold_payments || []).forEach((p) => { const k = String(p.paid_on).slice(0, 7); if (k in sum) sum[k] += +p.amount || 0; }));
    const max = Math.max(1, ...Object.values(sum)), tot6 = Object.values(sum).reduce((a, b) => a + b, 0);
    const short = (v) => (v >= 100000 ? (v / 100000).toFixed(v >= 1000000 ? 0 : 1) + "L" : v >= 1000 ? Math.round(v / 1000) + "K" : String(v));
    const ch = $i("s6chart");
    if (ch) ch.innerHTML = `<div class="hd2"><h3>மாத வசூல்</h3><small>கடந்த 6 மாதம் · ₹${N(tot6)}</small></div>
      <div class="s6bars" role="img" aria-label="கடந்த 6 மாத வசூல்">${months.map((m, i) => `<div class="b${i === 5 ? " cur" : ""}"><i style="height:${Math.max(2, Math.round((sum[m] / max) * 100))}%">${sum[m] ? `<span>₹${short(sum[m])}</span>` : ""}</i><small>${TAM[+m.slice(5) - 1]}</small></div>`).join("")}</div>`;
    // pending installments this month
    const due = C.map((c) => ({ c, s: custStat(c) })).filter((x) => x.s.due);
    const dl = $i("s6due");
    if (dl) dl.innerHTML = `<div class="hd2"><h3>இந்த மாதம் நிலுவை</h3><small>${due.length} பேர்</small></div>
      ${due.length ? due.slice(0, 5).map(({ c, s }) => `<div class="r"><b>${E(c.name)}<small>${E(T(() => SN[c.scheme], c.scheme))} · ${s.n + 1}/${s.mo} தவணை</small></b>${c.monthly_amount ? `<span>₹${N(c.monthly_amount)}</span>` : ""}</div>`).join("") : '<div class="s6empty"><b>எல்லாரும் கட்டியாச்சு ✨</b>இந்த மாசம் நிலுவை இல்ல.</div>'}
      ${due.length ? `<button type="button" class="s6link" data-go="remind">WhatsApp நினைவூட்டல் அனுப்ப ›</button>` : ""}`;
    // badges
    const rq = (window.RQ || []).length;
    doc.querySelectorAll('[data-dot="dash"]').forEach((x) => { x.textContent = rq; x.classList.toggle("on", rq > 0); });
  }

  // =============== customers & payments: Excel-style tables (search, filters, sort, pages) ===============
  // built for thousands of rows: only one page (50 rows) is drawn at a time
  let F = { q: "", st: "all", sch: "", sort: "name", dir: 1, page: 0 };
  let G = { q: "", per: "month", mode: "", sch: "", sort: "date", dir: -1, page: 0 };
  let VIEW = "c";
  const PER = 50;
  function buildCust() {
    const p = P("cust");
    p.insertAdjacentHTML("afterbegin", `<div class="s6seg s6" role="tablist"><button type="button" data-v="c" class="on">Customers</button><button type="button" data-v="p">தவணைகள் (எல்லாம்)</button></div>
      <div class="s6search s6"><div class="s6sbox">${svg("search")}<input id="s6q" type="search" placeholder="பெயர் / மொபைல் / code தேடுங்க" autocomplete="off" aria-label="தேடல்"></div>
      <div class="s6chips" id="s6chips"></div></div><div class="s6sum" id="s6count"></div><div class="s6grid" id="s6grid"></div><div class="s6pager" id="s6pager"></div>`);
    p.querySelector(".s6seg").onclick = (e) => { const b = e.target.closest("[data-v]"); if (!b) return; VIEW = b.dataset.v; p.querySelectorAll(".s6seg button").forEach((x) => x.classList.toggle("on", x === b)); $i("s6q").value = VIEW === "c" ? F.q : G.q; $i("s6q").placeholder = VIEW === "c" ? "பெயர் / மொபைல் / code தேடுங்க" : "பெயர் / மொபைல் / Ref தேடுங்க"; renderCust(); };
    let t; $i("s6q").addEventListener("input", (e) => { clearTimeout(t); t = setTimeout(() => { const v = e.target.value.trim().toLowerCase(); if (VIEW === "c") { F.q = v; F.page = 0; } else { G.q = v; G.page = 0; } renderCust(); }, 150); });
    $i("s6chips").addEventListener("click", (e) => { const b = e.target.closest("[data-st]"); if (!b) return; if (VIEW === "c") { F.st = b.dataset.st; F.page = 0; } else { G.per = b.dataset.st; G.page = 0; } renderCust(); });
    $i("s6chips").addEventListener("change", (e) => { const v = e.target.value; if (e.target.id === "s6sch") { if (VIEW === "c") { F.sch = v; F.page = 0; } else { G.sch = v; G.page = 0; } } if (e.target.id === "s6mode") { G.mode = v; G.page = 0; } renderCust(); });
    $i("s6grid").addEventListener("click", (e) => {
      const th = e.target.closest("th[data-k]");
      if (th) { const S = VIEW === "c" ? F : G; if (S.sort === th.dataset.k) S.dir *= -1; else { S.sort = th.dataset.k; S.dir = th.dataset.k === "name" || th.dataset.k === "sch" ? 1 : -1; } S.page = 0; renderCust(); return; }
      const pay = e.target.closest("[data-pay]"); if (pay) { payFor(pay.dataset.pay); return; }
    });
    $i("s6pager").addEventListener("click", (e) => { const b = e.target.closest("[data-pg]"); if (!b) return; const S = VIEW === "c" ? F : G; S.page += +b.dataset.pg; renderCust(); $i("s6grid").scrollTop = 0; P("cust").scrollIntoView({ block: "start" }); });
    // the old list container stays (its click handlers: data-cd / data-em / data-ac) — the table is drawn inside it
    const cl = $i("cl"); if (cl) $i("s6grid").appendChild(cl);
    const card = cardBy("Customers"); if (card) card.style.display = "none";
  }
  const istYM = (d) => new Date(new Date(d).getTime() + 330 * 60000).toISOString().slice(0, 7);
  const pdate = (d) => { const s = String(d || "").slice(0, 10); return s ? s.split("-").reverse().join("-") : ""; };
  const MODE = { cash: "பணம்", upi: "UPI", card: "Card", bank: "Bank", online: "Online (app)" };
  function sorter(S, getters) { const g = getters[S.sort] || getters.name; return (a, b) => { const x = g(a), y = g(b); return (typeof x === "number" && typeof y === "number" ? x - y : String(x).localeCompare(String(y), "ta")) * S.dir; }; }
  const th = (S, k, l, cls) => `<th data-k="${k}" class="${cls || ""}${S.sort === k ? " on" : ""}" scope="col">${l}${S.sort === k ? (S.dir > 0 ? " ▲" : " ▼") : ""}</th>`;
  function pager(S, total) {
    const pages = Math.max(1, Math.ceil(total / PER)); if (S.page >= pages) S.page = pages - 1; if (S.page < 0) S.page = 0;
    $i("s6pager").innerHTML = total > PER ? `<button type="button" data-pg="-1" ${S.page ? "" : "disabled"}>‹ முந்தைய</button><span>${S.page * PER + 1}–${Math.min(total, (S.page + 1) * PER)} / ${N(total)}</span><button type="button" data-pg="1" ${S.page < pages - 1 ? "" : "disabled"}>அடுத்த ›</button>` : "";
  }
  function renderCust() {
    const C = window.CU, cl = $i("cl"); if (!Array.isArray(C) || !cl) return;
    const keys = [...new Set(C.map((c) => c.scheme))];
    const schSel = (S) => `<select id="s6sch" aria-label="திட்டம்"><option value="">எல்லா திட்டமும்</option>${keys.map((k) => `<option value="${E(k)}"${S.sch === k ? " selected" : ""}>${E(T(() => SN[k], k))}</option>`).join("")}</select>`;
    cl.className = "s6"; cl.removeAttribute("style");
    if (VIEW === "c") {
      const rows = C.map((c) => ({ c, s: custStat(c), last: (c.gold_payments || []).reduce((m, p) => (String(p.paid_on) > m ? String(p.paid_on) : m), "") }));
      const cnt = { all: rows.length, due: rows.filter((r) => r.s.due).length, paid: rows.filter((r) => r.s.paidNow).length, done: rows.filter((r) => r.s.done).length, np: rows.filter((r) => r.s.np).length };
      $i("s6chips").innerHTML = [["all", "எல்லாம்"], ["due", "நிலுவை"], ["paid", "இந்த மாதம் கட்டியவர்"], ["np", "செயல்படுத்தல் பாக்கி"], ["done", "முடிந்தது"]]
        .map(([k, l]) => `<button type="button" data-st="${k}" class="${F.st === k ? "on" : ""}">${l}<i>${N(cnt[k])}</i></button>`).join("") + schSel(F);
      const q = F.q;
      const list = rows.filter(({ c, s }) => (F.st === "all" || (F.st === "due" && s.due) || (F.st === "paid" && s.paidNow) || (F.st === "done" && s.done) || (F.st === "np" && s.np))
        && (!F.sch || c.scheme === F.sch) && (!q || [c.name, c.mobile, c.ref_code, c.email].some((v) => String(v || "").toLowerCase().includes(q))));
      list.sort(sorter(F, { name: (r) => r.c.name || "", mob: (r) => r.c.mobile || "", sch: (r) => T(() => SN[r.c.scheme], r.c.scheme), amt: (r) => +r.c.monthly_amount || 0, n: (r) => r.s.n, tot: (r) => r.s.tot, g: (r) => r.s.g, last: (r) => r.last, st: (r) => (r.s.np ? 0 : r.s.due ? 1 : r.s.paidNow ? 2 : 3), join: (r) => String(r.c.start_date || "") }));
      const tot = list.reduce((a, r) => a + r.s.tot, 0);
      $i("s6count").innerHTML = `<b>${N(list.length)}</b> / ${N(rows.length)} customers · மொத்தம் <b>₹${N(tot)}</b>`;
      pager(F, list.length);
      const pageRows = list.slice(F.page * PER, F.page * PER + PER);
      const w = can("cust.write"), pw = can("pay.write");
      cl.innerHTML = list.length ? `<table class="s6t"><thead><tr>${th(F, "name", "பெயர்", "stk")}${th(F, "mob", "மொபைல்")}${th(F, "sch", "திட்டம்")}${th(F, "amt", "மாதத் தொகை", "r")}${th(F, "n", "தவணை", "r")}${th(F, "tot", "மொத்தம் ₹", "r")}${th(F, "g", "கிராம்", "r")}${th(F, "last", "கடைசி தவணை")}${th(F, "st", "இந்த மாதம்")}${th(F, "join", "சேர்ந்த நாள்")}<th scope="col">Code</th><th scope="col">செயல்</th></tr></thead><tbody>` +
        pageRows.map(({ c, s, last }) => {
          const st = s.np ? '<span class="s6badge np">செயல்படுத்தல் பாக்கி</span>' : s.done ? '<span class="s6badge done">முடிந்தது</span>' : s.paidNow ? '<span class="s6badge ok">கட்டியாச்சு</span>' : '<span class="s6badge due">நிலுவை</span>';
          return `<tr><td class="stk"><a data-cd="${E(c.id)}">${E(c.name)}</a></td><td>${E(c.mobile || "")}</td><td>${E(T(() => SN[c.scheme], c.scheme))}</td><td class="r">${c.monthly_amount ? N(c.monthly_amount) : "—"}</td><td class="r">${s.n}/${s.mo}</td><td class="r b">${N(s.tot)}</td><td class="r">${T(() => GR(c.scheme), false) ? s.g.toFixed(3) : "—"}</td><td>${pdate(last) || "—"}</td><td>${st}</td><td>${pdate(c.start_date) || "—"}</td><td>${E(c.ref_code || "")}</td>
            <td class="acts">${pw && !s.done ? `<a data-pay="${E(c.id)}">தவணை</a>` : ""}${w ? `<a data-ac="${E(c.id)}">🔑 code</a><a data-em="${E(c.id)}">✉️ Email</a>` : ""}</td></tr>`;
        }).join("") + `</tbody></table>` : `<div class="s6empty"><b>Customer யாரும் இல்ல</b>${q || F.st !== "all" || F.sch ? "தேடலை / filter-ஐ மாத்திப் பாருங்க." : "புதிய Customer சேர்த்ததும் இங்கே வருவாங்க."}</div>`;
    } else {
      const now = istNow().toISOString().slice(0, 7), lm = (() => { const d = istNow(); d.setUTCDate(1); d.setUTCMonth(d.getUTCMonth() - 1); return d.toISOString().slice(0, 7); })(), today = istNow().toISOString().slice(0, 10);
      const all = [];
      C.forEach((c) => (c.gold_payments || []).slice().sort((a, b) => String(a.paid_on).localeCompare(String(b.paid_on))).forEach((p, i) => all.push({ c, p, i: i + 1, day: new Date(new Date(p.paid_on).getTime() + 330 * 60000).toISOString().slice(0, 10) })));
      const inPer = (r) => G.per === "all" || (G.per === "today" && r.day === today) || (G.per === "month" && r.day.slice(0, 7) === now) || (G.per === "last" && r.day.slice(0, 7) === lm);
      const cnt = { today: all.filter((r) => r.day === today).length, month: all.filter((r) => r.day.slice(0, 7) === now).length, last: all.filter((r) => r.day.slice(0, 7) === lm).length, all: all.length };
      const modes = [...new Set(all.map((r) => r.p.mode || ""))];
      $i("s6chips").innerHTML = [["today", "இன்று"], ["month", "இந்த மாதம்"], ["last", "கடந்த மாதம்"], ["all", "எல்லாம்"]].map(([k, l]) => `<button type="button" data-st="${k}" class="${G.per === k ? "on" : ""}">${l}<i>${N(cnt[k])}</i></button>`).join("") +
        `<select id="s6mode" aria-label="முறை"><option value="">எல்லா முறையும்</option>${modes.map((m) => `<option value="${E(m)}"${G.mode === m ? " selected" : ""}>${E(MODE[m] || m || "பதியல")}</option>`).join("")}</select>` + schSel(G);
      const q = G.q;
      const list = all.filter((r) => inPer(r) && (!G.mode || (r.p.mode || "") === G.mode) && (!G.sch || r.c.scheme === G.sch) && (!q || [r.c.name, r.c.mobile, r.p.ref].some((v) => String(v || "").toLowerCase().includes(q))));
      list.sort(sorter(G, { date: (r) => String(r.p.paid_on), name: (r) => r.c.name || "", sch: (r) => T(() => SN[r.c.scheme], r.c.scheme), amt: (r) => +r.p.amount || 0, mode: (r) => r.p.mode || "", g: (r) => +r.p.grams || 0 }));
      const tot = list.reduce((a, r) => a + (+r.p.amount || 0), 0);
      $i("s6count").innerHTML = `<b>${N(list.length)}</b> தவணை · மொத்தம் <b>₹${N(tot)}</b>`;
      pager(G, list.length);
      const pageRows = list.slice(G.page * PER, G.page * PER + PER);
      cl.innerHTML = list.length ? `<table class="s6t"><thead><tr>${th(G, "date", "தேதி", "stk")}${th(G, "name", "பெயர்")}<th scope="col">மொபைல்</th>${th(G, "sch", "திட்டம்")}<th scope="col" class="r">தவணை எண்</th>${th(G, "amt", "தொகை ₹", "r")}${th(G, "mode", "முறை")}<th scope="col" class="r">விலை ₹/கி</th>${th(G, "g", "கிராம்", "r")}</tr></thead><tbody>` +
        pageRows.map((r) => `<tr><td class="stk">${pdate(r.day)}</td><td><a data-cd="${E(r.c.id)}">${E(r.c.name)}</a></td><td>${E(r.c.mobile || "")}</td><td>${E(T(() => SN[r.c.scheme], r.c.scheme))}</td><td class="r">${r.i}</td><td class="r b">${N(r.p.amount)}</td><td>${E(MODE[r.p.mode] || r.p.mode || "—")}</td><td class="r">${r.p.gold_rate ? N(r.p.gold_rate) : "—"}</td><td class="r">${r.p.grams ? (+r.p.grams).toFixed(3) : "—"}</td></tr>`).join("") +
        `</tbody></table>` : `<div class="s6empty"><b>இந்த காலத்தில் தவணை இல்ல</b>வேற காலம் / filter தேர்வு பண்ணுங்க.</div>`;
    }
  }

  // =============== payment entry: searchable customer picker (works with thousands of customers) ===============
  function buildPicker() {
    const pc = $i("pc"); if (!pc || $i("s6pick")) return;
    pc.style.display = "none";
    pc.insertAdjacentHTML("beforebegin", `<div class="s6pick s6" id="s6pick"><div class="s6sbox">${svg("search")}<input id="s6pq" type="search" placeholder="Customer பெயர் / மொபைல் தேடுங்க" autocomplete="off" aria-label="Customer தேடல்"></div><div class="s6pres" id="s6pres" role="listbox"></div><div class="s6psel" id="s6psel"></div></div>`);
    const res = $i("s6pres"), inp = $i("s6pq");
    inp.addEventListener("input", () => {
      const q = inp.value.trim().toLowerCase(), C = window.CU || [];
      if (!q) { res.innerHTML = ""; return; }
      const hits = C.filter((c) => [c.name, c.mobile, c.ref_code].some((v) => String(v || "").toLowerCase().includes(q))).slice(0, 8);
      res.innerHTML = hits.length ? hits.map((c) => { const s = custStat(c); return `<button type="button" role="option" data-pick="${E(c.id)}"><b>${E(c.name)}</b><small>${E(c.mobile || "")} · ${E(T(() => SN[c.scheme], c.scheme))} · ${s.n}/${s.mo}${s.paidNow ? " · இந்த மாதம் கட்டியாச்சு" : ""}</small></button>`; }).join("") : '<div class="s6empty" style="padding:12px">யாரும் இல்ல</div>';
    });
    res.addEventListener("click", (e) => { const b = e.target.closest("[data-pick]"); if (b) choose(b.dataset.pick); });
    $i("s6psel").addEventListener("click", (e) => { if (e.target.closest("[data-unpick]")) { pc.value = ""; pc.dispatchEvent(new Event("change")); paintSel(); inp.focus(); } });
    paintSel();
  }
  function choose(id) { const pc = $i("pc"); if (!pc) return; if (![...pc.options].some((o) => o.value === String(id))) return; pc.value = String(id); pc.dispatchEvent(new Event("change")); $i("s6pq").value = ""; $i("s6pres").innerHTML = ""; paintSel(); const a = $i("pa"); if (a) a.focus(); }
  function paintSel() {
    const el = $i("s6psel"), pc = $i("pc"); if (!el || !pc) return;
    const c = (window.CU || []).find((x) => String(x.id) === String(pc.value));
    $i("s6pq").parentElement.style.display = c ? "none" : "";
    el.innerHTML = c ? `<div class="s6c"><div class="av">${E(ini(c.name))}</div><div class="m"><b>${E(c.name)}</b><small>${E(c.mobile || "")} · ${E(T(() => SN[c.scheme], c.scheme))}</small></div><button type="button" class="s6link" data-unpick="1">மாற்ற</button></div>` : "";
  }
  function payFor(id) { navTo("pay"); buildPicker(); choose(id); }

  // =============== notifications hub: one box per job ===============
  function buildNotify() {
    const p = P("notify"); if (!p || $i("s6nhub")) return;
    // history gets its own page
    const log = $i("pnlog");
    if (log) { const c = doc.createElement("div"); c.className = "card"; c.innerHTML = "<h2>அனுப்பிய notification-கள்</h2>"; const lbl = log.previousElementSibling; if (lbl && /அனுப்பியவை/.test(lbl.textContent)) lbl.remove(); c.appendChild(log); P("nlog").appendChild(c); }
    p.insertAdjacentHTML("afterbegin", `<div class="s6hub s6" id="s6nhub">
      <button type="button" data-go="nsend"><i>${svg("bell")}</i><b>Notification அனுப்பு</b><small>Customers phone-க்கு உடனே</small></button>
      ${can("settings.write") ? `<button type="button" data-go="nposter"><i>${svg("poster")}</i><b>App Poster</b><small>App திறந்ததும் வரும் படம்</small></button>` : ""}
      ${can("settings.write") ? `<button type="button" data-go="nstory"><i>${svg("poster")}</i><b>புதுசு என்ன</b><small>App மேல வட்ட stories</small></button>` : ""}
      ${can("settings.write") ? `<button type="button" data-go="ncat"><i>${svg("img")}</i><b>நகை வகைகள்</b><small>Swipe கட்டங்கள் + கடை photo</small></button>` : ""}
      <button type="button" data-go="nnotice"><i>${svg("more")}</i><b>அறிவிப்புகள்</b><small>App-ல உள்ள அறிவிப்பு பட்டியல்</small></button>
      <button type="button" data-go="nlog"><i>${svg("remind")}</i><b>அனுப்பிய வரலாறு</b><small>பார்க்க / நீக்க</small></button></div>`);
    p.onclick = (e) => { const b = e.target.closest("[data-go]"); if (b) navTo(b.dataset.go); };
  }

  // re-render after every data load (load() rebuilds #cl with the old markup)
  if (typeof window.load === "function") {
    const orig = window.load;
    window.load = async function () { const r = await orig.apply(this, arguments); renderCust(); renderDash(); T(() => paintSel(), null); return r; }; // eslint-disable-line no-global-assign
  }

  // =============== settings home ===============
  function buildSettings() {
    const p = P("set"); if (!p) return;
    const dev = $i("adm") && $i("adm").classList.contains("devun");
    const row = (k, ic, t, s) => `<button type="button" data-go="${k}"><i>${svg(ic)}</i><span><b>${t}</b><small>${s}</small></span><span class="chev">${svg("chev")}</span></button>`;
    const grp = (h, items) => { const v = items.filter(Boolean); return v.length ? `<h4>${h}</h4><div class="s6list">${v.join("")}</div>` : ""; };
    const more = P("more") && P("more").children.length;
    p.innerHTML = `<div class="s6set">` +
      grp("விலை & திட்டங்கள்", [can("rate.write") && row("rate", "rate", "தங்கம் / வெள்ளி விலை", "இன்றைய விலை, பழைய விலை (graph)"), can("settings.write") && row("schemes", "scheme", "திட்டங்கள்", "புதிய திட்டம் சேர்க்க / மாற்ற")]) +
      grp("Customers", [(can("cust.write") || can("req.handle")) && row("newcust", "add", "புதிய Customer", "நேரடியா சேர்க்க"), row("remind", "remind", "இந்த மாத நினைவூட்டல்", "நிலுவை உள்ளவர்களுக்கு WhatsApp"), can("settings.write") && row("refer", "gift", "Refer & Earn", "அமைப்பு, பரிசுகள்")]) +
      grp("App", [can("notify.send") && row("notify", "bell", "அறிவிப்பு & Poster", "Notification, poster, அறிவிப்புகள்"), can("settings.write") && row("links", "link", "Social / Website links", "Instagram, Facebook, YouTube"), can("settings.write") && dev && row("images", "img", "App படங்கள்", "Developer mode: கடை, banner, onboarding படங்கள்")]) +
      grp("என் கணக்கு", [row("mypw", "key", "என் Password மாற்ற", "பழைய password போட்டு புது password வைக்க")]) +
      grp("நிர்வாகம்", [role() === "super_admin" && row("staff", "staff", "Staff & அனுமதிகள்", "Staff சேர்க்க, role, password"), more && row("more", "more", "மற்றவை", "மற்ற அமைப்புகள்")]) +
      `<p class="s6count" style="text-align:center;margin-top:18px">${dev ? "Developer mode திறந்திருக்கு" : "அமைப்பு tab-ஐ 10 தடவை தட்டினா Developer mode"}</p></div>`;
    p.onclick = (e) => { const b = e.target.closest("[data-go]"); if (!b) return; if (b.dataset.go === "mypw") changePw(); else navTo(b.dataset.go); };
  }

  // =============== my password (any staff; standard Supabase Auth, no table / RLS change) ===============
  function changePw() {
    const ov = doc.createElement("div"); ov.className = "s6ov s6"; ov.setAttribute("role", "dialog"); ov.setAttribute("aria-modal", "true"); ov.setAttribute("aria-label", "என் Password மாற்ற");
    ov.innerHTML = `<div class="s6dlg s6mypw"><div class="ic">${svg("key")}</div><h3>என் Password மாற்ற</h3>
      <label for="s6pw0">இப்போதைய password</label><input type="password" id="s6pw0" autocomplete="current-password">
      <label for="s6pw1">புது password <small>(குறைஞ்சது 8 எழுத்து)</small></label><input type="password" id="s6pw1" autocomplete="new-password">
      <label for="s6pw2">புது password மறுபடி</label><input type="password" id="s6pw2" autocomplete="new-password">
      <label class="sh"><input type="checkbox" id="s6pwsh"> Password காட்டு</label>
      <p class="er" id="s6pwer" role="alert"></p>
      <div class="bt"><button type="button" class="o" data-v="0">ரத்து</button><button type="button" data-v="1">மாற்று</button></div></div>`;
    const q = (id) => ov.querySelector("#" + id);
    const close = () => { ov.classList.remove("on"); setTimeout(() => ov.remove(), 180); };
    const err = (m) => { q("s6pwer").textContent = m; };
    q("s6pwsh").onchange = (e) => ["s6pw0", "s6pw1", "s6pw2"].forEach((i) => (q(i).type = e.target.checked ? "text" : "password"));
    let busy = false;
    ov.addEventListener("click", async (e) => {
      const b = e.target.closest("[data-v]");
      if (!b) { if (e.target === ov) close(); return; }
      if (b.dataset.v === "0") return close();
      if (busy) return;
      const old = q("s6pw0").value, p1 = q("s6pw1").value, p2 = q("s6pw2").value;
      if (!old) return err("இப்போதைய password போடுங்க");
      if (p1.length < 8) return err("புது password குறைஞ்சது 8 எழுத்து இருக்கணும்");
      if (p1 !== p2) return err("புது password ரெண்டும் ஒண்ணா இல்ல");
      if (p1 === old) return err("புது password பழையதை விட வேற மாதிரி இருக்கணும்");
      busy = true; b.textContent = "மாற்றுகிறது…"; err("");
      try {
        const u = await sb.auth.getUser();
        const email = u && u.data && u.data.user && u.data.user.email;
        if (!email) throw new Error("login");
        const chk = await sb.auth.signInWithPassword({ email, password: old });
        if (chk.error) { err("இப்போதைய password தவறு"); return; }
        const r = await sb.auth.updateUser({ password: p1 });
        if (r.error) { err("மாற்ற முடியல: " + r.error.message); return; }
        close(); toast("Password மாற்றியாச்சு ✅", "ok");
      } catch (x) {
        err("மாற்ற முடியல. Internet / login சரிபார்த்து மறுபடி முயற்சிக்கவும்.");
      } finally { busy = false; if (doc.body.contains(ov)) b.textContent = "மாற்று"; }
    });
    ov.addEventListener("keydown", (e) => { if (e.key === "Escape") close(); });
    doc.body.appendChild(ov); requestAnimationFrame(() => ov.classList.add("on"));
    setTimeout(() => q("s6pw0").focus(), 60);
  }
  // developer unlock flips a class on #adm → refresh the settings list
  new MutationObserver(() => built && buildSettings()).observe($i("adm") || doc.body, { attributes: true, attributeFilter: ["class"] });

  // =============== start ===============
  function boot() {
    const adm = $i("adm"); if (!adm) return;
    enhanceLogin();
    const loggedIn = !adm.classList.contains("hide");
    doc.body.classList.toggle("s6login", !loggedIn);
    ["s6top", "s6nav", "s6side"].forEach((id) => { const el = $i(id); if (el) el.style.display = loggedIn ? "" : "none"; });
    const h = $i("s6lgh"); if (h) h.style.display = loggedIn ? "none" : "";
    if (loggedIn) { build(); whoAmI(); renderDash(); renderCust(); }
  }
  const adm = $i("adm");
  if (adm) new MutationObserver(boot).observe(adm, { attributes: true, attributeFilter: ["class"] });
  boot();
  // RQ (requests) and RT (rate) change asynchronously → light refresh
  setInterval(() => { if (built && cur === "dash") renderDash(); }, 4000);
})();

/* ===== Notification history: delete one entry / clear all (history only — sent notifications cannot be recalled) ===== */
(function () {
  if (!document.documentElement.hasAttribute("data-s6") || typeof window.loadPushLog !== "function") return;
  const E = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  window.loadPushLog = async function () { // eslint-disable-line no-global-assign
    const box = document.getElementById("pnlog"); if (!box) return;
    const { data, error } = await sb.from("gold_push_log").select("*").order("created_at", { ascending: false }).limit(30);
    if (error) { box.innerHTML = '<div class="mut">' + E(error.message) + "</div>"; return; }
    const rows = data || [];
    box.innerHTML = rows.length
      ? rows.map((r) => `<div class="s6log"><div class="t"><b>${E(r.title)}</b><small>${E(new Date(r.created_at).toLocaleString("ta-IN"))} · ✅ ${r.sent} · ❌ ${r.failed}${String(r.by_email || "") === "auto" ? " · தானியங்கி" : ""}</small></div><button type="button" class="x" data-pl="${E(r.id)}" aria-label="நீக்கு">நீக்கு</button></div>`).join("") +
        `<button type="button" class="s6link s6clr" data-plall="1">எல்லா வரலாற்றையும் அழி</button>`
      : '<div class="mut">இன்னும் இல்ல</div>';
  };
  document.addEventListener("click", async (e) => {
    const one = e.target.closest("[data-pl]"), all = e.target.closest("[data-plall]");
    if (!one && !all) return;
    const ok = await window.ASK(one ? "இந்த notification-ஐ வரலாற்றில் இருந்து நீக்கவா?\n(ஏற்கனவே phone-களுக்கு போனது திரும்ப வராது.)" : "எல்லா notification வரலாற்றையும் அழிக்கவா?\n(ஏற்கனவே phone-களுக்கு போனது திரும்ப வராது.)");
    if (!ok) return;
    const q = sb.from("gold_push_log").delete();
    const { error } = one ? await q.eq("id", one.dataset.pl) : await q.gt("id", 0);
    if (error) alert("நீக்க முடியல: " + error.message); else alert(one ? "நீக்கியாச்சு ✅" : "வரலாறு அழிக்கப்பட்டது ✅");
    window.loadPushLog();
  });
  if (document.getElementById("pnlog")) window.loadPushLog();
})();
