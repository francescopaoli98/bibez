import { S, save, resetAll, exportJSON } from './store.js';
import { h, icon, toast, openSheet, closeSheet, mdLite } from './ui.js';
import { gemini } from './ai.js';
import { templatePlan, aiPlan } from './plans.js';

let LIB = [];                       // libreria esercizi
const EX = (id) => LIB.find(e => e.id === id);
const view = document.getElementById('view');
const tabsEl = document.getElementById('tabs');
// Come replaceChildren ma ignora false/null (utile per i blocchi condizionali)
const render = (...kids) => view.replaceChildren(...kids.flat(Infinity).filter(k => k != null && k !== false));

const GRUPPI = ['tutti', 'gambe', 'petto', 'schiena', 'spalle', 'braccia', 'core', 'cardio'];
const OBIETTIVI = [
  ['misto', 'Un po\' di tutto', 'Forza, massa e definizione insieme'],
  ['massa', 'Mettere massa', 'Più muscoli e più forza'],
  ['dimagrire', 'Dimagrire', 'Più circuiti e cardio finale'],
  ['tonificare', 'Tonificare', 'Stare in forma e definirsi'],
];

/* ------------------------------------------------------------------ */
/* Avvio                                                               */
/* ------------------------------------------------------------------ */
async function boot() {
  try { LIB = await (await fetch('data/exercises.json')).json(); }
  catch { render(h('p', { class: 'err' }, 'Impossibile caricare gli esercizi.')); return; }
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
  window.addEventListener('hashchange', route);
  route();
}

const ROUTES = {
  oggi: viewOggi, scheda: viewScheda, esercizi: viewEsercizi,
  coach: viewCoach, profilo: viewProfilo, allenamento: viewAllenamento, benvenuto: viewOnboarding,
};

