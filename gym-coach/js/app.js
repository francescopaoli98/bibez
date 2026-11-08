import { S, save, resetAll, exportJSON } from './store.js';
import { h, icon, toast, openSheet, closeSheet, mdLite } from './ui.js';
import { gemini } from './ai.js';
import { templatePlan, aiPlan } from './plans.js';
import { isTime, topReps, suggestion, startSession, adaptDay, estKcal, estMin, setLib } from './training.js';
import { targets } from './nutrition.js';
import { viewProgressi } from './progress.js';
import { remindersCard } from './reminders.js';
import { coachSystem, parseReply, normChanges, applyChanges, undoChanges } from './coach.js';

let LIB = [];
const EX = (id) => LIB.find(e => e.id === id);
const view = document.getElementById('view');
const tabsEl = document.getElementById('tabs');
// Come replaceChildren ma ignora false/null (utile per i blocchi condizionali)
const render = (...kids) => view.replaceChildren(...kids.flat(Infinity).filter(k => k != null && k !== false));
const go = (hash) => { location.hash = hash; };

const GRUPPI = ['tutti', 'gambe', 'petto', 'schiena', 'spalle', 'braccia', 'core', 'cardio'];
const OBIETTIVI = [['misto', 'Un po\' di tutto'], ['massa', 'Massa'], ['dimagrire', 'Dimagrire'], ['tonificare', 'Tonificare']];
const CASA_OPT = [['libero', 'Niente (corpo libero)'], ['manubri', 'Manubri']];
const LIVELLI = [['principiante', 'Principiante'], ['intermedio', 'Un po\' di esperienza']];

/* ---------------------------- avvio e navigazione ---------------------------- */
async function boot() {
  try { LIB = await (await fetch('data/exercises.json')).json(); setLib(LIB); }
  catch { render(h('p', { class: 'err' }, 'Impossibile caricare gli esercizi.')); return; }
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
  window.addEventListener('hashchange', route);
  route();
}

const ROUTES = { oggi: viewOggi, scheda: viewScheda, esercizi: viewEsercizi, coach: viewCoach, progressi: () => viewProgressi({ render, LIB, go }),
                 profilo: viewProfilo, allenamento: viewAllenamento, benvenuto: viewOnboarding };
const TAB_OF = { oggi: 'oggi', profilo: 'oggi', progressi: 'oggi', scheda: 'scheda', esercizi: 'scheda', coach: 'coach' };

