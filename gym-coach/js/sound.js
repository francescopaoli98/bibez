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
export function buzz(ms = 8) { if (getTheme().haptics) { try { navigator.vibrate?.(ms); } catch {} } }

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