function route() {
  closeSheet();
  let name = location.hash.replace(/^#\/?/, '') || 'oggi';
  if (!S.profile || !S.plan) { if (name !== 'benvenuto') { location.hash = '#/benvenuto'; return; } }
  if (!ROUTES[name]) name = 'oggi';
  const full = name === 'allenamento' || name === 'benvenuto';
  view.className = full ? 'no-tabs' : '';
  renderTabs(full ? null : name);
  window.scrollTo(0, 0);
  ROUTES[name]();
}

function renderTabs(active) {
  tabsEl.hidden = !active;
  if (!active) return;
  const items = [['oggi', 'Oggi', 'home'], ['scheda', 'Scheda', 'list'], ['esercizi', 'Esercizi', 'dumbbell'],
                 ['coach', 'Coach', 'chat'], ['profilo', 'Profilo', 'user']];
  tabsEl.replaceChildren(h('div', { class: 'inner' }, items.map(([k, label, ic]) =>
    h('a', { class: 'tab' + (k === active ? ' on' : ''), href: '#/' + k, style: 'text-decoration:none' }, icon(ic), label))));
}

/* ------------------------------------------------------------------ */
/* Dettaglio esercizio (pannello)                                      */
/* ------------------------------------------------------------------ */
function exAnim(ex) {
  // Due immagini (inizio/fine movimento) che si alternano = piccola animazione
  return h('div', { class: 'anim' }, ex.img.map(src => h('img', { src, alt: ex.nome, loading: 'lazy' })));
}

function showExercise(id) {
  const ex = EX(id); if (!ex) return;
  openSheet(h('div', { class: 'stack' },
    exAnim(ex),
    h('div', {}, h('h2', {}, ex.nome), h('p', { class: 'muted small' }, `${ex.muscoli} · ${ex.attrezzo}`)),
    h('ol', { class: 'steps' }, ex.passi.map(p => h('li', {}, p))),
    h('div', { class: 'tip' }, '💡 ', ex.consiglio),
    h('a', { class: 'btn ghost block', href: ex.video, target: '_blank', rel: 'noopener', style: 'text-decoration:none' }, '▶ Guarda il video su YouTube'),
    h('button', { class: 'btn block', onclick: closeSheet }, 'Chiudi'),
  ));
}

function exRow(id, subtitle, onclick) {
  const ex = EX(id);
  return h('button', { class: 'ex-item', onclick: onclick || (() => showExercise(id)) },
    h('img', { class: 'thumb', src: ex.img[0], alt: '', loading: 'lazy' }),
    h('div', { class: 'grow' }, h('h3', {}, ex.nome), h('div', { class: 'muted small' }, subtitle || ex.muscoli)));
}

/* ------------------------------------------------------------------ */
/* Onboarding + creazione scheda                                       */
/* ------------------------------------------------------------------ */
function viewOnboarding() {
  const d = { obiettivo: 'misto', livello: 'intermedio', giorni: 3, note: '', apiKey: S.settings.apiKey || '' };
  let step = 0;
  const TOT = 4;

  const choose = (opts, key, grid) => h('div', { class: 'opts' + (grid ? ' grid' : '') }, opts.map(([v, t, s]) =>
    h('button', { class: 'opt' + (d[key] === v ? ' on' : ''), onclick: () => { d[key] = v; draw(); } },
      h('b', {}, t), s && h('span', {}, s))));

  const nextLabel = () => step === TOT - 1 ? (d.apiKey ? 'Crea la mia scheda' : 'Continua senza IA') : 'Avanti';
  const nextBtn = h('button', { class: 'btn grow', onclick: next });

  function draw() {
    nextBtn.textContent = nextLabel();
    const body = [];
    if (step === 0) body.push(
      h('div', {}, h('h1', {}, 'Ciao! Facciamo la tua scheda 💪'), h('p', { class: 'muted' }, 'Quattro domande veloci. Qual è il tuo obiettivo?')),
      choose(OBIETTIVI, 'obiettivo'));
    if (step === 1) body.push(
      h('div', {}, h('h1', {}, 'Che esperienza hai?')),
      choose([['principiante', 'Principiante', 'Mai o quasi mai in palestra'],
              ['intermedio', 'Qualche esperienza', 'Ci sono stato ogni tanto negli anni']], 'livello'));
    if (step === 2) body.push(
      h('div', {}, h('h1', {}, 'Quanti giorni a settimana?'), h('p', { class: 'muted' }, '3 è perfetto per iniziare e restare costante.')),
      choose([[2, '2'], [3, '3'], [4, '4'], [5, '5']], 'giorni', true),
      h('label', { class: 'field' }, 'Dolori, infortuni o limiti? (facoltativo)',
        h('textarea', { placeholder: 'Es. mal di schiena, spalla sinistra delicata…', oninput: e => d.note = e.target.value, value: d.note })));
    if (step === 3) body.push(
      h('div', {}, h('h1', {}, 'Attiva il coach IA'),
        h('p', { class: 'muted' }, 'Incolla la tua chiave gratuita di Gemini: serve per creare la scheda su misura e per la chat col coach. Resta solo sul tuo telefono.')),
      h('a', { href: 'https://aistudio.google.com/apikey', target: '_blank', rel: 'noopener' }, 'Crea la chiave su Google AI Studio →'),
      h('input', { type: 'password', placeholder: 'Chiave API Gemini', value: d.apiKey, autocomplete: 'off', oninput: e => { d.apiKey = e.target.value.trim(); nextBtn.textContent = nextLabel(); } }),
      h('p', { class: 'muted small' }, 'Senza chiave ti preparo comunque una scheda pronta, e potrai aggiungerla dopo.'));

    render(h('div', { class: 'onb' },
      h('div', { class: 'dots' }, Array.from({ length: TOT }, (_, i) => h('i', { class: i <= step ? 'on' : '' }))),
      ...body, h('div', { class: 'spacer' }),
      h('div', { class: 'row' },
        step > 0 && h('button', { class: 'btn ghost', onclick: () => { step--; draw(); } }, 'Indietro'),
        nextBtn)));
  }

  async function next() {
    if (step < TOT - 1) { step++; draw(); window.scrollTo(0, 0); return; }
    S.settings.apiKey = d.apiKey;
    S.profile = { obiettivo: d.obiettivo, livello: d.livello, giorni: d.giorni, note: d.note };
    save();
    await buildPlan();
  }
  draw();
}

async function buildPlan() {
  view.className = 'no-tabs';
  render(h('div', { class: 'onb center', style: 'justify-content:center' },
    h('div', { class: 'spin' }), h('h2', {}, 'Il coach sta preparando la tua scheda…'),
    h('p', { class: 'muted' }, 'Ci vogliono pochi secondi.')));
  let plan, note = '';
  if (S.settings.apiKey) {
    try { plan = await aiPlan(S.profile, LIB); }
    catch (e) { note = 'IA non disponibile (' + e.message + '). Ho usato una scheda pronta.'; }
  }
  if (!plan) plan = templatePlan(S.profile);
  S.plan = plan; S.nextDay = 0; S.session = null;
  save();
  location.hash = '#/scheda';
  if (note) setTimeout(() => toast(note), 300);
  else toast('Scheda pronta! 🎉');
}

/* ------------------------------------------------------------------ */
/* Oggi                                                                */
/* ------------------------------------------------------------------ */
const GIORNI_IT = ['domenica', 'lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato'];
function weekCount() {
  const t = Date.now() - 7 * 864e5;
  return S.history.filter(w => new Date(w.date).getTime() > t).length;
}
function fmtDate(iso) {
  const d = new Date(iso);
  return `${GIORNI_IT[d.getDay()]} ${d.getDate()}/${d.getMonth() + 1}`;
}

function viewOggi() {
  const day = S.plan.giorni[S.nextDay % S.plan.giorni.length];
  const wk = weekCount();
  const target = S.profile.giorni;
  const mins = Math.round(day.esercizi.reduce((a, e) => a + e.serie * (45 + (e.recupero || 60)) / 60, 0));
  const hero = h('div', { class: 'hero' },
    h('div', { class: 'kicker' }, S.session ? 'Allenamento in corso' : 'Il prossimo allenamento'),
    h('h1', {}, day.nome),
    h('p', { class: 'muted' }, `${day.esercizi.length} esercizi · circa ${mins} min`),
    h('div', { class: 'chips' }, [...new Set(day.esercizi.map(e => EX(e.id).gruppo))].map(g => h('span', { class: 'chip' }, g))),
    h('button', { class: 'btn block', onclick: () => { if (!S.session) startSession(S.nextDay); location.hash = '#/allenamento'; } },
      S.session ? 'Riprendi allenamento' : 'Inizia allenamento'));

  const hist = S.history.slice(-4).reverse();
  render(
    h('div', {}, h('p', { class: 'muted' }, 'Forza, oggi si va in palestra.'), h('h1', {}, 'Ciao 👋')),
    hero,
    h('div', { class: 'card stack' },
      h('div', { class: 'row between' }, h('h3', {}, 'Questa settimana'), h('span', { class: 'muted small' }, `${wk} / ${target} allenamenti`)),
      h('div', { class: 'week' }, Array.from({ length: target }, (_, i) => h('i', { class: i < wk ? 'on' : '' })))),
    h('div', { class: 'stats' },
      h('div', { class: 'stat' }, h('b', {}, S.history.length), h('span', {}, 'Allenamenti')),
      h('div', { class: 'stat' }, h('b', {}, Math.round(S.history.reduce((a, w) => a + w.volume, 0) / 1000 * 10) / 10), h('span', {}, 'Tonn. sollevate')),
      h('div', { class: 'stat' }, h('b', {}, streak()), h('span', {}, 'Settimane di fila'))),
    hist.length > 0 && h('div', { class: 'stack' }, h('h2', {}, 'Ultimi allenamenti'),
      hist.map(w => h('div', { class: 'card row between' },
        h('div', {}, h('h3', {}, w.dayName), h('div', { class: 'muted small' }, fmtDate(w.date))),
        h('div', { class: 'muted small' }, `${w.sets} serie · ${w.durata} min`)))));
}

function streak() {
  // settimane consecutive (lun-dom) con almeno un allenamento
  if (!S.history.length) return 0;
  const weekKey = (d) => { const x = new Date(d); x.setHours(0, 0, 0, 0); x.setDate(x.getDate() - ((x.getDay() + 6) % 7)); return x.getTime(); };
  const weeks = new Set(S.history.map(w => weekKey(w.date)));
  let k = weekKey(new Date()), n = 0;
  if (!weeks.has(k)) k -= 7 * 864e5;           // settimana corrente ancora vuota: non spezza la serie
  while (weeks.has(k)) { n++; k -= 7 * 864e5; }
  return n;
}

/* ------------------------------------------------------------------ */
/* Scheda                                                              */
/* ------------------------------------------------------------------ */
function viewScheda() {
  render(
    h('div', {}, h('h1', {}, S.plan.nome), h('p', { class: 'muted' }, S.plan.fonte === 'ia' ? 'Creata dal coach IA per te' : 'Scheda pronta')),
    ...S.plan.giorni.map((d, i) => h('details', { class: 'card day', open: i === S.nextDay % S.plan.giorni.length },
      h('summary', {}, h('div', {}, h('h3', {}, d.nome), h('div', { class: 'muted small' }, `${d.esercizi.length} esercizi`)),
        h('button', { class: 'btn small', onclick: (e) => { e.preventDefault(); if (S.session && !confirm('Hai un allenamento in corso. Vuoi iniziarne un altro?')) return; startSession(i); location.hash = '#/allenamento'; } }, 'Inizia')),
      h('div', { class: 'list' }, d.esercizi.map(e => exRow(e.id, `${e.serie} × ${e.ripetizioni}${e.recupero ? ' · recupero ' + e.recupero + 's' : ''}`))))),
    h('button', { class: 'btn ghost block', onclick: () => { location.hash = '#/profilo'; } }, 'Cambia obiettivo o rigenera la scheda'));
}

/* ------------------------------------------------------------------ */
/* Esercizi                                                            */
/* ------------------------------------------------------------------ */
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
  const drawChips = () => chips.replaceChildren(...GRUPPI.map(g => h('button', { class: 'chip' + (g === fGruppo ? ' on' : ''), onclick: () => { fGruppo = g; drawChips(); draw(); } }, g)));
  drawChips(); draw();
  render(
    h('h1', {}, 'Esercizi'),
    h('input', { type: 'search', placeholder: 'Cerca (es. panca, squat…)', value: fQuery, oninput: e => { fQuery = e.target.value; draw(); } }),
    chips, grid);
}

