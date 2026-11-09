// Pagina Progressi: peso corporeo, forza per esercizio, record e storico. Grafici in SVG, senza librerie.
import { S, save } from './store.js';
import { h, toast, icon, tile as ttile } from './ui.js';

const NS = 'http://www.w3.org/2000/svg';
const sv = (tag, attrs = {}) => { const e = document.createElementNS(NS, tag); for (const [k, v] of Object.entries(attrs)) e.setAttribute(k, v); return e; };
const GIORNI = ['dom', 'lun', 'mar', 'mer', 'gio', 'ven', 'sab'];
const fmtDay = (iso) => { const d = new Date(iso); return `${GIORNI[d.getDay()]} ${d.getDate()}/${d.getMonth() + 1}`; };
const short = (iso) => { const d = new Date(iso); return `${d.getDate()}/${d.getMonth() + 1}`; };
const num = (v) => { const s = Math.abs(v) >= 100 ? v.toFixed(0) : v.toFixed(1); return s.replace(/\.0$/, ''); };
// Forza stimata (Epley): peso × (1 + ripetizioni/30). A corpo libero (0 kg) conta le ripetizioni.
const strength = (s) => (s.kg > 0 ? s.kg * (1 + s.reps / 30) : s.reps);

/* ---------- grafico a linea: 1 serie, tooltip al tocco, tabella alternativa ---------- */
function lineChart(points, { unit = '', title = '' } = {}) {
  const box = h('div', { class: 'chart' });
  if (!points.length) { box.append(h('p', { class: 'muted small' }, 'Ancora nessun dato.')); return box; }
  const W = 320, H = 150, L = 36, R = 16, T = 18, B = 26;
  let lo = Math.min(...points.map(p => p.y)), hi = Math.max(...points.map(p => p.y));
  if (hi - lo < 1e-9) { lo -= 1; hi += 1; }
  const pad = (hi - lo) * 0.18; lo -= pad; hi += pad;
  const n = points.length;
  const X = (i) => (n === 1 ? (L + W - R) / 2 : L + (W - L - R) * i / (n - 1));
  const Y = (v) => T + (H - T - B) * (1 - (v - lo) / (hi - lo));

  const svg = sv('svg', { viewBox: `0 0 ${W} ${H}`, role: 'img', 'aria-label': title });
  const gid = 'ga' + Math.random().toString(36).slice(2, 7);
  const defs = sv('defs'); const lg = sv('linearGradient', { id: gid, x1: 0, x2: 0, y1: 0, y2: 1 });
  lg.append(sv('stop', { offset: 0, 'stop-color': 'var(--accent)', 'stop-opacity': .35 }), sv('stop', { offset: 1, 'stop-color': 'var(--accent)', 'stop-opacity': 0 }));
  defs.append(lg); svg.append(defs);
  [0, 0.5, 1].forEach(t => {
    const v = lo + (hi - lo) * t, yy = Y(v);
    svg.append(sv('line', { x1: L, x2: W - R, y1: yy, y2: yy, class: 'grid' }));
    const tx = sv('text', { x: L - 6, y: yy + 3.5, class: 'axis', 'text-anchor': 'end' }); tx.textContent = num(v); svg.append(tx);
  });
  const lab = (i, anchor) => { const t = sv('text', { x: X(i), y: H - 6, class: 'axis', 'text-anchor': anchor }); t.textContent = short(points[i].iso); svg.append(t); };
  if (n === 1) lab(0, 'middle'); else { lab(0, 'start'); lab(n - 1, 'end'); }
  if (n > 1) {                                           // curva morbida + area sfumata sotto
    let d = `M${X(0).toFixed(1)} ${Y(points[0].y).toFixed(1)}`;
    for (let i = 1; i < n; i++) { const mx = (X(i - 1) + X(i)) / 2; d += ` C${mx.toFixed(1)} ${Y(points[i - 1].y).toFixed(1)} ${mx.toFixed(1)} ${Y(points[i].y).toFixed(1)} ${X(i).toFixed(1)} ${Y(points[i].y).toFixed(1)}`; }
    svg.append(sv('path', { class: 'area', d: `${d} L${X(n - 1).toFixed(1)} ${H - B} L${X(0).toFixed(1)} ${H - B}Z`, fill: `url(#${gid})` }), sv('path', { class: 'line', d }));
  }
  points.forEach((p, i) => svg.append(sv('circle', { class: 'dot', cx: X(i), cy: Y(p.y), r: 4 })));
  const last = points[n - 1];
  const below = n > 1 && points[n - 2].y > last.y;      // la linea arriva dall'alto: etichetta sotto il punto
  const lt = sv('text', { x: X(n - 1), y: Y(last.y) + (below ? 17 : -9), class: 'val', 'text-anchor': n === 1 ? 'middle' : 'end' }); lt.textContent = num(last.y) + (unit ? ' ' + unit : ''); svg.append(lt);

  // hover / tocco: linea guida + tooltip
  const cross = sv('line', { class: 'cross', y1: T, y2: H - B, x1: 0, x2: 0, visibility: 'hidden' });
  const ring = sv('circle', { class: 'dot', r: 6, visibility: 'hidden' });
  const hit = sv('rect', { x: L, y: 0, width: W - L - R, height: H, fill: 'transparent' });
  svg.append(cross, ring, hit);
  const tip = h('div', { class: 'tip', hidden: true });
  const show = (ev) => {
    const r = svg.getBoundingClientRect();
    const xs = (ev.clientX - r.left) / r.width * W;
    let k = 0; for (let i = 1; i < n; i++) if (Math.abs(X(i) - xs) < Math.abs(X(k) - xs)) k = i;
    const p = points[k];
    cross.setAttribute('x1', X(k)); cross.setAttribute('x2', X(k)); cross.setAttribute('visibility', 'visible');
    ring.setAttribute('cx', X(k)); ring.setAttribute('cy', Y(p.y)); ring.setAttribute('visibility', 'visible');
    tip.hidden = false; tip.style.left = Math.min(88, Math.max(12, X(k) / W * 100)) + '%';
    tip.replaceChildren(h('b', {}, `${num(p.y)}${unit ? ' ' + unit : ''}`), h('span', {}, ` · ${fmtDay(p.iso)}`), p.note && h('div', {}, p.note));
  };
  const hide = () => { cross.setAttribute('visibility', 'hidden'); ring.setAttribute('visibility', 'hidden'); tip.hidden = true; };
  hit.addEventListener('pointermove', show); hit.addEventListener('pointerdown', show);
  hit.addEventListener('pointerleave', hide);

  const table = h('details', { class: 'tbl' }, h('summary', { class: 'muted small' }, 'Mostra come tabella'),
    h('table', {}, points.slice().reverse().map(p => h('tr', {}, h('td', {}, fmtDay(p.iso)), h('td', {}, `${num(p.y)}${unit ? ' ' + unit : ''}`), h('td', { class: 'muted' }, p.note || '')))));
  box.append(svg, tip, table);
  return box;
}