function route() {
  closeSheet();
  let name = location.hash.replace(/^#\/?/, '') || 'oggi';
  if ((!S.profile || !S.plan) && name !== 'benvenuto') return go('#/benvenuto');
  if (!ROUTES[name]) name = 'oggi';
  const tab = TAB_OF[name];
  view.className = tab ? '' : 'no-tabs';
  renderTabs(tab);
  window.scrollTo(0, 0);
  ROUTES[name]();
}

function renderTabs(active) {
  tabsEl.hidden = !active;
  if (!active) return;
  const items = [['oggi', 'Oggi', 'home'], ['scheda', 'Scheda', 'list'], ['coach', 'Coach', 'chat']];
  tabsEl.replaceChildren(h('div', { class: 'inner' }, items.map(([k, label, ic]) =>
    h('a', { class: 'tab' + (k === active ? ' on' : ''), href: '#/' + k }, icon(ic), label))));
}

// Interruttore Palestra / Casa
function luogoSwitch(redraw) {
  return h('div', { class: 'seg' }, [['palestra', '🏋️ Palestra'], ['casa', '🏠 Casa']].map(([v, t]) =>
    h('button', { class: 'seg-b' + ((S.luogo || 'palestra') === v ? ' on' : ''), onclick: () => { S.luogo = v; save(); redraw(); } }, t)));
}
const homeHint = () => (S.luogo === 'casa' && (S.profile.casa || 'libero') === 'libero')
  ? h('p', { class: 'muted small' }, 'A casa uso esercizi a corpo libero. Hai dei manubri? ', h('a', { href: '#/profilo' }, 'Dillo qui'))
  : null;
const kcalTxt = (exs) => `~${estKcal(exs)} kcal`;

const gear = () => h('a', { class: 'iconbtn', href: '#/profilo', 'aria-label': 'Impostazioni' }, icon('user'));

/* ---------------------------- dettaglio esercizio ---------------------------- */
const exAnim = (ex) => h('div', { class: 'anim' }, ex.img.map(src => h('img', { src, alt: ex.nome })));

function showExercise(id) {
  const ex = EX(id); if (!ex) return;
  openSheet(h('div', { class: 'stack' },
    exAnim(ex),
    h('div', {}, h('h2', {}, ex.nome), h('p', { class: 'muted small' }, `${ex.muscoli} · ${ex.attrezzo}`)),
    h('ol', { class: 'steps' }, ex.passi.map(p => h('li', {}, p))),
    h('div', { class: 'tip' }, '💡 ', ex.consiglio),
    h('a', { class: 'btn ghost block', href: ex.video, target: '_blank', rel: 'noopener' }, '▶ Guarda il video su YouTube'),
    h('button', { class: 'btn block', onclick: closeSheet }, 'Chiudi')));
}

function exRow(id, subtitle, onclick) {
  const ex = EX(id);
  return h('button', { class: 'ex-item', onclick: onclick || (() => showExercise(id)) },
    h('img', { class: 'thumb', src: ex.img[0], alt: '', loading: 'lazy' }),
    h('div', { class: 'grow' }, h('h3', {}, ex.nome), h('div', { class: 'muted small' }, subtitle || ex.muscoli)));
}

/* ---------------------------- primo avvio: una sola schermata ---------------------------- */
function viewOnboarding() {
  const d = { obiettivo: 'misto', livello: 'intermedio', giorni: 3, casa: 'libero', peso: '', note: '', apiKey: S.settings.apiKey || '' };
  const pick = (title, key, opts) => {
    const box = h('div', { class: 'chips' });
    const draw = () => box.replaceChildren(...opts.map(([v, t]) =>
      h('button', { class: 'chip lg' + (d[key] === v ? ' on' : ''), onclick: () => { d[key] = v; draw(); } }, t)));
    draw();
    return h('div', { class: 'stack' }, h('h3', {}, title), box);
  };
  const btn = h('button', { class: 'btn block', onclick: create });
  const label = () => { btn.textContent = d.apiKey ? 'Crea la mia scheda' : 'Crea la scheda (senza IA)'; };
  label();

  async function create() {
    S.settings.apiKey = d.apiKey;
    S.profile = { obiettivo: d.obiettivo, livello: d.livello, giorni: d.giorni, casa: d.casa, peso: parseFloat(d.peso) || 0, note: d.note };
    save();
    await buildPlan();
  }

  render(h('div', { class: 'stack', style: 'gap:22px' },
    h('div', {}, h('h1', {}, 'Facciamo la tua scheda 💪'), h('p', { class: 'muted' }, 'Ho già scelto per te le opzioni più comuni. Cambia solo se serve.')),
    pick('Obiettivo', 'obiettivo', OBIETTIVI),
    pick('Esperienza', 'livello', LIVELLI),
    pick('Giorni a settimana', 'giorni', [[2, '2'], [3, '3'], [4, '4'], [5, '5']]),
    pick('A casa che attrezzatura hai?', 'casa', CASA_OPT),
    h('label', { class: 'field' }, 'Il tuo peso in kg (per stimare le calorie, facoltativo)',
      h('input', { type: 'number', inputmode: 'decimal', placeholder: '75', oninput: e => d.peso = e.target.value })),
    h('label', { class: 'field' }, 'Dolori o limiti? (facoltativo)',
      h('input', { type: 'text', placeholder: 'Es. mal di schiena', oninput: e => d.note = e.target.value })),
    h('div', { class: 'card stack' },
      h('h3', {}, 'Coach IA (gratis)'),
      h('p', { class: 'muted small' }, 'Incolla la chiave di Gemini: serve per la scheda su misura e per la chat col coach. Resta solo sul tuo telefono.'),
      h('input', { type: 'password', placeholder: 'Chiave Gemini', value: d.apiKey, autocomplete: 'off', oninput: e => { d.apiKey = e.target.value.trim(); label(); } }),
      h('a', { class: 'small', href: 'https://aistudio.google.com/apikey', target: '_blank', rel: 'noopener' }, 'Come ottenere la chiave →')),
    btn));
}

async function buildPlan() {
  view.className = 'no-tabs'; renderTabs(null);
  render(h('div', { class: 'center stack', style: 'padding-top:30vh' },
    h('div', { class: 'spin' }), h('h2', {}, 'Il coach prepara la tua scheda…')));
  let plan, note = '';
  if (S.settings.apiKey) {
    try { plan = await aiPlan(S.profile, LIB); }
    catch (e) { note = 'IA non disponibile: ho usato una scheda pronta. (' + e.message + ')'; }
  }
  S.plan = plan || templatePlan(S.profile);
  S.nextDay = 0; S.session = null; S.planBackup = null;
  save();
  if (location.hash === '#/oggi') route(); else go('#/oggi');
  setTimeout(() => toast(note || 'Scheda pronta! 🎉'), 300);
}

/* ---------------------------- Oggi ---------------------------- */
const weekCount = () => S.history.filter(w => new Date(w.date).getTime() > Date.now() - 7 * 864e5).length;

function viewOggi() {
  const day = S.plan.giorni[S.nextDay % S.plan.giorni.length];
  const wk = weekCount(), target = S.profile.giorni;
  const exs = adaptDay(day, S.luogo);
  const kcalWeek = Math.round(S.history.filter(w => new Date(w.date).getTime() > Date.now() - 7 * 864e5).reduce((a, w) => a + (w.kcal || 0), 0) / 10) * 10;
  render(
    h('div', { class: 'row between' }, h('h1', {}, 'Ciao 👋'), gear()),
    !S.session && luogoSwitch(viewOggi),
    !S.session && homeHint(),
    h('div', { class: 'hero' },
      h('div', { class: 'kicker' }, S.session ? `Allenamento in corso · ${S.session.luogo === 'casa' ? '🏠 Casa' : '🏋️ Palestra'}` : 'Oggi tocca a'),
      h('h1', {}, day.nome),
      h('p', { class: 'muted' }, `${exs.length} esercizi · circa ${estMin(exs)} min · ${kcalTxt(exs)}`),
      h('button', { class: 'btn big block', onclick: () => { if (!S.session) startSession(S.nextDay % S.plan.giorni.length); go('#/allenamento'); } },
        S.session ? 'Riprendi' : 'Inizia')),
    h('div', { class: 'card stack' },
      h('div', { class: 'row between' }, h('h3', {}, 'Questa settimana'), h('span', { class: 'muted small' }, `${wk} / ${target}${kcalWeek ? ' · ~' + kcalWeek + ' kcal' : ''}`)),
      h('div', { class: 'week' }, Array.from({ length: target }, (_, i) => h('i', { class: i < wk ? 'on' : '' })))),
    nutritionCard(),
    h('a', { class: 'card row between linkcard', href: '#/progressi' },
      h('div', {}, h('h3', {}, 'I tuoi progressi'), h('p', { class: 'muted small' }, S.history.length ? 'Peso, forza, record e storico' : 'Peso, forza e record: appaiono qui')), h('span', { class: 'arrow' }, '›')),
    h('a', { class: 'card row between linkcard', href: '#/coach' },
      h('div', {}, h('h3', {}, 'Parla col coach'), h('p', { class: 'muted small' }, 'Dolore, poco tempo, esercizio da cambiare…')),
      h('span', { class: 'arrow' }, '›')));
}

function nutritionCard() {
  const t = targets(S.profile);
  if (!t) return h('a', { class: 'card row between linkcard', href: '#/profilo' },
    h('div', {}, h('h3', {}, 'Calcola calorie e proteine'), h('p', { class: 'muted small' }, 'Servono altezza, età e sesso')), h('span', { class: 'arrow' }, '›'));
  return h('div', { class: 'card stack' },
    h('div', { class: 'row between' }, h('h3', {}, 'Alimentazione di oggi'), h('span', { class: 'muted small' }, 'stima')),
    h('div', { class: 'stats' },
      h('div', { class: 'stat' }, h('b', {}, t.kcal), h('span', {}, 'kcal')),
      h('div', { class: 'stat' }, h('b', {}, t.prot + ' g'), h('span', {}, 'proteine')),
      h('div', { class: 'stat' }, h('b', {}, t.carb + ' g'), h('span', {}, 'carboidrati'))));
}

/* ---------------------------- Scheda ---------------------------- */
function viewScheda() {
  render(
    h('div', {}, h('h1', {}, S.plan.nome), h('p', { class: 'muted' }, 'Tocca un esercizio per vedere come si fa.')),
    luogoSwitch(viewScheda), homeHint(),
    ...S.plan.giorni.map((d, i) => h('details', { class: 'card day', open: i === S.nextDay % S.plan.giorni.length },
      h('summary', {}, h('div', {}, h('h3', {}, d.nome), h('div', { class: 'muted small' }, `${adaptDay(d, S.luogo).length} esercizi · ${kcalTxt(adaptDay(d, S.luogo))}`)),
        h('button', { class: 'btn small', onclick: (e) => {
          e.preventDefault();
          if (S.session && !confirm('Hai un allenamento in corso. Vuoi iniziarne un altro?')) return;
          startSession(i); go('#/allenamento'); } }, 'Inizia')),
      h('div', { class: 'list' }, adaptDay(d, S.luogo).map(e => exRow(e.id, `${e.serie} × ${e.ripetizioni}${e.recupero ? ' · rec. ' + e.recupero + 's' : ''}`))))),
    h('a', { class: 'btn block', href: '#/coach' }, 'Chiedi al coach di cambiarla'),
    h('a', { class: 'btn ghost block', href: '#/esercizi' }, 'Tutti gli esercizi'));
}

/* ---------------------------- libreria esercizi ---------------------------- */
let fGruppo = 'tutti', fQuery = '';
function viewEsercizi() {
  const grid = h('div', { class: 'ex-grid' });
  const draw = () => {
    const q = fQuery.toLowerCase();
    const list = LIB.filter(e => (fGruppo === 'tutti' || e.gruppo === fGruppo) && (!q || (e.nome + ' ' + e.muscoli).toLowerCase().includes(q)));
    grid.replaceChildren(...list.map(e => h('button', { class: 'ex-card', onclick: () => showExercise(e.id) },
      h('img', { src: e.img[0], alt: '', loading: 'lazy' }),
      h('div', {}, h('h3', {}, e.nome), h('span', { class: 'tag' }, e.gruppo)))));
    if (!list.length) grid.replaceChildren(h('p', { class: 'muted' }, 'Nessun esercizio trovato.'));
  };
  const chips = h('div', { class: 'chips scroll' });
  const drawChips = () => chips.replaceChildren(...GRUPPI.map(g =>
    h('button', { class: 'chip' + (g === fGruppo ? ' on' : ''), onclick: () => { fGruppo = g; drawChips(); draw(); } }, g)));
  drawChips(); draw();
  render(h('div', { class: 'row' }, h('a', { class: 'iconbtn', href: '#/scheda', 'aria-label': 'Indietro' }, '‹'), h('h1', {}, 'Esercizi')),
    h('input', { type: 'search', placeholder: 'Cerca (es. panca, squat…)', value: fQuery, oninput: e => { fQuery = e.target.value; draw(); } }),
    chips, grid);
}

/* ---------------------------- allenamento: un esercizio alla volta ---------------------------- */
let wakeLock = null;
async function keepAwake(on) {
  try {
    if (on && 'wakeLock' in navigator && !wakeLock) wakeLock = await navigator.wakeLock.request('screen');
    else if (!on && wakeLock) { await wakeLock.release(); wakeLock = null; }
  } catch { wakeLock = null; }
}

function viewAllenamento() {
  const s = S.session;
  if (!s) return go('#/oggi');
  keepAwake(true);
  const n = s.exercises.length;
  s.cur = Math.max(0, Math.min(s.cur || 0, n - 1));
  const ex = s.exercises[s.cur], info = EX(ex.id), sg = suggestion(ex.id, ex.target), time = isTime(ex.target.ripetizioni);
  const last = s.cur === n - 1;

  const total = s.exercises.reduce((a, e) => a + e.sets.length, 0);
  const bar = h('i');
  const upd = () => {
    const done = s.exercises.reduce((a, e) => a + e.sets.filter(x => x.done).length, 0);
    bar.style.width = (done / total * 100) + '%';
  };

  const rows = ex.sets.map((st, si) => {
    const kg = h('input', { type: 'number', inputmode: 'decimal', step: '0.5', min: '0', placeholder: 'kg', value: st.kg, disabled: time, oninput: e => { st.kg = e.target.value; save(); } });
    const reps = h('input', { type: 'number', inputmode: 'numeric', min: '0', placeholder: ex.target.ripetizioni, value: st.reps, disabled: time, oninput: e => { st.reps = e.target.value; save(); } });
    const chk = h('button', { class: 'chk', 'aria-label': 'Serie fatta' }, icon('check'));
    const cells = [h('div', { class: 'n' }, si + 1), kg, reps, chk];
    const paint = () => cells.forEach(c => c.classList.toggle('set-done', st.done));
    chk.addEventListener('click', () => {
      st.done = !st.done; paint(); save(); upd();
      if (st.done && ex.target.recupero) startRest(ex.target.recupero);
      if (!st.done) stopRest();
    });
    paint();
    return h('div', { style: 'display:contents' }, cells);
  });

  const goTo = (i) => { s.cur = i; save(); stopRest(); viewAllenamento(); window.scrollTo(0, 0); };

  render(
    h('div', { class: 'sticky-head' },
      h('div', {}, h('div', { class: 'muted small' }, s.dayName + (s.luogo === 'casa' ? ' · 🏠 Casa' : '')), h('h3', {}, `Esercizio ${s.cur + 1} di ${n}`)),
      h('button', { class: 'btn ghost small', onclick: exitMenu }, 'Fine')),
    h('div', { class: 'progress' }, bar),
    h('button', { class: 'anim-btn', onclick: () => showExercise(ex.id), 'aria-label': 'Come si fa' }, exAnim(info), h('span', { class: 'pill' }, 'Come si fa ›')),
    h('div', {}, h('h1', {}, info.nome), h('p', { class: 'muted' }, `${ex.target.serie} × ${ex.target.ripetizioni}${ex.target.recupero ? ' · recupero ' + ex.target.recupero + 's' : ''}`)),
    sg && h('div', { class: 'hint' }, 'Ultima volta: ', sg.txt, sg.up ? h('span', {}, ' · ', h('b', {}, `prova ${sg.up} kg 🔥`)) : ''),
    h('div', { class: 'sets' },
      h('div', { class: 'hd' }, ''), h('div', { class: 'hd' }, time ? '' : 'Kg'), h('div', { class: 'hd' }, time ? '' : 'Ripet.'), h('div', { class: 'hd' }, ''), rows),
    h('p', { class: 'muted small center' }, time ? 'Tocca ✓ quando hai finito.' : 'I valori sono già compilati: tocca ✓ a ogni serie, cambia solo se serve.'),
    h('button', { class: 'btn ghost block', onclick: () => swapExercise(s.cur) }, '↔ Sostituisci esercizio'),
    h('div', { class: 'bottom-bar' }, h('div', { class: 'in' },
      s.cur > 0 && h('button', { class: 'btn ghost', onclick: () => goTo(s.cur - 1), 'aria-label': 'Precedente' }, '‹'),
      h('button', { class: 'btn grow big', onclick: () => last ? finishSession() : goTo(s.cur + 1) }, last ? 'Termina allenamento' : 'Prossimo esercizio ›'))));
  upd();
}

function exitMenu() {
  openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Allenamento'),
    h('button', { class: 'btn block', onclick: () => { closeSheet(); finishSession(); } }, 'Termina e salva'),
    h('button', { class: 'btn ghost block', onclick: () => { closeSheet(); go('#/oggi'); } }, 'Metti in pausa (riprendi dopo)'),
    h('button', { class: 'btn danger block', onclick: () => { if (confirm('Annullare? Perderai i dati di questo allenamento.')) { closeSheet(); discardSession(); } } }, 'Annulla allenamento'),
    h('button', { class: 'btn ghost block', onclick: closeSheet }, 'Continua')));
}
function discardSession() { S.session = null; save(); keepAwake(false); stopRest(); go('#/oggi'); }

