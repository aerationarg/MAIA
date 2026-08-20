const CACHE = 'maia-v5';
const ASSETS = [
  './',
  './index.html',
  'https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  // Solo intervenir en pedidos al propio origen (los assets estáticos de la app:
  // index.html, íconos, manifest). Cualquier llamada a una API externa (Supabase,
  // Microsoft Graph, Anthropic, MSAL, etc.) va siempre directo a la red — nunca se
  // debe cachear ni devolver una respuesta vieja para datos que cambian en vivo
  // (notificaciones, hallazgos, aprobaciones de NP, etc.).
  if (new URL(e.request.url).origin !== self.location.origin) return;
  if (e.request.method !== 'GET') return;

  // HTML/navegación: siempre pedir a la red primero para no quedar pegado
  // a una versión vieja cacheada; si no hay red, cae al cache offline.
  if (e.request.mode === 'navigate' || e.request.url.endsWith('.html')) {
    e.respondWith(
      fetch(e.request).then(resp => {
        const clone = resp.clone();
        caches.open(CACHE).then(c => c.put(e.request, clone));
        return resp;
      }).catch(() => caches.match(e.request))
    );
    return;
  }

  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(resp => {
        if (resp.ok) {
          const clone = resp.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return resp;
      }).catch(() => cached);
    })
  );
});