/* ---------- calcoli ---------- */
function weekStreak() {
  if (!S.history.length) return 0;
  const key = (d) => { const x = new Date(d); x.setHours(0, 0, 0, 0); x.setDate(x.getDate() - ((x.getDay() + 6) % 7)); return x.getTime(); };
  const weeks = new Set(S.history.map(w => key(w.date)));
  let k = key(new Date()), c = 0;
  if (!weeks.has(k)) k -= 7 * 864e5;
  while (weeks.has(k)) { c++; k -= 7 * 864e5; }
  return c;
}

function perExercise() {
  const m = new Map();
  for (const w of S.history) for (const e of w.exercises) {
    if (!e.sets.length) continue;
    const best = e.sets.reduce((a, s) => (strength(s) > strength(a) ? s : a), e.sets[0]);
    const arr = m.get(e.id) || []; arr.push({ iso: w.date, best, sets: e.sets }); m.set(e.id, arr);
  }
  return m;
}

/* ---------- pagina ---------- */
let sel = null;
export function viewProgressi({ render, LIB, go }) {
  const name = (id) => LIB.find(e => e.id === id)?.nome || id;
  const per = perExercise();
  const ids = [...per.keys()].sort((a, b) => per.get(b).length - per.get(a).length);
  if (!sel || !per.has(sel)) sel = ids[0] || null;

  const tons = Math.round(S.history.reduce((a, w) => a + (w.volume || 0), 0) / 100) / 10;
  const tile = (b, s) => h('div', { class: 'stat' }, h('b', {}, b), h('span', {}, s));

  // peso corporeo
  const pesi = (S.pesi || []).slice().sort((a, b) => a.date.localeCompare(b.date));
  const inp = h('input', { type: 'number', inputmode: 'decimal', step: '0.1', placeholder: S.profile.peso ? String(S.profile.peso) : 'kg' });
  const addPeso = () => {
    const kg = parseFloat(String(inp.value).replace(',', '.'));
    if (!(kg >= 30 && kg <= 300)) return toast('Inserisci un peso valido (kg)');
    const today = new Date().toDateString();
    S.pesi = (S.pesi || []).filter(p => new Date(p.date).toDateString() !== today);
    S.pesi.push({ date: new Date().toISOString(), kg });
    S.profile.peso = kg; save(); toast('Peso registrato ✅'); viewProgressi({ render, LIB, go });
  };
  const delta = pesi.length > 1 ? pesi[pesi.length - 1].kg - pesi[0].kg : null;

  const exChips = h('div', { class: 'chips scroll' }, ids.map(id =>
    h('button', { class: 'chip' + (id === sel ? ' on' : ''), onclick: () => { sel = id; viewProgressi({ render, LIB, go }); } }, name(id))));
  const series = sel ? per.get(sel) : [];
  const bw = series.length && series.every(s => s.best.kg === 0);

  const records = ids.slice(0, 8).map(id => {
    const b = per.get(id).reduce((a, s) => (strength(s.best) > strength(a.best) ? s : a));
    return h('div', { class: 'row between rec' }, h('span', {}, name(id)),
      h('span', { class: 'muted small' }, `${b.best.kg ? b.best.kg + ' kg × ' : ''}${b.best.reps}${b.best.kg ? '' : ' rip.'} · ${short(b.iso)}`));
  });

  const hist = S.history.slice(-15).reverse().map(w => h('details', { class: 'hist' },
    h('summary', {}, h('div', {}, h('b', {}, w.dayName), h('div', { class: 'muted small' }, `${fmtDay(w.date)} · ${w.sets} serie · ${w.durata} min${w.kcal ? ' · ~' + w.kcal + ' kcal' : ''}${w.luogo === 'casa' ? ' · 🏠' : ''}`))),
    h('div', { class: 'stack small', style: 'padding:8px 0 4px' }, w.exercises.map(e => h('div', {}, h('b', {}, name(e.id)), h('div', { class: 'muted' }, e.sets.map(s => s.kg ? `${s.kg}×${s.reps}` : `${s.reps} rip.`).join('  ·  ')))))));

  // serie di settimane, allenamenti della settimana, record appena battuto
  const streak = weekStreak(), target = S.profile.giorni || 3;
  const mon = new Date(); mon.setHours(0, 0, 0, 0); mon.setDate(mon.getDate() - ((mon.getDay() + 6) % 7));
  const wkDone = S.history.filter(w => new Date(w.date) >= mon).length, left = Math.max(0, target - wkDone);
  const ore = S.history.reduce((a, w) => a + (w.durata || 0), 0), oreTxt = ore >= 60 ? `${Math.floor(ore / 60)} h ${String(ore % 60).padStart(2, '0')}` : `${ore} min`;
  const tonsTxt = String(tons).replace('.', ',') + ' t';
  const lastDate = S.history.at(-1)?.date;
  const newRec = ids.map(id => { const s = per.get(id); const l = s.at(-1); return s.length > 1 && l.iso === lastDate && strength(l.best) > Math.max(...s.slice(0, -1).map(x => strength(x.best))) ? { id, best: l.best } : null; }).find(Boolean);
  const loseGoal = S.profile.obiettivo !== 'massa';
  const dGood = delta != null && delta !== 0 && (loseGoal ? delta < 0 : delta > 0);

  render(
    h('div', { class: 'row between' }, h('div', {}, h('div', { class: 'eyebrow', style: 'text-transform:none' }, streak ? `Settimana ${streak} di fila` : 'Si comincia!'), h('h1', { class: 'hi' }, 'I tuoi progressi')),
      h('a', { class: 'iconbtn', href: '#/profilo', 'aria-label': 'Impostazioni' }, icon('gear'))),
    h('div', { class: 'streak' }, ttile('kcal', 24),
      h('div', {}, h('b', {}, streak ? `${streak} ${streak === 1 ? 'settimana' : 'settimane'} di fila!` : 'Il primo allenamento è il più bello'),
        h('span', {}, !S.history.length ? 'Fai il primo e iniziamo a contare.' : left ? `Ancora ${left} ${left === 1 ? 'allenamento' : 'allenamenti'} e chiudi questa settimana` : 'Settimana completata, bravo! 🎉'))),
    h('div', { class: 'stats3' },
      h('div', { class: 'st' }, ttile('oggi', 16), h('b', {}, S.history.length), h('small', {}, 'Allenamenti')),
      h('div', { class: 'st' }, ttile('tempo', 16), h('b', {}, oreTxt), h('small', {}, 'Tempo')),
      h('div', { class: 'st' }, ttile('palestra', 16), h('b', {}, tonsTxt), h('small', {}, 'Sollevate'))),
    newRec && h('div', { class: 'cardp rec' }, ttile('trophy', 22), h('div', {}, h('b', {}, 'Nuovo record!'), h('span', {}, `${name(newRec.id)} · ${newRec.best.kg ? newRec.best.kg + ' kg × ' + newRec.best.reps : newRec.best.reps + ' ripetizioni'}`))),

    h('div', { class: 'card stack' },
      h('div', { class: 'row between' }, h('h2', { class: 'h2s' }, 'Peso'),
        delta != null && delta !== 0 ? h('span', { class: 'pillg' + (dGood ? '' : ' neutral') }, `${delta > 0 ? '+' : '−'}${num(Math.abs(delta))} kg`) : null),
      pesi.length ? h('div', { class: 'big' }, num(pesi[pesi.length - 1].kg), h('small', {}, ' kg')) : null,
      lineChart(pesi.map(p => ({ iso: p.date, y: p.kg })), { unit: 'kg', title: 'Peso corporeo nel tempo' }),
      h('div', { class: 'row' }, h('div', { class: 'grow' }, inp), h('button', { class: 'btn', onclick: addPeso }, 'Registra')),
      h('p', { class: 'muted small' }, 'Pesati 1 volta a settimana, sempre alla stessa ora. Il peso aggiorna anche calorie e proteine.')),

    h('div', { class: 'card stack' }, h('h2', { class: 'h2s' }, 'Forza'),
      ids.length ? [exChips,
        lineChart(series.map(s => ({ iso: s.iso, y: strength(s.best), note: s.best.kg ? `Miglior serie: ${s.best.kg} kg × ${s.best.reps}` : `Miglior serie: ${s.best.reps} ripetizioni` })),
          { unit: bw ? 'rip.' : 'kg', title: 'Andamento ' + name(sel) }),
        h('p', { class: 'muted small' }, bw ? 'Ripetizioni migliori per allenamento.' : 'Forza stimata dalla tua miglior serie (peso e ripetizioni insieme): se sale, stai progredendo.')]
        : h('p', { class: 'muted' }, 'Completa il primo allenamento per vedere i grafici.')),

    records.length > 0 && h('div', { class: 'card stack' }, h('div', { class: 'row', style: 'gap:10px' }, ttile('trophy', 12), h('h2', { class: 'h2s' }, 'Record personali')), records),
    hist.length > 0 && h('div', { class: 'card stack' }, h('h2', { class: 'h2s' }, 'Ultimi allenamenti'), hist));
}
