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
// Le mattine della settimana (lun-dom) in cui hai fatto il risveglio, e la serie di giorni di fila
export function weekMornings() {
  const mon = new Date(); mon.setHours(0, 0, 0, 0); mon.setDate(mon.getDate() - ((mon.getDay() + 6) % 7));
  return Array.from({ length: 7 }, (_, i) => { const d = new Date(mon); d.setDate(mon.getDate() + i); return (S.risvegli || []).some(r => new Date(r.date).toDateString() === d.toDateString()); });
}
export function mattineDiFila() {
  const days = new Set((S.risvegli || []).map(r => new Date(r.date).toDateString()));
  let d = new Date(), c = 0;
  if (!days.has(d.toDateString())) d.setDate(d.getDate() - 1);
  while (days.has(d.toDateString())) { c++; d.setDate(d.getDate() - 1); }
  return c;
}
// Mappa del corpo: una figura semplice con la zona che stai muovendo illuminata
const ZONES = {
  anche: '<ellipse cx="50" cy="104" rx="22" ry="12"/>', spalle: '<ellipse cx="50" cy="52" rx="32" ry="9"/>', schiena: '<ellipse cx="50" cy="80" rx="14" ry="24"/>',
  caviglie: '<ellipse cx="39" cy="186" rx="8" ry="6"/><ellipse cx="61" cy="186" rx="8" ry="6"/>', gambe: '<rect x="31" y="122" width="16" height="56" rx="8"/><rect x="53" y="122" width="16" height="56" rx="8"/>',
  petto: '<ellipse cx="50" cy="64" rx="19" ry="11"/>', braccia: '<rect x="12" y="48" width="12" height="56" rx="6"/><rect x="76" y="48" width="12" height="56" rx="6"/>', collo: '<ellipse cx="50" cy="38" rx="8" ry="7"/>',
};
export const ZONE_NAME = { anche: 'Anche', spalle: 'Spalle', schiena: 'Schiena', caviglie: 'Caviglie', gambe: 'Gambe', petto: 'Petto', braccia: 'Braccia', collo: 'Collo' };
export function bodyMap(zona) {
  const s = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); s.setAttribute('viewBox', '0 0 100 200'); s.setAttribute('class', 'bodymap');
  s.innerHTML = `<g fill="#33281c" stroke="#5a4528" stroke-width="1.5"><circle cx="50" cy="22" r="13"/><rect x="43" y="34" width="14" height="10" rx="4"/><rect x="26" y="44" width="48" height="62" rx="20"/><rect x="12" y="46" width="12" height="62" rx="6"/><rect x="76" y="46" width="12" height="62" rx="6"/><rect x="30" y="104" width="18" height="86" rx="8"/><rect x="52" y="104" width="18" height="86" rx="8"/></g><g class="zon" fill="#fbbf24" opacity=".9">${ZONES[zona] || ''}</g>`;
  return s;
}
export const SOLE = 'img/risveglio-sole.webp';
export const doneToday = () => (S.risvegli || []).some(r => new Date(r.date).toDateString() === new Date().toDateString());

