// Service worker: l'app funziona anche offline (palestra senza campo!).
const VERSION = 'v32';
const CORE = ['./', 'index.html', 'css/fonts.css', 'css/style.css', 'css/theme.css', 'js/app.js', 'js/store.js', 'js/ui.js', 'js/ai.js', 'js/plans.js', 'js/training.js', 'js/coach.js', 'js/nutrition.js', 'js/progress.js', 'js/reminders.js', 'js/lock.js', 'js/account.js', 'js/theme.js', 'js/sound.js', 'js/fx.js', 'js/chats.js', 'js/bio.js', 'js/install.js', 'js/salute.js', 'js/voice.js',
  'data/exercises.json', 'manifest.webmanifest', 'icons/icon.svg', 'icons/icon-192.png', 'icons/apple-touch-icon.png',
  'fonts/HTxwL3I-JCGChYJ8VI-L6OO_au7B46r2z3bWuYMBYro.woff2', 'fonts/HTxwL3I-JCGChYJ8VI-L6OO_au7B47b1z3bWuYMBYro.woff2', 'fonts/HTxwL3I-JCGChYJ8VI-L6OO_au7B4873z3bWuYMBYro.woff2', 'fonts/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa1ZL7W0Q5nw.woff2'];

self.addEventListener('install', (e) => {
  e.waitUntil((async () => {
    const c = await caches.open(VERSION);
    await c.addAll(CORE);
    try {                                   // scarica in anticipo anche le immagini
      const lib = await (await fetch('data/exercises.json')).json();
      await Promise.all(lib.flatMap(x => x.img).map(u => c.add(u).catch(() => {})));
    } catch {}
    self.skipWaiting();
  })());
});

self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    for (const k of await caches.keys()) if (k !== VERSION) await caches.delete(k);
    await self.clients.claim();
  })());
});

// cache-first per i file dell'app; richieste esterne (Gemini) mai toccate
self.addEventListener('fetch', (e) => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || u.origin !== location.origin) return;
  e.respondWith((async () => {
    const hit = await caches.match(e.request, { ignoreSearch: true });
    if (hit) { fetch(e.request).then(r => r.ok && caches.open(VERSION).then(c => c.put(e.request, r))).catch(() => {}); return hit; }
    try { return await fetch(e.request); } catch { return caches.match('index.html'); }
  })());
});
