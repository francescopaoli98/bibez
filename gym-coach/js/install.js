// Invito a installare l'app sulla schermata Home: su Android un tocco, su iPhone la guida in 3 passi.
import { h, openSheet, closeSheet, toast, icon } from './ui.js';

const KEY = 'gymcoach:installDismiss';
const standalone = () => window.matchMedia?.('(display-mode: standalone)').matches || navigator.standalone === true;
const dismissed = () => Date.now() - (+localStorage.getItem(KEY) || 0) < 7 * 864e5;       // dopo "Non ora": se ne riparla tra 7 giorni
const root = () => document.getElementById('install-root');
let deferred = null, shown = false;

function hide() { root()?.replaceChildren(); shown = false; }
function later() { try { localStorage.setItem(KEY, String(Date.now())); } catch {} hide(); }

const SHARE = '<path d="M12 15V3"/><path d="M8 7l4-4 4 4"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>';
function iosSheet() {
  const share = h('span', { class: 'share' }); share.innerHTML = `<svg viewBox="0 0 24 24">${SHARE}</svg>`;
  openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Aggiungi alla Home'),
    h('div', { class: 'steps3' },
      h('div', { class: 'step' }, h('span', { class: 'n' }, '1'), h('span', { class: 'grow' }, 'Tocca ', h('b', {}, 'Condividi'), ' in basso'), share),
      h('div', { class: 'step' }, h('span', { class: 'n' }, '2'), h('span', { class: 'grow' }, 'Scorri e scegli ', h('b', {}, 'Aggiungi alla schermata Home')), h('span', { class: 'share dim' }, '＋')),
      h('div', { class: 'step' }, h('span', { class: 'n' }, '3'), h('span', { class: 'grow' }, 'Tocca ', h('b', {}, 'Aggiungi'), ': l\'icona di Gym Coach compare sulla Home'), h('img', { src: 'icons/icon-192.png', alt: '', style: 'width:40px;height:40px;border-radius:11px' }))),
    h('button', { class: 'btn big block', onclick: () => { closeSheet(); later(); } }, 'Ho capito')));
}

function render(kind) {
  if (shown || dismissed() || standalone() || !root()) return;
  if (document.body.classList.contains('locked')) return void setTimeout(() => render(kind), 1500);   // non sopra la schermata di accesso
  shown = true;
  const android = kind === 'android';
  root().replaceChildren(h('div', { class: 'ibanner', role: 'dialog', 'aria-label': 'Installa l\'app' },
    h('img', { src: 'icons/icon-192.png', alt: '' }),
    h('div', { class: 'grow' },
      h('b', {}, android ? 'Installa Gym Coach' : 'Aggiungi Gym Coach alla Home'),
      h('span', { class: 'muted small' }, android ? 'Si apre come un\'app, direttamente dalla schermata Home del telefono.' : 'Su iPhone si fa da Safari in tre passi.'),
      h('div', { class: 'row', style: 'margin-top:10px;gap:8px' },
        h('button', { class: 'btn small', onclick: async () => {
          if (!android) return iosSheet();
          try { deferred.prompt(); const r = await deferred.userChoice; if (r.outcome === 'accepted') hide(); else later(); } catch { later(); }
        } }, android ? 'Installa' : 'Come si fa'),
        h('button', { class: 'btn ghost small', onclick: later }, 'Non ora'))),
    h('button', { class: 'x', 'aria-label': 'Chiudi', onclick: later }, '✕')));
}

export function initInstall() {
  if (standalone()) return;
  window.addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); deferred = e; render('android'); });
  window.addEventListener('appinstalled', () => { hide(); toast('Installata! Trovi l\'icona sulla schermata Home 🎉', 5000); });
  const ua = navigator.userAgent;
  const ios = /iphone|ipad|ipod/i.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (ios && /safari/i.test(ua) && !/crios|fxios|edgios/i.test(ua)) setTimeout(() => render('ios'), 1500);     // Safari non ha un tasto "installa": spieghiamo i passi
}