/* ------------------------------------------------------------------ */
/* Allenamento guidato                                                 */
/* ------------------------------------------------------------------ */
function lastPerf(id) {
  for (let i = S.history.length - 1; i >= 0; i--) {
    const e = S.history[i].exercises.find(x => x.id === id);
    if (e && e.sets.length) return e.sets;
  }
  return null;
}
function topReps(rep) { const n = String(rep).match(/\d+/g); return n ? +n[n.length - 1] : 0; }
function suggestion(id, target) {
  const last = lastPerf(id);
  if (!last) return null;
  const best = last.reduce((a, s) => (s.kg > a.kg ? s : a), last[0]);
  const all = last.every(s => s.reps >= topReps(target.ripetizioni));
  const txt = last.map(s => `${s.kg || 0}kg×${s.reps}`).join(', ');
  return { txt, up: all && best.kg > 0 ? best.kg + 2.5 : null, kg: best.kg };
}

function startSession(dayIndex) {
  const day = S.plan.giorni[dayIndex];
  S.session = {
    dayIndex, dayName: day.nome, startedAt: Date.now(),
    exercises: day.esercizi.map(t => {
      const sg = suggestion(t.id, t);
      return { id: t.id, target: t, sets: Array.from({ length: t.serie }, () => ({ kg: sg?.kg ? String(sg.kg) : '', reps: '', done: false })) };
    }),
  };
  save();
  keepAwake(true);
}

