import { S, save, resetAll, exportJSON, importJSON, initStore, lockEnabled, enableLock, disableLock, changePassword } from './store.js';
import { lockScreen, initAutoLock, softLock } from './lock.js';
import { h, icon, toast, openSheet, closeSheet, mdLite } from './ui.js';
import { gemini, listModels, benchModel, aiReady, useProxy, proxyAvailable } from './ai.js';
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

const APP_VERSION = 'v10';

// Errori di Gemini: mostrati per intero e copiabili, per poterli incollare in chat
const errorText = (err) => `Errore Gemini: ${err.message}\nModello: ${S.settings.model}\nApp: ${APP_VERSION}\nOra: ${new Date().toISOString()}`;
async function copyText(txt) {
  try { await navigator.clipboard.writeText(txt); return true; }
  catch {
    const ta = h('textarea', { style: 'position:fixed;opacity:0;top:0' }); ta.value = txt; document.body.append(ta); ta.select();
    let ok = false; try { ok = document.execCommand('copy'); } catch {}
    ta.remove(); return ok;
  }
}
function showError(err) {
  S.lastError = errorText(err); save();
  const box = h('textarea', { readonly: true, rows: 6, onclick: e => e.target.select() }); box.value = S.lastError;
  openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Errore di Gemini'),
    h('p', { class: 'muted small' }, 'Tocca "Copia errore" e incollalo nella chat con me: così capisco subito cosa non va.'), box,
    h('button', { class: 'btn block', onclick: async () => toast((await copyText(S.lastError)) ? 'Copiato! Incollalo nella chat con me' : 'Tieni premuto sul testo e scegli Copia', 4000) }, 'Copia errore'),
    h('button', { class: 'btn ghost block', onclick: closeSheet }, 'Chiudi')));
}

const GRUPPI = ['tutti', 'gambe', 'petto', 'schiena', 'spalle', 'braccia', 'core', 'cardio'];
const OBIETTIVI = [['misto', 'Un po\' di tutto'], ['massa', 'Massa'], ['dimagrire', 'Dimagrire'], ['tonificare', 'Tonificare']];
const CASA_OPT = [['libero', 'Niente (corpo libero)'], ['manubri', 'Manubri']];
const LIVELLI = [['principiante', 'Principiante'], ['intermedio', 'Un po\' di esperienza']];

/* ---------------------------- avvio e navigazione ---------------------------- */
async function boot() {
  try { LIB = await (await fetch('data/exercises.json')).json(); setLib(LIB); }
  catch { render(h('p', { class: 'err' }, 'Impossibile caricare gli esercizi.')); return; }
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
  if (await initStore() === 'locked') await lockScreen({ cold: true });   // password prima di mostrare qualsiasi dato
  initAutoLock();
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
  if (name !== 'allenamento') stopRest();          // il timer vale solo durante l'allenamento
  view.className = (tab ? '' : 'no-tabs') + ' enter';
  clearTimeout(route.t); route.t = setTimeout(() => view.classList.remove('enter'), 800);
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
  const label = () => { btn.textContent = (d.apiKey || useProxy()) ? 'Crea la mia scheda' : 'Crea la scheda (senza IA)'; };
  label();

  async function create() {
    S.settings.apiKey = d.apiKey;
    S.profile = { obiettivo: d.obiettivo, livello: d.livello, giorni: d.giorni, casa: d.casa, peso: parseFloat(d.peso) || 0, note: d.note };
    save();
    await buildPlan();
  }

  render(h('div', { class: 'stack', style: 'gap:22px' },
    h('div', { class: 'brand' }, h('img', { src: 'icons/icon-192.png', alt: '' }), 'Gym Coach'),
    h('div', {}, h('h1', {}, 'Facciamo la tua scheda'), h('p', { class: 'muted' }, 'Ho già scelto per te le opzioni più comuni. Cambia solo se serve.')),
    pick('Obiettivo', 'obiettivo', OBIETTIVI),
    pick('Esperienza', 'livello', LIVELLI),
    pick('Giorni a settimana', 'giorni', [[2, '2'], [3, '3'], [4, '4'], [5, '5']]),
    pick('A casa che attrezzatura hai?', 'casa', CASA_OPT),
    h('label', { class: 'field' }, 'Il tuo peso in kg (per stimare le calorie, facoltativo)',
      h('input', { type: 'number', inputmode: 'decimal', placeholder: '75', oninput: e => d.peso = e.target.value })),
    h('label', { class: 'field' }, 'Dolori o limiti? (facoltativo)',
      h('input', { type: 'text', placeholder: 'Es. mal di schiena', oninput: e => d.note = e.target.value })),
    useProxy()
      ? h('div', { class: 'card stack' }, h('h3', {}, 'Coach IA ✅'), h('p', { class: 'muted small' }, 'Il coach è già collegato: non devi inserire nessuna chiave. I tuoi messaggi al coach passano dal Gemini di chi gestisce l\'app.'))
      : h('div', { class: 'card stack' },
      h('h3', {}, 'Coach IA (gratis)'),
      h('p', { class: 'muted small' }, 'Incolla la chiave di Gemini: serve per la scheda su misura e per la chat col coach. Resta solo sul tuo telefono.'),
      h('input', { type: 'password', placeholder: 'Chiave Gemini', value: d.apiKey, autocomplete: 'off', oninput: e => { d.apiKey = e.target.value.trim(); label(); } }),
      h('a', { class: 'small', href: 'https://aistudio.google.com/apikey', target: '_blank', rel: 'noopener' }, 'Come ottenere la chiave →')),
    btn));
}