function swapExercise(ei) {
  const s = S.session, cur = EX(s.exercises[ei].id);
  const alts = LIB.filter(e => e.gruppo === cur.gruppo && e.id !== cur.id && !s.exercises.some(x => x.id === e.id));
  openSheet(h('div', { class: 'stack' },
    h('h2', {}, 'Sostituisci con…'), h('p', { class: 'muted small' }, `Alternative per ${cur.gruppo}`),
    alts.map(a => exRow(a.id, a.attrezzo + ' · ' + a.muscoli, () => {
      const old = s.exercises[ei];
      const t = { ...old.target, id: a.id };
      s.exercises[ei] = { id: a.id, target: t, sets: old.sets.map(() => ({ kg: suggestion(a.id, t)?.kg ? String(suggestion(a.id, t).kg) : '', reps: String(topReps(t.ripetizioni) || ''), done: false })) };
      save(); closeSheet(); viewAllenamento();
    }))));
}

function finishSession() {
  const s = S.session;
  const done = s.exercises.map(e => ({ id: e.id, sets: e.sets.filter(x => x.done).map(x => ({ kg: parseFloat(x.kg) || 0, reps: parseInt(x.reps) || 0 })) })).filter(e => e.sets.length);
  if (!done.length) { if (confirm('Nessuna serie completata. Chiudere senza salvare?')) discardSession(); return; }
  const rec = {
    date: new Date().toISOString(), dayName: s.dayName,
    durata: Math.max(1, Math.round((Date.now() - s.startedAt) / 60000)),
    exercises: done,
    sets: done.reduce((a, e) => a + e.sets.length, 0),
    volume: done.reduce((a, e) => a + e.sets.reduce((b, x) => b + x.kg * x.reps, 0), 0),
    luogo: s.luogo || 'palestra',
    kcal: estKcal(s.exercises.map(e => ({ ...e.target, id: e.id, serie: e.sets.filter(x => x.done).length })).filter(t => t.serie)),
  };
  S.history.push(rec);
  S.nextDay = (s.dayIndex + 1) % S.plan.giorni.length;
  S.session = null; save(); keepAwake(false); stopRest();
  go('#/oggi');
  toast(`Ottimo lavoro! ${rec.sets} serie, ${rec.durata} min, ~${rec.kcal} kcal 💪`);
}