// Il player: un esercizio alla volta, con il conto alla rovescia
export function viewRisveglio({ render, go, keepAwake, presetId, dayIdx }) {
  const list = routine(presetId), n = list.length;
  if (!n) return go('#/oggi');
  keepAwake?.(true); document.body.classList.add('alba');
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
    const zones = [...new Set(list.map(x => ZONE_NAME[x.zona]).filter(Boolean))].map(z => z.toLowerCase());
    const zTxt = zones.length > 1 ? zones.slice(0, -1).join(', ') + ' e ' + zones.at(-1) : zones[0] || 'i muscoli';
    const mins = Math.max(1, Math.round((Date.now() - t0) / 60000)), fila = mattineDiFila();
    document.body.classList.add('alba');
    render(h('div', { class: 'rvend' }, h('div', { class: 'sunbig' }, h('img', { src: SOLE, alt: '' })),
      h('h1', { class: 'tt3' }, 'Risveglio fatto!'), h('p', { class: 'sub3' }, `Hai svegliato ${zTxt}.`),
      h('div', { class: 'chips3' }, h('span', {}, tile('risveglio', 12), `${fila} ${fila === 1 ? 'mattina' : 'mattine'} di fila`), h('span', {}, tile('tempo', 12), `${mins} min`)),
      h('div', { class: 'dots3' }, weekMornings().map((on, k) => h('i', { class: on ? 'on' : '' }, 'LMMGVSD'[k]))),
      next && h('div', { class: 'next3' }, h('b', {}, 'Ora tocca all\'allenamento'), h('span', {}, 'Muscoli caldi: parti più facile.')),
      h('button', { class: 'btn big block rvgo' + (next ? ' green' : ''), onclick: () => { if (next) go('#/allenamento/' + dayIdx); else go('#/oggi'); } }, next ? '▶ Vai all\'allenamento' : 'Torna a Oggi')));
    confetti();
  }
  function step(k) {
    stop(); i = k; if (i >= n) return finish();
    const ex = list[i]; left = ex.sec; paused = false;
    segs.forEach((s, j) => s.className = j < i ? 'd' : j === i ? 'c' : '');
    const ring = h('div', { class: 'ringbox' }, h('div', { html: `<svg width="190" height="190" viewBox="0 0 190 190"><circle cx="95" cy="95" r="80" fill="none" stroke="rgba(255,255,255,.12)" stroke-width="14"/><circle class="rfg" cx="95" cy="95" r="80" fill="none" stroke="url(#rsg)" stroke-width="14" stroke-linecap="round" stroke-dasharray="${C}" stroke-dashoffset="0" transform="rotate(-90 95 95)"/><defs><linearGradient id="rsg"><stop offset="0" stop-color="#fde047"/><stop offset="1" stop-color="#fb923c"/></linearGradient></defs></svg>` }));
    const num = h('b', {}, left), rn = h('div', { class: 'rn' }, num, h('span', {}, 'secondi')); ring.append(rn);
    const fg = ring.querySelector('.rfg');
    const pauseBtn = h('button', { class: 'cb2', 'aria-label': 'Pausa', 'data-nosound': '', onclick: () => { paused = !paused; pauseBtn.replaceChildren(icon(paused ? 'play' : 'pause')); } }, icon('pause'));
    const nextEx = list[i + 1];
    body.replaceChildren(
      h('div', { class: 'ex rvex' }, h('div', { class: 'anim' }, ex.img.map(src => h('img', { src, alt: ex.nome }))),
        h('div', { class: 'zonebox' }, bodyMap(ex.zona), h('span', {}, 'Zona', h('b', {}, ZONE_NAME[ex.zona] || '')))),
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

// "Perché farlo": benefici in parole semplici, come funziona e un avviso di prudenza
export function viewRisveglioInfo({ render, go, presetId }) {
  document.body.classList.add('alba');
  const B = [['risveglio', 'Meno rigidità', 'Allenta il corpo dopo la notte o dopo ore da seduto'], ['palestra', 'Più mobilità', 'Anche, spalle e schiena si muovono meglio'], ['kcal', 'Più energia', 'Il movimento leggero sveglia anche la testa'],
    ['schiena', 'Postura migliore', 'Aiuta a stare dritto dopo la scrivania o il divano'], ['fatto', 'Allenamento più facile', 'Se lo fai prima, parti già caldo']];
  const n = routine(presetId).length;
  render(
    h('div', { class: 'row between' }, h('div', {}, h('div', { class: 'eyebrow', style: 'text-transform:none' }, 'Perché farlo'), h('h1', { class: 'hi' }, 'Risveglio muscolare')),
      h('button', { class: 'btn ghost small', onclick: () => go('#/oggi') }, '‹ Indietro')),
    h('div', { class: 'whyhero' }, h('img', { class: 'whysun', src: SOLE, alt: '' }),
      h('p', {}, 'Dopo ore di sonno e di sedia i muscoli sono "freddi". Pochi minuti di movimento lento li ', h('b', {}, 'scaldano e li svegliano'), ', prima di qualsiasi altra cosa.')),
    B.map(([ic, t, s]) => h('div', { class: 'ben' }, tile(ic, 16), h('div', {}, h('b', {}, t), h('span', {}, s)))),
    h('div', { class: 'how' }, tile('tempo', 12), h('span', {}, h('b', {}, 'Come funziona: '), `${n} esercizi a tempo, 20-40 secondi ciascuno. Vai piano, respira, non forzare mai.`)),
    h('div', { style: 'height:120px' }),
    h('div', { class: 'startday alba-cta' }, h('button', { class: 'btn big block rvbtn', onclick: () => { S.seen = { ...(S.seen || {}), risveglio: true }; save(); go('#/risveglio/' + presetId); } }, 'Comincia'),
      h('p', { class: 'disc' }, 'Non sostituisce una visita: se senti dolore, fermati e parlane con un medico.')));
}