let wakeLock = null;
async function keepAwake(on) {
  try {
    if (on && 'wakeLock' in navigator) wakeLock = await navigator.wakeLock.request('screen');
    else if (wakeLock) { await wakeLock.release(); wakeLock = null; }
  } catch {}
}

const CHECK = () => icon('check');

function viewAllenamento() {
  const s = S.session;
  if (!s) { location.hash = '#/oggi'; return; }
  keepAwake(true);
  const total = s.exercises.reduce((a, e) => a + e.sets.length, 0);
  const bar = h('i');
  const counter = h('span', { class: 'muted small' });
  const upd = () => {
    const done = s.exercises.reduce((a, e) => a + e.sets.filter(x => x.done).length, 0);
    bar.style.width = (done / total * 100) + '%';
    counter.textContent = `${done}/${total} serie`;
  };

  const cards = s.exercises.map((ex, ei) => {
    const info = EX(ex.id), sg = suggestion(ex.id, ex.target);
    const isTime = /sec|min/.test(ex.target.ripetizioni);
    const setsBox = h('div', { class: 'sets' },
      h('div', { class: 'hd' }, 'Serie'), h('div', { class: 'hd' }, isTime ? '—' : 'Kg'), h('div', { class: 'hd' }, isTime ? 'Fatto' : 'Ripet.'), h('div', { class: 'hd' }, ''),
      ex.sets.map((st, si) => {
        const kg = h('input', { type: 'number', inputmode: 'decimal', step: '0.5', min: '0', placeholder: 'kg', value: st.kg, disabled: isTime, oninput: e => { st.kg = e.target.value; save(); } });
        const reps = h('input', { type: 'number', inputmode: 'numeric', min: '0', placeholder: isTime ? '✓' : ex.target.ripetizioni, value: st.reps, disabled: isTime, oninput: e => { st.reps = e.target.value; save(); } });
        const chk = h('button', { class: 'chk', 'aria-label': 'Serie fatta' }, CHECK());
        const cells = [h('div', { class: 'n' }, si + 1), kg, reps, chk];
        chk.addEventListener('click', () => {
          st.done = !st.done;
          cells.forEach(c => c.classList.toggle('set-done', st.done));
          save(); upd();
          if (st.done) {
            if (!st.reps) { st.reps = String(topReps(ex.target.ripetizioni) || ''); reps.value = st.reps; }
            if (ex.target.recupero) startRest(ex.target.recupero);
          }
        });
        const row = h('div', { style: 'display:contents' }, cells);
        if (st.done) cells.forEach(c => c.classList.add('set-done'));
        return row;
      }));
    return h('div', { class: 'card wk-ex' },
      h('div', { class: 'top' },
        h('img', { class: 'thumb', src: info.img[0], alt: '', onclick: () => showExercise(ex.id) }),
        h('div', { class: 'grow' }, h('h3', {}, info.nome), h('div', { class: 'muted small' }, `${ex.target.serie} × ${ex.target.ripetizioni}${ex.target.recupero ? ' · ' + ex.target.recupero + 's rec.' : ''}`)),
        h('button', { class: 'btn ghost small', onclick: () => showExercise(ex.id) }, 'Come si fa')),
      sg && h('div', { class: 'hint' }, 'Ultima volta: ', sg.txt, sg.up ? h('span', {}, ' · ', h('b', {}, `prova ${sg.up} kg 🔥`)) : ''),
      setsBox,
      h('button', { class: 'btn ghost small', style: 'align-self:flex-start', onclick: () => swapExercise(ei) }, '↔ Sostituisci esercizio'));
  });

  render(
    h('div', { class: 'sticky-head' },
      h('div', {}, h('h3', {}, s.dayName), counter),
      h('button', { class: 'btn small', onclick: finishSession }, 'Fine')),
    h('div', { class: 'progress' }, bar),
    ...cards,
    h('button', { class: 'btn block', onclick: finishSession }, 'Termina allenamento'),
    h('button', { class: 'btn danger block', onclick: () => { if (confirm('Annullare l\'allenamento? Perderai i dati inseriti.')) { S.session = null; save(); keepAwake(false); stopRest(); location.hash = '#/oggi'; } } }, 'Annulla allenamento'));
  upd();
}