/* timer di recupero */
let restTimer = null, audioCtx = null;
function beep() {
  try {
    const o = audioCtx.createOscillator(), g = audioCtx.createGain();
    o.frequency.value = 880; g.gain.value = 0.15; o.connect(g); g.connect(audioCtx.destination);
    o.start(); o.stop(audioCtx.currentTime + 0.35);
  } catch {}
}
function stopRest() { clearInterval(restTimer); restTimer = null; document.getElementById('rest-root').replaceChildren(); }
function startRest(sec) {
  try { audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)(); audioCtx.resume?.(); } catch {}
  stopRest();
  let end = Date.now() + sec * 1000;
  const t = h('div', { class: 't' });
  const draw = () => {
    const left = Math.max(0, Math.ceil((end - Date.now()) / 1000));
    t.textContent = `${Math.floor(left / 60)}:${String(left % 60).padStart(2, '0')}`;
    if (left === 0) { clearInterval(restTimer); restTimer = null; beep(); navigator.vibrate?.([200, 100, 200]); t.textContent = 'Via! 💥'; setTimeout(stopRest, 2500); }
  };
  document.getElementById('rest-root').replaceChildren(h('div', { class: 'rest' },
    h('div', { class: 'grow' }, h('div', { class: 'muted small' }, 'Recupero'), t),
    h('button', { class: 'btn ghost small', onclick: () => { end += 15000; draw(); } }, '+15s'),
    h('button', { class: 'btn small', onclick: stopRest }, 'Salta')));
  draw(); restTimer = setInterval(draw, 250);
}