async function buildPlan() {
  view.className = 'no-tabs'; renderTabs(null);
  render(h('div', { class: 'center stack', style: 'padding-top:30vh' },
    h('div', { class: 'spin' }), h('h2', {}, 'Il coach prepara la tua scheda…'), h('p', { class: 'muted small' }, 'Al massimo 45 secondi, poi uso una scheda pronta.')));
  let plan, note = '';
  if (aiReady()) {
    try { plan = await aiPlan(S.profile, LIB); }
    catch (e) { S.lastError = errorText(e); note = 'IA non disponibile: ho usato una scheda pronta. Vedi Impostazioni → Avanzate → Copia ultimo errore.'; }
  }
  S.plan = plan || templatePlan(S.profile);
  S.nextDay = 0; S.session = null; S.planBackup = null;
  save();
  if (location.hash === '#/oggi') route(); else go('#/oggi');
  setTimeout(() => toast(note || 'Scheda pronta! 🎉'), 300);
}

/* ---------------------------- Oggi ---------------------------- */
const monday = () => { const d = new Date(); d.setHours(0, 0, 0, 0); d.setDate(d.getDate() - ((d.getDay() + 6) % 7)); return d; };
const thisWeek = () => S.history.filter(w => new Date(w.date).getTime() >= monday().getTime());
const weekCount = () => thisWeek().length;
function weekDots() {
  const mon = monday(), today = new Date().toDateString();
  return h('div', { class: 'days' }, ['L', 'M', 'M', 'G', 'V', 'S', 'D'].map((l, i) => {
    const d = new Date(mon); d.setDate(mon.getDate() + i);
    const done = S.history.some(w => new Date(w.date).toDateString() === d.toDateString());
    return h('div', { class: 'day-dot' + (done ? ' done' : '') + (d.toDateString() === today ? ' today' : '') }, h('i'), l);
  }));
}
const saluto = () => { const hr = new Date().getHours(); return hr < 12 ? 'Buongiorno' : hr < 18 ? 'Buon pomeriggio' : 'Buonasera'; };
const oggiTxt = () => { const t = new Date().toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long' }); return t[0].toUpperCase() + t.slice(1); };

function viewOggi() {
  const day = S.plan.giorni[S.nextDay % S.plan.giorni.length];
  const wk = weekCount(), target = S.profile.giorni;
  const exs = adaptDay(day, S.luogo);
  const kcalWeek = Math.round(thisWeek().reduce((a, w) => a + (w.kcal || 0), 0) / 10) * 10;
  render(
    h('div', { class: 'row between' }, h('div', {}, h('div', { class: 'eyebrow' }, oggiTxt()), h('h1', {}, saluto())), gear()),
    !S.session && luogoSwitch(viewOggi),
    !S.session && homeHint(),
    h('div', { class: 'hero' },
      h('div', { class: 'kicker' }, S.session ? `Allenamento in corso · ${S.session.luogo === 'casa' ? '🏠 Casa' : '🏋️ Palestra'}` : 'Oggi tocca a'),
      h('h1', { class: 'hero-title' }, day.nome),
      h('div', { class: 'meta' }, h('span', {}, '⏱ ' + estMin(exs) + ' min'), h('span', {}, '🔥 ' + kcalTxt(exs)), h('span', {}, '🏋️ ' + exs.length + ' esercizi')),
      h('div', { class: 'chips' }, [...new Set(exs.map(e => EX(e.id)?.gruppo))].filter(Boolean).map(g => h('span', { class: 'chip' }, g))),
      h('button', { class: 'btn big block', onclick: () => { if (!S.session) startSession(S.nextDay % S.plan.giorni.length); go('#/allenamento'); } },
        S.session ? 'Riprendi' : 'Inizia')),
    h('div', { class: 'card stack' },
      h('div', { class: 'row between' }, h('h3', {}, 'Questa settimana'), h('span', { class: 'muted small' }, `${wk} / ${target}${kcalWeek ? ' · ~' + kcalWeek + ' kcal' : ''}`)),
      weekDots()),
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

  const segEls = s.exercises.map((_, i) => h('i', { class: 'seg' + (i === s.cur ? ' cur' : '') }, h('u')));
  const upd = () => s.exercises.forEach((e, i) => { segEls[i].firstChild.style.width = (e.sets.filter(x => x.done).length / e.sets.length * 100) + '%'; });

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
    h('div', { class: 'segs' }, segEls),
    h('button', { class: 'anim-btn', onclick: () => showExercise(ex.id), 'aria-label': 'Come si fa' }, exAnim(info), h('span', { class: 'pill' }, 'Come si fa ›')),
    h('div', {}, h('h1', { class: 'wk-title' }, info.nome), h('p', { class: 'muted' }, `${ex.target.serie} × ${ex.target.ripetizioni}${ex.target.recupero ? ' · recupero ' + ex.target.recupero + 's' : ''}`)),
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
  const C = 2 * Math.PI * 22;
  const ring = h('div', { class: 'ring', html: `<svg viewBox="0 0 52 52"><circle class="bg" cx="26" cy="26" r="22"/><circle class="fg" cx="26" cy="26" r="22" stroke-dasharray="${C}" stroke-dashoffset="0"/></svg>` });
  const fg = ring.querySelector('.fg');
  const draw = () => {
    const left = Math.max(0, Math.ceil((end - Date.now()) / 1000));
    fg.style.strokeDashoffset = C * (1 - Math.min(1, left / Math.max(sec, (end - Date.now()) / 1000)));
    t.textContent = `${Math.floor(left / 60)}:${String(left % 60).padStart(2, '0')}`;
    if (left === 0) { clearInterval(restTimer); restTimer = null; beep(); navigator.vibrate?.([200, 100, 200]); t.textContent = 'Via! 💥'; setTimeout(stopRest, 2500); }
  };
  document.getElementById('rest-root').replaceChildren(h('div', { class: 'rest' }, ring,
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
  const newBtn = h('button', { class: 'btn ghost small', onclick: () => { S.chat = []; save(); draw(); } }, 'Nuova chat');
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
    newBtn.hidden = !S.chat.length;
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
    if (!aiReady()) return toast('Aggiungi la chiave Gemini in Impostazioni');
    busy = true; input.value = '';
    S.chat.push({ role: 'user', text }); S.chat = S.chat.slice(-30); save(); draw();
    const cnt = h('span', { class: 'muted small' });
    list.append(h('div', { class: 'msg ai' }, h('div', { class: 'dots-anim' }, h('span'), h('span'), h('span'), cnt))); bottom();
    const t0 = Date.now();
    const tick = setInterval(() => { const s = Math.round((Date.now() - t0) / 1000); cnt.textContent = s < 4 ? '' : ` ${s} s` + (s >= 15 ? ' · Gemini è lento: prova un modello più veloce in Impostazioni' : ''); }, 500);
    try {
      const hist = S.chat.map(m => ({ role: m.role, parts: [{ text: m.text }] }));
      while (hist.length && hist[0].role !== 'user') hist.shift();
      const raw = await gemini({ system: coachSystem(LIB), contents: hist, json: true, temperature: 0.5 });
      const { text: reply, changes } = parseReply(raw);
      const ok = normChanges(changes, LIB);
      S.chat.push({ role: 'model', text: reply, ...(ok.length ? { proposal: { status: 'pending', changes: ok } } : {}) });
    } catch (e) { S.chat.pop(); input.value = text; showError(e); }
    clearInterval(tick); S.chat = S.chat.slice(-30); save(); busy = false; draw();
  }
  input.addEventListener('keydown', e => { if (e.key === 'Enter') send(); });

  const sugg = ['Mi fa male una cosa', 'Cambia un esercizio', 'Ho poco tempo oggi', 'Mi sembra troppo facile'];
  render(
    h('div', { class: 'row between' },
      h('div', { class: 'coach-head' }, h('div', { class: 'avatar' }, icon('dumbbell')), h('div', {}, h('h1', {}, 'Coach'), h('div', { class: 'eyebrow', style: 'text-transform:none' }, 'Ti rispondo anche per cambiare la scheda'))),
      h('div', { class: 'row', style: 'gap:8px' },
        newBtn, gear())),
    !aiReady() && h('div', { class: 'card stack' }, h('p', {}, 'Per parlare col coach serve la chiave Gemini (gratuita).'),
      h('a', { class: 'btn small', href: '#/profilo' }, 'Aggiungila qui')),
    list,
    h('div', { class: 'chips' }, sugg.map(q => h('button', { class: 'chip', onclick: () => send(q) }, q))),
    h('div', { style: 'height:64px' }),
    h('div', { class: 'composer' }, h('div', { class: 'in' }, input, h('button', { class: 'btn', onclick: () => send() }, 'Invia'))));
  draw();
}

function downloadFile(name, text, type = 'application/json') {
  const a = h('a', { href: URL.createObjectURL(new Blob([text], { type })), download: name }); document.body.append(a); a.click(); a.remove();
}

/* ---------------------------- sicurezza: blocco con password ---------------------------- */
const MIN_PW = 8;
function securityCard() {
  const box = h('div', { class: 'stack' });
  const pwField = (label, ac) => h('label', { class: 'field' }, label, h('input', { type: 'password', autocomplete: ac, autocapitalize: 'off' }));
  const val = (l) => l.querySelector('input').value;

  function setupSheet() {
    const p1 = pwField('Scegli una password (almeno 8 caratteri)', 'new-password'), p2 = pwField('Ripeti la password', 'new-password');
    const ack = h('input', { type: 'checkbox' });
    const err = h('p', { class: 'err' });
    const btn = h('button', { class: 'btn block', onclick: async () => {
      err.textContent = '';
      if (val(p1).length < MIN_PW) return err.textContent = `Usa almeno ${MIN_PW} caratteri (meglio una frase facile da ricordare).`;
      if (val(p1) !== val(p2)) return err.textContent = 'Le due password non coincidono.';
      if (!ack.checked) return err.textContent = 'Conferma di aver capito che la password non si può recuperare.';
      btn.disabled = true; btn.textContent = 'Cifro i dati…';
      await enableLock(val(p1)); closeSheet(); draw(); toast('Blocco attivato ✅');
    } }, 'Attiva il blocco');
    openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Blocco con password'),
      h('p', { class: 'muted small' }, 'I dati sul telefono vengono cifrati: senza la password nessuno può leggerli, nemmeno guardando i file.'),
      h('div', { class: 'tip' }, '⚠️ La password NON si può recuperare. Se la dimentichi, i dati vanno persi e si ricomincia da zero. Esporta un backup prima (Avanzate → Esporta backup).'),
      p1, p2, h('label', { class: 'check' }, ack, h('span', {}, 'Ho capito che se dimentico la password perdo i dati.')), err, btn));
  }
  function changeSheet() {
    const o = pwField('Password attuale', 'current-password'), n1 = pwField('Nuova password (almeno 8 caratteri)', 'new-password'), n2 = pwField('Ripeti la nuova password', 'new-password');
    const err = h('p', { class: 'err' });
    const btn = h('button', { class: 'btn block', onclick: async () => {
      err.textContent = '';
      if (val(n1).length < MIN_PW) return err.textContent = `Usa almeno ${MIN_PW} caratteri.`;
      if (val(n1) !== val(n2)) return err.textContent = 'Le due password non coincidono.';
      btn.disabled = true; btn.textContent = 'Controllo…';
      if (await changePassword(val(o), val(n1))) { closeSheet(); toast('Password cambiata ✅'); }
      else { err.textContent = 'La password attuale non è corretta.'; btn.disabled = false; btn.textContent = 'Cambia password'; }
    } }, 'Cambia password');
    openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Cambia password'), o, n1, n2, err, btn));
  }
  function disableSheet() {
    const o = pwField('Password attuale', 'current-password'); const err = h('p', { class: 'err' });
    const btn = h('button', { class: 'btn danger block', onclick: async () => {
      btn.disabled = true; btn.textContent = 'Controllo…';
      if (await disableLock(val(o))) { closeSheet(); draw(); toast('Blocco disattivato'); }
      else { err.textContent = 'Password non corretta.'; btn.disabled = false; btn.textContent = 'Disattiva il blocco'; }
    } }, 'Disattiva il blocco');
    openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Disattiva il blocco'), h('p', { class: 'muted small' }, 'I dati tornano in chiaro sul telefono.'), o, err, btn));
  }

  function draw() {
    if (!lockEnabled()) {
      box.replaceChildren(
        h('p', { class: 'muted small' }, 'Proteggi i tuoi dati con una password: viene chiesta all\'apertura dell\'app e dopo un po\' che resta in background. I dati sul telefono vengono cifrati.'),
        h('button', { class: 'btn block', onclick: setupSheet }, 'Attiva il blocco con password'));
      return;
    }
    box.replaceChildren(
      h('p', {}, 'Blocco attivo ✅  ', h('span', { class: 'muted small' }, 'dati cifrati')),
      h('div', { class: 'stack' }, h('h3', {}, 'Chiedi la password'),
        h('div', { class: 'chips' }, [[0, 'Ogni volta'], [1, 'Dopo 1 min'], [5, 'Dopo 5 min'], [15, 'Dopo 15 min'], [-1, 'Solo all\'apertura']].map(([v, t]) =>
          h('button', { class: 'chip' + (S.security.autoLockMin === v ? ' on' : ''), onclick: () => { S.security.autoLockMin = v; save(); draw(); } }, t)))),
      h('button', { class: 'btn ghost block', onclick: () => softLock() }, 'Blocca ora'),
      h('button', { class: 'btn ghost block', onclick: changeSheet }, 'Cambia password'),
      h('button', { class: 'btn danger block', onclick: disableSheet }, 'Disattiva il blocco'));
  }
  draw();
  return h('div', { class: 'card stack' }, h('h2', {}, 'Sicurezza'), box);
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
  const saveKeys = () => { if (!proxyAvailable() || S.settings.ownKey) S.settings.apiKey = keyIn.value.trim(); S.settings.model = modelIn.value.trim() || 'gemini-flash-latest'; save(); };

  render(
    h('div', { class: 'row' }, h('a', { class: 'iconbtn', href: '#/oggi', 'aria-label': 'Indietro' }, '‹'), h('h1', {}, 'Impostazioni')),
    securityCard(),
    bodyCard(),
    remindersCard(),
    h('div', { class: 'card stack' }, h('h2', {}, 'Casa'),
      h('div', { class: 'stack' }, h('h3', {}, 'Attrezzatura a casa'),
        h('div', { class: 'chips' }, CASA_OPT.map(([v, t]) => h('button', { class: 'chip lg' + ((S.profile.casa || 'libero') === v ? ' on' : ''), onclick: (e) => {
          S.profile.casa = v; save(); e.target.parentElement.querySelectorAll('.chip').forEach(c => c.classList.remove('on')); e.target.classList.add('on'); toast('Salvato'); } }, t)))),
    ),
    h('div', { class: 'card stack' }, h('h2', {}, 'Coach IA (Gemini)'),
      proxyAvailable() && h('div', { class: 'stack' },
        h('div', { class: 'chips' }, [[false, 'Coach condiviso'], [true, 'La mia chiave']].map(([v, t]) =>
          h('button', { class: 'chip lg' + (!!S.settings.ownKey === v ? ' on' : ''), onclick: () => { S.settings.ownKey = v; save(); viewProfilo(); } }, t))),
        !S.settings.ownKey && h('p', { class: 'muted small' }, 'Nessuna chiave da inserire: il coach usa il Gemini collegato all\'app. I tuoi messaggi passano da lì.')),
      (!proxyAvailable() || S.settings.ownKey) && h('label', { class: 'field' }, 'Chiave API', keyIn),
      (!proxyAvailable() || S.settings.ownKey) && h('a', { href: 'https://aistudio.google.com/apikey', target: '_blank', rel: 'noopener', class: 'small' }, 'Crea / vedi la chiave su Google AI Studio →'),
      h('div', { class: 'row' },
        h('button', { class: 'btn ghost grow', onclick: async (e) => {
          saveKeys(); e.target.disabled = true; e.target.textContent = 'Provo…';
          const t0 = Date.now();
          try { await gemini({ contents: [{ role: 'user', parts: [{ text: 'Rispondi solo: ok' }] }] }); toast(`Collegamento riuscito ✅ (${((Date.now() - t0) / 1000).toFixed(1)} s)`); }
          catch (err) { showError(err); }
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
        S.lastError && h('button', { class: 'btn ghost block', onclick: async () => toast((await copyText(S.lastError)) ? 'Errore copiato: incollalo nella chat con me' : 'Copia non riuscita', 4000) }, 'Copia ultimo errore'),
        h('label', { class: 'field' }, 'Modello Gemini', modelIn),
        h('button', { class: 'btn block', onclick: async () => {
          saveKeys();
          let names; try { names = await listModels(); } catch (err) { return toast(err.message); }
          names = [...names.filter(n => /lite/.test(n)), ...names.filter(n => !/lite/.test(n))].slice(0, 8);
          const box = h('div', { class: 'stack' });
          openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Velocità dei modelli'),
            h('p', { class: 'muted small' }, 'Misuro quanto ci mette ognuno a rispondere. Tocca quello che vuoi usare (più basso = più veloce).'), box));
          const rows = names.map(n => {
            const t = h('span', { class: 'muted small' }, 'in attesa…');
            const b = h('button', { class: 'ex-item', disabled: true, onclick: () => { modelIn.value = n; saveKeys(); closeSheet(); toast('Modello: ' + n); } },
              h('div', { class: 'grow' }, h('h3', {}, n), n === S.settings.model && h('div', { class: 'muted small' }, 'in uso')), t);
            box.append(b); return { n, t, b };
          });
          for (const r of rows) {
            r.t.textContent = 'provo…';
            const res = await benchModel(r.n);
            if (!document.querySelector('.sheet')) return;          // pannello chiuso: smetto di misurare
            r.t.textContent = res.sec != null ? res.sec.toFixed(1) + ' s' : 'non funziona';
            if (res.sec != null) { r.b.disabled = false; r.t.style.color = res.sec < 6 ? 'var(--accent)' : ''; }
          }
        } }, 'Trova il modello più veloce'),
        h('button', { class: 'btn ghost block', onclick: async (e) => {
          saveKeys(); e.target.disabled = true; e.target.textContent = 'Cerco i modelli…';
          try {
            const list = await listModels();
            openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Scegli il modello'),
              h('p', { class: 'muted small' }, 'I "flash" sono i più veloci. Se uno è lento, provane un altro.'),
              list.map(n => h('button', { class: 'ex-item', onclick: () => { modelIn.value = n; saveKeys(); closeSheet(); toast('Modello: ' + n); } },
                h('div', { class: 'grow' }, h('h3', {}, n), n === S.settings.model && h('div', { class: 'muted small' }, 'in uso'))))));
          } catch (err) { toast(err.message); }
          e.target.disabled = false; e.target.textContent = 'Scegli il modello'; } }, 'Scegli il modello'),
        h('button', { class: 'btn ghost block', onclick: () => { saveKeys(); downloadFile('gym-coach-backup.json', exportJSON()); toast('Backup salvato (senza la chiave Gemini). Conservalo con cura: non è cifrato.', 5000); } }, 'Esporta backup'),
        h('label', { class: 'btn ghost block' }, 'Importa backup',
          h('input', { type: 'file', accept: 'application/json,.json', hidden: true, onchange: async (e) => {
            const f = e.target.files[0]; if (!f) return;
            if (!confirm('Sostituire i dati attuali con quelli del backup?')) return;
            try { importJSON(await f.text()); toast('Backup importato'); setTimeout(() => { location.hash = '#/oggi'; location.reload(); }, 600); } catch (err) { toast(err.message); }
          } })),
        h('button', { class: 'btn danger block', onclick: () => { if (confirm('Cancellare TUTTI i dati (scheda, storico, chiave)?')) { resetAll(); location.hash = ''; location.reload(); } } }, 'Cancella tutto'))),
    h('p', { class: 'muted small center' }, 'Immagini esercizi: free-exercise-db (pubblico dominio).'));
}

boot();