function swapExercise(ei) {
  const s = S.session, cur = EX(s.exercises[ei].id);
  const alts = LIB.filter(e => e.gruppo === cur.gruppo && e.id !== cur.id && !s.exercises.some(x => x.id === e.id));
  openSheet(h('div', { class: 'stack' },
    h('h2', {}, 'Sostituisci con…'), h('p', { class: 'muted small' }, `Alternative per ${cur.gruppo} (macchina occupata? Dolore?)`),
    alts.map(a => exRow(a.id, a.attrezzo + ' · ' + a.muscoli, () => {
      const old = s.exercises[ei];
      const sg = suggestion(a.id, old.target);
      s.exercises[ei] = { id: a.id, target: old.target, sets: old.sets.map(() => ({ kg: sg?.kg ? String(sg.kg) : '', reps: '', done: false })) };
      save(); closeSheet(); viewAllenamento();
    }))));
}

function finishSession() {
  const s = S.session;
  const done = s.exercises.map(e => ({ id: e.id, sets: e.sets.filter(x => x.done).map(x => ({ kg: parseFloat(x.kg) || 0, reps: parseInt(x.reps) || 0 })) })).filter(e => e.sets.length);
  if (!done.length) { if (!confirm('Nessuna serie completata. Chiudere senza salvare?')) return; S.session = null; save(); keepAwake(false); stopRest(); location.hash = '#/oggi'; return; }
  const rec = {
    date: new Date().toISOString(), dayName: s.dayName,
    durata: Math.max(1, Math.round((Date.now() - s.startedAt) / 60000)),
    exercises: done,
    sets: done.reduce((a, e) => a + e.sets.length, 0),
    volume: done.reduce((a, e) => a + e.sets.reduce((b, x) => b + x.kg * x.reps, 0), 0),
  };
  S.history.push(rec);
  S.nextDay = (s.dayIndex + 1) % S.plan.giorni.length;
  S.session = null; save(); keepAwake(false); stopRest();
  location.hash = '#/oggi';
  toast(`Ottimo lavoro! ${rec.sets} serie in ${rec.durata} min 💪`);
}