/* ---------------------------- coach IA ---------------------------- */
const STATUS = { pending: 'Sto per modificare la scheda', applied: 'Modifica applicata ✅', rejected: 'Nessuna modifica fatta', undone: 'Modifica annullata' };

function viewCoach() {
  const list = h('div', { class: 'chat' });
  const input = h('input', { type: 'text', placeholder: 'Scrivi al coach…', enterkeyhint: 'send' });
  let busy = false;
  const bottom = () => window.scrollTo(0, document.body.scrollHeight);

  function proposalCard(m) {
    const p = m.proposal;
    const setStatus = (st) => { p.status = st; save(); draw(); };
    return h('div', { class: 'proposal' + (p.status === 'pending' ? ' pending' : '') },
      h('div', { class: 'kicker' }, STATUS[p.status]),
      h('ul', {}, p.changes.map(c => h('li', {}, c.desc))),
      p.status === 'pending' && h('div', { class: 'row' },
        h('button', { class: 'btn grow', onclick: () => {
          const ok = normChanges(p.changes, LIB);        // ricontrolla: la scheda potrebbe essere cambiata
          if (!ok.length) { toast('Queste modifiche non sono più applicabili'); return setStatus('rejected'); }
          applyChanges(ok);
          S.chat.forEach(x => x.proposal && (x.proposal.undoable = false));
          p.undoable = true; setStatus('applied');
          toast(S.session ? 'Fatto! Allenamento aggiornato' : 'Fatto! Scheda aggiornata');
        } }, 'Sì, applica'),
        h('button', { class: 'btn ghost grow', onclick: () => setStatus('rejected') }, 'No, lascia così')),
      p.status === 'applied' && p.undoable && S.planBackup &&
        h('button', { class: 'btn ghost small', onclick: () => { if (undoChanges()) setStatus('undone'); } }, 'Annulla modifica'));
  }

  function draw() {
    const msgs = S.chat.length ? S.chat : [{ role: 'model', text: 'Ciao! Sono il tuo coach. Dimmi se qualcosa ti dà fastidio, se hai poco tempo o se vuoi cambiare un esercizio: ti dico io cosa modificare, e prima di toccare la scheda ti chiedo il permesso. 💪' }];
    list.replaceChildren(...msgs.flatMap(m => {
      const b = h('div', { class: 'msg ' + (m.role === 'user' ? 'me' : 'ai') });
      b.append(m.role === 'user' ? document.createTextNode(m.text) : mdLite(m.text));
      return [b, m.proposal && proposalCard(m)];
    }).filter(Boolean));
    bottom();
  }

  async function send(text) {
    text = (text || input.value).trim();
    if (!text || busy) return;
    if (!S.settings.apiKey) return toast('Aggiungi la chiave Gemini in Impostazioni');
    busy = true; input.value = '';
    S.chat.push({ role: 'user', text }); S.chat = S.chat.slice(-30); save(); draw();
    list.append(h('div', { class: 'msg ai' }, h('div', { class: 'dots-anim' }, h('span'), h('span'), h('span')))); bottom();
    try {
      const hist = S.chat.map(m => ({ role: m.role, parts: [{ text: m.text }] }));
      while (hist.length && hist[0].role !== 'user') hist.shift();
      const raw = await gemini({ system: coachSystem(LIB), contents: hist, json: true, temperature: 0.5 });
      const { text: reply, changes } = parseReply(raw);
      const ok = normChanges(changes, LIB);
      S.chat.push({ role: 'model', text: reply, ...(ok.length ? { proposal: { status: 'pending', changes: ok } } : {}) });
    } catch (e) { S.chat.pop(); toast(e.message); input.value = text; }
    S.chat = S.chat.slice(-30); save(); busy = false; draw();
  }
  input.addEventListener('keydown', e => { if (e.key === 'Enter') send(); });

  const sugg = ['Mi fa male una cosa', 'Cambia un esercizio', 'Ho poco tempo oggi', 'Mi sembra troppo facile'];
  render(
    h('div', { class: 'row between' }, h('h1', {}, 'Coach'),
      h('div', { class: 'row', style: 'gap:8px' },
        S.chat.length > 0 && h('button', { class: 'btn ghost small', onclick: () => { S.chat = []; save(); viewCoach(); } }, 'Nuova chat'), gear())),
    !S.settings.apiKey && h('div', { class: 'card stack' }, h('p', {}, 'Per parlare col coach serve la chiave Gemini (gratuita).'),
      h('a', { class: 'btn small', href: '#/profilo' }, 'Aggiungila qui')),
    list,
    h('div', { class: 'chips' }, sugg.map(q => h('button', { class: 'chip', onclick: () => send(q) }, q))),
    h('div', { style: 'height:64px' }),
    h('div', { class: 'composer' }, h('div', { class: 'in' }, input, h('button', { class: 'btn', onclick: () => send() }, 'Invia'))));
  draw();
}

