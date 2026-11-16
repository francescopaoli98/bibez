// Risveglio muscolare: routine di mobilità/stretching del mattino (a tempo), senza attrezzi.
// Può essere fatta da sola (carta in Oggi) oppure prima di un giorno di allenamento.
import { S, save } from './store.js';
import { h, icon, tile } from './ui.js';
import { play, buzz } from './sound.js';
import { confetti } from './fx.js';

let DATA = { items: [], presets: [] };
export async function loadRisveglio() { try { DATA = await (await fetch('data/risveglio.json')).json(); } catch {} }
export const risvegliPresets = () => DATA.presets;
export const risvegliItem = (id) => DATA.items.find(i => i.id === id);
export function routine(presetId) {
  const p = DATA.presets.find(x => x.id === presetId) || DATA.presets[0];
  return p ? p.items.map(risvegliItem).filter(Boolean) : [];
}
export const routineSec = (presetId) => routine(presetId).reduce((a, i) => a + i.sec + 4, 0);     // +4 s di cambio posizione
export const routineMin = (presetId) => Math.max(1, Math.round(routineSec(presetId) / 60));
// "Scelto dal coach": gambe → anche e caviglie; altrimenti parte alta → spalle e schiena
export function autoPreset(groups) {
  if (groups.includes('gambe')) return 'gambe';
  if (groups.some(g => ['petto', 'schiena', 'spalle', 'braccia'].includes(g))) return 'alto';
  return 'completo';
}
export const presetName = (id) => DATA.presets.find(p => p.id === id)?.nome || 'Risveglio';
export const defaultPreset = () => S.settings.risvegliPreset || 'completo';
export const doneToday = () => (S.risvegli || []).some(r => new Date(r.date).toDateString() === new Date().toDateString());

// Il player: un esercizio alla volta, con il conto alla rovescia
export function viewRisveglio({ render, go, keepAwake, presetId, dayIdx }) {
  const list = routine(presetId), n = list.length;
  if (!n) return go('#/oggi');
  keepAwake?.(true);
  let i = 0, left = 0, paused = false, timer = null, t0 = Date.now();
  const C = 2 * Math.PI * 80;
  const stop = () => { clearInterval(timer); timer = null; };
  const leave = () => { stop(); keepAwake?.(false); };
  const segs = list.map(() => h('i', {}));
  const body = h('div', { class: 'rvbody' });

  function finish() {
    leave(); play('win'); buzz([60, 40, 60]);
    S.risvegli = [...(S.risvegli || []), { date: new Date().toISOString(), preset: presetId, sec: Math.round((Date.now() - t0) / 1000) }].slice(-200); save();
    const next = dayIdx != null && dayIdx !== '' && !isNaN(+dayIdx);
    render(h('div', { class: 'rvend' }, h('div', { class: 'rvsun' }, tile('risveglio', 40)),
      h('h1', { class: 'hi' }, 'Risveglio fatto!'), h('p', { class: 'muted' }, next ? 'Muscoli svegli. Ora tocca all\'allenamento.' : 'Muscoli svegli: buona giornata!'),
      h('button', { class: 'btn big block rvgo', onclick: () => { if (next) go('#/allenamento/' + dayIdx); else go('#/oggi'); } }, next ? '▶ Vai all\'allenamento' : 'Torna a Oggi')));
    confetti();
  }
  function step(k) {
    stop(); i = k; if (i >= n) return finish();
    const ex = list[i]; left = ex.sec; paused = false;
    segs.forEach((s, j) => s.className = j < i ? 'd' : j === i ? 'c' : '');
    const ring = h('div', { class: 'ringbox' }, h('div', { html: `<svg width="190" height="190" viewBox="0 0 190 190"><circle cx="95" cy="95" r="80" fill="none" stroke="rgba(255,255,255,.12)" stroke-width="14"/><circle class="rfg" cx="95" cy="95" r="80" fill="none" stroke="#fde047" stroke-width="14" stroke-linecap="round" stroke-dasharray="${C}" stroke-dashoffset="0" transform="rotate(-90 95 95)"/></svg>` }));
    const num = h('b', {}, left), rn = h('div', { class: 'rn' }, num, h('span', {}, 'secondi')); ring.append(rn);
    const fg = ring.querySelector('.rfg');
    const pauseBtn = h('button', { class: 'cb2', 'aria-label': 'Pausa', 'data-nosound': '', onclick: () => { paused = !paused; pauseBtn.replaceChildren(icon(paused ? 'play' : 'pause')); } }, icon('pause'));
    const nextEx = list[i + 1];
    body.replaceChildren(
      h('div', { class: 'ex rvex' }, h('div', { class: 'anim' }, ex.img.map(src => h('img', { src, alt: ex.nome })))),
      h('div', { class: 'en' }, ex.nome),
      h('div', { class: 'chips2' }, h('span', {}, ex.muscoli), h('span', {}, 'Senza attrezzi')),
      ring,
      h('div', { class: 'tip3' }, ex.passi.slice(0, 2).join(' ')),
      h('p', { class: 'muted small center' }, ex.consiglio),
      h('div', { class: 'ctl' },
        h('button', { class: 'cb2', 'aria-label': 'Indietro', 'data-nosound': '', disabled: i === 0, onclick: () => step(i - 1) }, icon('chevl')),
        h('button', { class: 'btn rvnext', 'data-nosound': '', onclick: () => step(i + 1) }, nextEx ? `Prossimo: ${nextEx.nome} ›` : 'Finisci ›'), pauseBtn));
    document.querySelector('.rvsub') && (document.querySelector('.rvsub').textContent = `Esercizio ${i + 1} di ${n}`);
    play('check'); buzz(10);
    let last = Date.now();
    timer = setInterval(() => {
      const now = Date.now(), dt = (now - last) / 1000; last = now;
      if (paused) return;
      left -= dt; const sh = Math.max(0, Math.ceil(left)); num.textContent = sh;
      fg.style.strokeDashoffset = C * (1 - Math.max(0, left) / ex.sec);
      if (left <= 0) { play('done'); buzz([120, 60, 120]); step(i + 1); }
    }, 200);
  }
  render(
    h('div', { class: 'sticky-head' }, h('div', {}, h('div', { class: 'muted small rvsub' }, `Esercizio 1 di ${n}`), h('h3', {}, presetName(presetId))),
      h('button', { class: 'btn ghost small', onclick: () => { leave(); go(dayIdx != null && dayIdx !== '' ? '#/scheda' : '#/oggi'); } }, 'Esci')),
    h('div', { class: 'rvsegs' }, segs), body, h('div', { style: 'height:96px' }));
  step(0);
}