/* timer di recupero */
let restTimer = null, audioCtx = null;
function beep() {
  try {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
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
    if (left === 0) {
      clearInterval(restTimer); restTimer = null; beep(); navigator.vibrate?.([200, 100, 200]);
      t.textContent = 'Via! 💥'; setTimeout(stopRest, 2500);
    }
  };
  document.getElementById('rest-root').replaceChildren(h('div', { class: 'rest' },
    h('div', { class: 'grow' }, h('div', { class: 'muted small' }, 'Recupero'), t),
    h('button', { class: 'btn ghost small', onclick: () => { end += 15000; draw(); } }, '+15s'),
    h('button', { class: 'btn small', onclick: stopRest }, 'Salta')));
  draw(); restTimer = setInterval(draw, 250);
}

/* ------------------------------------------------------------------ */
/* Coach IA                                                            */
/* ------------------------------------------------------------------ */
function coachSystem() {
  const p = S.profile;
  const plan = S.plan.giorni.map(d => `${d.nome}: ` + d.esercizi.map(e => `${EX(e.id)?.nome} ${e.serie}x${e.ripetizioni}`).join(', ')).join('\n');
  const rec = S.history.slice(-5).map(w => `${w.date.slice(0, 10)} ${w.dayName}: ` + w.exercises.map(e => `${EX(e.id)?.nome} ${e.sets.map(s => s.kg + 'kg×' + s.reps).join('/')}`).join('; ')).join('\n') || 'nessuno ancora';
  return `Sei il coach personale di palestra di Francesco. Parli SEMPRE in italiano, tono amichevole e diretto, risposte brevi (max 6-8 righe), semplici, con elenchi puntati quando servono.
Profilo: obiettivo ${p.obiettivo}, livello ${p.livello}, ${p.giorni} giorni/settimana, palestra completa. Note: ${p.note || 'nessuna'}.
Scheda attuale:\n${plan}
Ultimi allenamenti:\n${rec}
Regole: consigli pratici su tecnica, carichi, progressione (aggiungi peso solo quando le ripetizioni massime sono raggiunte su tutte le serie), recupero e alimentazione di base. Se c'è dolore acuto o un problema medico, consiglia di fermarsi e sentire un medico. Non inventare dati che non hai.`;
}