function bodyCard() {
  const out = h('div', { class: 'stack' });
  const num = (label, key, ph) => h('label', { class: 'field' }, label,
    h('input', { type: 'number', inputmode: 'decimal', placeholder: ph, value: S.profile[key] || '', oninput: e => { S.profile[key] = parseFloat(e.target.value) || 0; save(); show(); } }));
  const sesso = h('div', { class: 'chips' });
  const drawSesso = () => sesso.replaceChildren(...[['uomo', 'Uomo'], ['donna', 'Donna']].map(([v, t]) =>
    h('button', { class: 'chip lg' + (S.profile.sesso === v ? ' on' : ''), onclick: () => { S.profile.sesso = v; save(); drawSesso(); show(); } }, t)));
  function show() {
    const t = targets(S.profile);
    out.replaceChildren(t
      ? h('div', { class: 'stack' },
          h('div', { class: 'stats' },
            h('div', { class: 'stat' }, h('b', {}, t.kcal), h('span', {}, 'kcal al giorno')),
            h('div', { class: 'stat' }, h('b', {}, t.prot + ' g'), h('span', {}, 'proteine')),
            h('div', { class: 'stat' }, h('b', {}, t.fat + ' g'), h('span', {}, 'grassi'))),
          h('p', { class: 'muted small' }, `Mantenimento circa ${t.mantenimento} kcal. Il resto è carboidrati (~${t.carb} g). Stima indicativa: pesati ogni settimana e correggi di ±100-150 kcal se serve. Non sostituisce il parere di un medico o di un nutrizionista.`))
      : h('p', { class: 'muted small' }, 'Inserisci peso, altezza, età e sesso per calcolare calorie e proteine.'));
  }
  drawSesso(); show();
  return h('div', { class: 'card stack' }, h('h2', {}, 'Il tuo corpo e l\'alimentazione'),
    h('div', { class: 'row' }, h('div', { class: 'grow' }, num('Peso (kg)', 'peso', '87')), h('div', { class: 'grow' }, num('Altezza (cm)', 'altezza', '181'))),
    h('div', { class: 'row' }, h('div', { class: 'grow' }, num('Età', 'eta', '30')), h('div', { class: 'grow' }, h('div', { class: 'field' }, 'Sesso (per la formula)', sesso))),
    out);
}

