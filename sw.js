// சுப்புலட்சுமி தங்க மாளிகை · Service Worker — Push Notification மட்டும் (cache எதுவும் இல்ல)
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));

// ===== இணையம் இல்லாதபோது: browser பிழைப் பக்கத்துக்குப் பதில் தமிழ் "இணையம் இல்லை" பக்கம் =====
// Cache எதுவும் இல்லை: இந்தப் பக்கம் இங்கேயே உருவாகிறது, பழைய தொகை / payment நிலை எதையும் காட்டாது.
// Customer பக்கங்களுக்கு மட்டும் (/staff-ஐ தொடாது).
const OFFLINE_HTML = `<!DOCTYPE html><html lang="ta"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#092A63"><title>இணையம் இல்லை</title>
<style>body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;background:#FBF8F1;color:#092A63;font-family:"Noto Sans Tamil",system-ui,sans-serif;text-align:center;padding:24px;box-sizing:border-box}
svg{width:64px;height:64px;margin-bottom:10px}h1{margin:0 0 6px;font-size:20px}p{margin:0 0 18px;color:#5B6475;font-size:15px;line-height:1.6}
button{padding:12px 28px;border:0;border-radius:12px;background:#092A63;color:#fff;font:700 16px/1.3 inherit;font-family:inherit}</style></head>
<body><main><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="M2 8.8a15 15 0 0 1 20 0M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0"/><circle cx="12" cy="19.5" r="1"/><path d="M3 3l18 18"/></svg>
<h1>இணையம் இல்லை</h1><p>உங்க mobile data / Wi-Fi-ஐ சரிபார்த்து மீண்டும் முயற்சி செய்யுங்க.<br>No internet connection.</p>
<button type="button" onclick="location.reload()">மீண்டும் முயற்சி</button></main>
<script>addEventListener("online",function(){location.reload()})</script></body></html>`;

self.addEventListener("fetch", (e) => {
  const r = e.request;
  if (r.mode !== "navigate" || r.method !== "GET") return;
  const u = new URL(r.url);
  if (u.origin !== self.location.origin || /^\/staff/i.test(u.pathname)) return;
  e.respondWith((async () => {
    try {
      return await fetch(r);
    } catch (_) {
      return new Response(OFFLINE_HTML, { status: 503, headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" } });
    }
  })());
});

// App ஐகான் மேல எண் (iPhone / computer-ல; Android launcher notification எண்ணிக்கையை தானே காட்டும்)
async function setBadge() {
  try {
    const n = (await self.registration.getNotifications()).length;
    if (self.navigator && "setAppBadge" in self.navigator) {
      if (n) await self.navigator.setAppBadge(n); else await self.navigator.clearAppBadge();
    }
  } catch (_) {}
}

self.addEventListener("push", (e) => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (_) { d = { title: e.data ? e.data.text() : "" }; }
  const title = d.title || "சுப்புலட்சுமி தங்க மாளிகை";
  const opt = {
    body: d.body || "",
    icon: "icon-192.png",
    badge: "badge-96.png",
    data: { url: d.url || "/" },
    tag: d.tag || undefined,
  };
  if (d.image) opt.image = d.image;
  e.waitUntil(self.registration.showNotification(title, opt).then(setBadge));
});

self.addEventListener("notificationclose", (e) => e.waitUntil(setBadge()));

self.addEventListener("notificationclick", (e) => {
  e.notification.close();
  e.waitUntil(setBadge());
  const path = (e.notification.data && e.notification.data.url) || "/";
  const target = new URL(path, self.registration.scope).href;
  e.waitUntil((async () => {
    const all = await self.clients.matchAll({ type: "window", includeUncontrolled: true });
    for (const c of all) {
      if (c.url.startsWith(self.registration.scope)) {
        await c.focus();
        c.postMessage({ type: "open", hash: new URL(target).hash });
        return;
      }
    }
    await self.clients.openWindow(target);
  })());
});
