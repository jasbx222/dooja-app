'use strict';
// Dooja PWA service worker: offline shell + cached static assets. API calls always go to the network.
const VERSION = 'dooja-pwa-v1';
const SCOPE = new URL(self.registration.scope);
const CORE = ['./', 'index.html', 'flutter.js', 'flutter_bootstrap.js', 'main.dart.js', 'manifest.json', 'favicon.png', 'icons/Icon-192.png', 'icons/Icon-512.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(VERSION).then((c) => c.addAll(CORE.map((p) => new URL(p, SCOPE).toString()))).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) if (key !== VERSION) await caches.delete(key);
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== SCOPE.origin || !url.pathname.startsWith(SCOPE.pathname)) return;
  if (req.mode === 'navigate') {
    event.respondWith(fetch(req).then((res) => {
      const copy = res.clone();
      caches.open(VERSION).then((c) => c.put(new URL('index.html', SCOPE).toString(), copy));
      return res;
    }).catch(() => caches.match(new URL('index.html', SCOPE).toString())));
    return;
  }
  event.respondWith(caches.open(VERSION).then(async (cache) => {
    const cached = await cache.match(req);
    const network = fetch(req).then((res) => {
      if (res.ok) cache.put(req, res.clone());
      return res;
    }).catch(() => cached);
    return cached || network;
  }));
});