function viewCoach() {
  const list = h('div', { class: 'chat' });
  const input = h('input', { type: 'text', placeholder: 'Scrivi al coach…', enterkeyhint: 'send' });
  let busy = false;

  const bubble = (m) => {
    const b = h('div', { class: 'msg ' + (m.role === 'user' ? 'me' : 'ai') });
    b.append(m.role === 'user' ? document.createTextNode(m.text) : mdLite(m.text));
    return b;
  };
  const draw = () => {
    list.replaceChildren(
      ...(S.chat.length ? S.chat.map(bubble) : [
        h('div', { class: 'msg ai' }, 'Ciao! Sono il tuo coach. Chiedimi cosa vuoi su esercizi, pesi, recupero o alimentazione. 💪')]));
    window.scrollTo(0, document.body.scrollHeight);
  };

  async function send(text) {
    text = (text || input.value).trim();
    if (!text || busy) return;
    if (!S.settings.apiKey) { toast('Aggiungi la chiave Gemini in Profilo'); return; }
    busy = true; input.value = '';
    S.chat.push({ role: 'user', text }); S.chat = S.chat.slice(-30); save(); draw();
    const wait = h('div', { class: 'msg ai' }, h('div', { class: 'dots-anim' }, h('span'), h('span'), h('span')));
    list.append(wait); window.scrollTo(0, document.body.scrollHeight);
    try {
      const reply = await gemini({ system: coachSystem(), contents: S.chat.map(m => ({ role: m.role, parts: [{ text: m.text }] })) });
      S.chat.push({ role: 'model', text: reply });
    } catch (e) { S.chat.pop(); toast(e.message); input.value = text; }
    S.chat = S.chat.slice(-30); save(); busy = false; draw();
  }
  input.addEventListener('keydown', e => { if (e.key === 'Enter') send(); });

  const sugg = ['Come mi alleno oggi?', 'Quanto peso devo usare?', 'Cosa mangio dopo l\'allenamento?', 'Ho poco tempo, come accorcio?'];
  render(
    h('div', { class: 'row between' }, h('h1', {}, 'Coach'),
      S.chat.length > 0 && h('button', { class: 'btn ghost small', onclick: () => { S.chat = []; save(); viewCoach(); } }, 'Nuova chat')),
    !S.settings.apiKey && h('div', { class: 'card stack' }, h('p', {}, 'Per parlare col coach serve la chiave Gemini (gratuita).'),
      h('a', { class: 'btn small', href: '#/profilo', style: 'text-decoration:none' }, 'Aggiungila in Profilo')),
    list,
    !S.chat.length && h('div', { class: 'chips' }, sugg.map(q => h('button', { class: 'chip', onclick: () => send(q) }, q))),
    h('div', { style: 'height:56px' }),
    h('div', { class: 'composer' }, h('div', { class: 'in' }, input, h('button', { class: 'btn', onclick: () => send() }, 'Invia'))));
  draw();
}

