// சுப்புலட்சுமி தங்க மாளிகை · Service Worker — Push Notification மட்டும் (cache எதுவும் இல்ல)
self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));

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
