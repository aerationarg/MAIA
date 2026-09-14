const CACHE = 'maia-v15';
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

// ── Web Push: mostrar la notificación aunque MAIA esté cerrada ──
self.addEventListener('push', e => {
  let data = {};
  try { data = e.data ? e.data.json() : {}; } catch(err) {}
  const title = data.title || 'MAIA';
  const options = {
    body: data.body || '',
    icon: 'icons/icon-192.png',
    badge: 'icons/icon-192.png',
    data: { seccion: data.seccion || '' }
  };
  e.waitUntil((async () => {
    await self.registration.showNotification(title, options);
    // Numerito en el ícono, aunque la app esté completamente cerrada.
    if (self.navigator && 'setAppBadge' in self.navigator && typeof data.badge === 'number') {
      try { await self.navigator.setAppBadge(data.badge); } catch(err) {}
    }
  })());
});

// Tocar la notificación: enfocar MAIA si ya está abierta, o abrirla; y llevar
// al panel correspondiente avisándole a la pestaña abierta por postMessage.
self.addEventListener('notificationclick', e => {
  e.notification.close();
  const seccion = e.notification.data?.seccion || '';
  e.waitUntil((async () => {
    const allClients = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const c of allClients) {
      if ('focus' in c) {
        await c.focus();
        if (seccion) c.postMessage({ type: 'push-nav', seccion });
        return;
      }
    }
    if (clients.openWindow) await clients.openWindow('./');
  })());
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