/* ------------------------------------------------------------------ */
/* Profilo                                                             */
/* ------------------------------------------------------------------ */
function viewProfilo() {
  const p = { ...S.profile };
  const sel = (label, key, opts) => h('div', { class: 'stack' }, h('h3', {}, label),
    h('div', { class: 'chips' }, opts.map(([v, t]) => h('button', { class: 'chip' + (p[key] === v ? ' on' : ''), onclick: (e) => {
      p[key] = v; e.target.parentElement.querySelectorAll('.chip').forEach(c => c.classList.remove('on')); e.target.classList.add('on'); } }, t))));
  const keyIn = h('input', { type: 'password', value: S.settings.apiKey, placeholder: 'Chiave API Gemini', autocomplete: 'off' });
  const modelIn = h('input', { type: 'text', value: S.settings.model, autocapitalize: 'off' });
  const note = h('textarea', { placeholder: 'Dolori, infortuni…', value: p.note || '' });
  const saveKeys = () => { S.settings.apiKey = keyIn.value.trim(); S.settings.model = modelIn.value.trim() || 'gemini-flash-latest'; save(); };

  render(
    h('h1', {}, 'Profilo'),
    h('div', { class: 'card stack' }, h('h2', {}, 'Obiettivo e scheda'),
      sel('Obiettivo', 'obiettivo', OBIETTIVI.map(o => [o[0], o[1]])),
      sel('Livello', 'livello', [['principiante', 'Principiante'], ['intermedio', 'Con esperienza']]),
      sel('Giorni a settimana', 'giorni', [[2, '2'], [3, '3'], [4, '4'], [5, '5']]),
      h('label', { class: 'field' }, 'Limiti / infortuni', note),
      h('button', { class: 'btn block', onclick: async () => {
        saveKeys(); S.profile = { ...p, note: note.value }; save();
        if (S.session && !confirm('Hai un allenamento in corso: verrà annullato. Continuare?')) return;
        await buildPlan(); } }, 'Aggiorna e rigenera la scheda')),
    h('div', { class: 'card stack' }, h('h2', {}, 'Coach IA (Gemini)'),
      h('label', { class: 'field' }, 'Chiave API', keyIn),
      h('a', { href: 'https://aistudio.google.com/apikey', target: '_blank', rel: 'noopener', class: 'small' }, 'Crea / vedi la chiave su Google AI Studio →'),
      h('label', { class: 'field' }, 'Modello', modelIn),
      h('div', { class: 'row' },
        h('button', { class: 'btn ghost grow', onclick: async (e) => {
          saveKeys(); e.target.disabled = true; e.target.textContent = 'Provo…';
          try { await gemini({ contents: [{ role: 'user', parts: [{ text: 'Rispondi solo: ok' }] }] }); toast('Collegamento riuscito ✅'); }
          catch (err) { toast(err.message); }
          e.target.disabled = false; e.target.textContent = 'Prova collegamento'; } }, 'Prova collegamento'),
        h('button', { class: 'btn grow', onclick: () => { saveKeys(); toast('Salvato'); } }, 'Salva')),
      h('p', { class: 'muted small' }, 'La chiave è salvata solo su questo telefono e viene inviata solo a Google.')),
    h('div', { class: 'card stack' }, h('h2', {}, 'Dati'),
      h('button', { class: 'btn ghost block', onclick: () => {
        const a = h('a', { href: URL.createObjectURL(new Blob([exportJSON()], { type: 'application/json' })), download: 'gym-coach-backup.json' });
        a.click(); } }, 'Esporta backup'),
      h('button', { class: 'btn danger block', onclick: () => { if (confirm('Cancellare TUTTI i dati (scheda, storico, chiave)?')) { resetAll(); location.hash = ''; location.reload(); } } }, 'Cancella tutto')),
    h('p', { class: 'muted small center' }, 'Immagini esercizi: free-exercise-db (pubblico dominio).'));
}

boot();