/* ---------------------------- impostazioni ---------------------------- */
function viewProfilo() {
  const p = { obiettivo: S.profile.obiettivo, livello: S.profile.livello, giorni: S.profile.giorni };
  const sel = (label, key, opts) => h('div', { class: 'stack' }, h('h3', {}, label),
    h('div', { class: 'chips' }, opts.map(([v, t]) => h('button', { class: 'chip lg' + (p[key] === v ? ' on' : ''), onclick: (e) => {
      p[key] = v; e.target.parentElement.querySelectorAll('.chip').forEach(c => c.classList.remove('on')); e.target.classList.add('on'); } }, t))));
  const keyIn = h('input', { type: 'password', value: S.settings.apiKey, placeholder: 'Chiave API Gemini', autocomplete: 'off' });
  const modelIn = h('input', { type: 'text', value: S.settings.model, autocapitalize: 'off' });
  const note = h('textarea', { placeholder: 'Dolori, infortuni…', value: p.note || '' });
  const saveKeys = () => { S.settings.apiKey = keyIn.value.trim(); S.settings.model = modelIn.value.trim() || 'gemini-flash-latest'; save(); };

  render(
    h('div', { class: 'row' }, h('a', { class: 'iconbtn', href: '#/oggi', 'aria-label': 'Indietro' }, '‹'), h('h1', {}, 'Impostazioni')),
    bodyCard(),
    remindersCard(),
    h('div', { class: 'card stack' }, h('h2', {}, 'Casa'),
      h('div', { class: 'stack' }, h('h3', {}, 'Attrezzatura a casa'),
        h('div', { class: 'chips' }, CASA_OPT.map(([v, t]) => h('button', { class: 'chip lg' + ((S.profile.casa || 'libero') === v ? ' on' : ''), onclick: (e) => {
          S.profile.casa = v; save(); e.target.parentElement.querySelectorAll('.chip').forEach(c => c.classList.remove('on')); e.target.classList.add('on'); toast('Salvato'); } }, t)))),
    ),
    h('div', { class: 'card stack' }, h('h2', {}, 'Coach IA (Gemini)'),
      h('label', { class: 'field' }, 'Chiave API', keyIn),
      h('a', { href: 'https://aistudio.google.com/apikey', target: '_blank', rel: 'noopener', class: 'small' }, 'Crea / vedi la chiave su Google AI Studio →'),
      h('div', { class: 'row' },
        h('button', { class: 'btn ghost grow', onclick: async (e) => {
          saveKeys(); e.target.disabled = true; e.target.textContent = 'Provo…';
          try { await gemini({ contents: [{ role: 'user', parts: [{ text: 'Rispondi solo: ok' }] }] }); toast('Collegamento riuscito ✅'); }
          catch (err) { toast(err.message); }
          e.target.disabled = false; e.target.textContent = 'Prova collegamento'; } }, 'Prova collegamento'),
        h('button', { class: 'btn grow', onclick: () => { saveKeys(); toast('Salvato'); } }, 'Salva')),
      h('p', { class: 'muted small' }, 'La chiave resta su questo telefono e viene inviata solo a Google.')),
    h('div', { class: 'card stack' }, h('h2', {}, 'Rifai la scheda da zero'),
      sel('Obiettivo', 'obiettivo', OBIETTIVI), sel('Esperienza', 'livello', LIVELLI), sel('Giorni a settimana', 'giorni', [[2, '2'], [3, '3'], [4, '4'], [5, '5']]),
      h('label', { class: 'field' }, 'Limiti / infortuni', note),
      h('button', { class: 'btn block', onclick: async () => {
        if (S.session && !confirm('Hai un allenamento in corso: verrà annullato. Continuare?')) return;
        saveKeys(); S.profile = { ...S.profile, ...p, note: note.value }; save(); await buildPlan(); } }, 'Rigenera la scheda')),
    h('details', { class: 'card' }, h('summary', { class: 'muted' }, 'Avanzate'),
      h('div', { class: 'stack', style: 'margin-top:12px' },
        h('label', { class: 'field' }, 'Modello Gemini', modelIn),
        h('button', { class: 'btn ghost block', onclick: () => { saveKeys(); h('a', { href: URL.createObjectURL(new Blob([exportJSON()], { type: 'application/json' })), download: 'gym-coach-backup.json' }).click(); } }, 'Esporta backup'),
        h('button', { class: 'btn danger block', onclick: () => { if (confirm('Cancellare TUTTI i dati (scheda, storico, chiave)?')) { resetAll(); location.hash = ''; location.reload(); } } }, 'Cancella tutto'))),
    h('p', { class: 'muted small center' }, 'Immagini esercizi: free-exercise-db (pubblico dominio).'));
}

boot();
