// Suoni e vibrazione leggeri (sintetizzati, nessun file). Si possono spegnere in Impostazioni → Aspetto.
import { getTheme } from './theme.js';

let ctx = null;
function ac() {
  try { ctx = ctx || new (window.AudioContext || window.webkitAudioContext)(); if (ctx.state === 'suspended') ctx.resume(); } catch {}
  return ctx;
}
function tone(freq, at, dur, { type = 'sine', gain = 0.05, to } = {}) {
  const c = ac(); if (!c) return;
  const t0 = c.currentTime + at, o = c.createOscillator(), g = c.createGain();
  o.type = type; o.frequency.setValueAtTime(freq, t0); if (to) o.frequency.exponentialRampToValueAtTime(to, t0 + dur);
  g.gain.setValueAtTime(0.0001, t0); g.gain.exponentialRampToValueAtTime(gain, t0 + 0.008); g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  o.connect(g); g.connect(c.destination); o.start(t0); o.stop(t0 + dur + 0.02);
}
const SOUNDS = {
  tap:     () => tone(1000, 0, 0.035, { gain: 0.03 }),
  check:   () => { tone(660, 0, 0.08, { gain: 0.06 }); tone(990, 0.07, 0.12, { gain: 0.06 }); },
  send:    () => tone(520, 0, 0.12, { gain: 0.05, to: 820 }),
  receive: () => { tone(740, 0, 0.1, { gain: 0.04 }); tone(990, 0.09, 0.14, { gain: 0.035 }); },
  error:   () => tone(220, 0, 0.18, { type: 'triangle', gain: 0.06, to: 150 }),
  done:    () => { tone(880, 0, 0.12, { gain: 0.07 }); tone(1175, 0.13, 0.2, { gain: 0.07 }); },
  win:     () => [523, 659, 784, 1047].forEach((f, i) => tone(f, i * 0.09, 0.22, { gain: 0.06 })),
  switch:  () => tone(700, 0, 0.06, { gain: 0.04, to: 900 }),
};
export function play(name) { if (getTheme().sound) { try { SOUNDS[name]?.(); } catch {} } }
// Vibrazione: Android usa l'API ufficiale. Su iPhone (Safari 17.4 o più recente) Apple non la offre, ma
// il passaggio di un interruttore nativo (<input switch>) dà un piccolo "tic": lo usiamo come scorciatoia.
const isIOS = () => /iphone|ipad|ipod/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
function iosTap() {
  const label = document.createElement('label');
  label.setAttribute('aria-hidden', 'true'); label.style.display = 'none';
  const input = document.createElement('input'); input.type = 'checkbox'; input.setAttribute('switch', '');
  label.append(input); document.head.append(label);
  label.click();                                           // deve avvenire dentro il tocco dell'utente
  label.remove();
}
export function buzz(ms = 8) {
  if (!getTheme().haptics) return;
  try {
    if (typeof navigator.vibrate === 'function') navigator.vibrate(Array.isArray(ms) ? ms : Math.max(ms, 14));
    else if (isIOS()) iosTap();                              // un solo "tic" (su iPhone non si possono fare schemi più lunghi)
  } catch {}
}

// Tocco su qualsiasi elemento "cliccabile" = piccolo suono (data-nosound lo esclude: ha già un suono suo)
const TAPPABLE = 'button, a.tab, a.iconbtn, .chip, .seg-b, .ex-item, .ex-card, .linkcard, summary, .opt';
export function initSound() {
  document.addEventListener('pointerdown', () => ac(), { once: true, capture: true });
  document.addEventListener('click', (e) => {
    const t = e.target.closest?.(TAPPABLE);
    if (!t || t.disabled || t.closest('[data-nosound]')) return;
    play('tap'); buzz(6);
  }, true);
}
