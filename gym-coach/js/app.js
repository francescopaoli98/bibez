import { S, save, resetAll, exportJSON, importJSON, initStore, lockEnabled, enableLock, disableLock, changePassword, unlock, setUser, hasUserData, deviceInfo, rememberDevice, forgetDevice, unlockWithDevice } from './store.js';
import { bioAvailable, bioRegister } from './bio.js';
import { lockScreen, loginScreen, initAutoLock, softLock, setUnlockHook } from './lock.js';
import { accountsMode, knownUsers, rememberUser, lastUser, forgetLast, getSession, setSession, refreshSession, changeAccountPassword } from './account.js';
import { h, icon, tile, toast, openSheet, closeSheet, mdLite } from './ui.js';
import { gemini, listModels, benchModel, aiReady, useProxy, proxyAvailable, lastTiming, expert } from './ai.js';
import { templatePlan, aiPlan } from './plans.js';
import { isTime, topReps, suggestion, startSession, adaptDay, estKcal, estMin, setLib } from './training.js';
import { targets } from './nutrition.js';
import { applyTheme, setTheme, getTheme, PRESETS, BACKGROUNDS } from './theme.js';
import { initSound, play, buzz } from './sound.js';
import { countUps, confetti } from './fx.js';
import { initInstall } from './install.js';
import * as Sal from './salute.js';
import { viewProgressi } from './progress.js';
import { remindersCard } from './reminders.js';
import * as Chats from './chats.js';
import { voiceMode, startVoice } from './voice.js';
import { coachSystem, parseReply, normChanges, applyChanges, undoChanges } from './coach.js';

let LIB = [];
let needReload = false;
const EX = (id) => LIB.find(e => e.id === id);
const view = document.getElementById('view');
const tabsEl = document.getElementById('tabs');
// Come replaceChildren ma ignora false/null (utile per i blocchi condizionali)
const render = (...kids) => view.replaceChildren(...kids.flat(Infinity).filter(k => k != null && k !== false));
const go = (hash) => { location.hash = hash; };

let APP_VERSION = '?';                                  // si legge da sw.js all'avvio

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
  S.lastError = errorText(err) + (S.lastBench ? '\nProve modelli:\n' + S.lastBench : ''); save();
  const box = h('textarea', { readonly: true, rows: 6, onclick: e => e.target.select() }); box.value = S.lastError;
  if (!expert()) return openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Il coach non risponde'),
    h('p', {}, 'Succede ogni tanto. Aspetta un momento e riprova: di solito passa da solo.'),
    h('button', { class: 'btn big block', onclick: closeSheet }, 'Ho capito'),
    h('button', { class: 'btn ghost small', onclick: async () => toast((await copyText(S.lastError)) ? 'Copiato: mandalo a Francesco' : 'Copia non riuscita', 4000) }, 'Copia i dettagli per Francesco')));
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
  applyTheme(); initSound();                      // colori e suoni scelti, subito
  fetch('sw.js').then(r => r.text()).then(t => { APP_VERSION = /VERSION = '([^']+)'/.exec(t)?.[1] || '?'; }).catch(() => {});
  try { LIB = await (await fetch('data/exercises.json')).json(); setLib(LIB); }
  catch { render(h('p', { class: 'err' }, 'Impossibile caricare gli esercizi.')); return; }
  if ('serviceWorker' in navigator) {
    const had = !!navigator.serviceWorker.controller;
    navigator.serviceWorker.register('sw.js').then(r => r.update()).catch(() => {});
    // c'è una versione nuova: ricarico da solo appena si può (non durante un allenamento)
    navigator.serviceWorker.addEventListener('controllerchange', () => { if (had) needReload = true; });
  }
  if (accountsMode()) await accessFlow();                                  // account dell'app (sito su Cloudflare)
  else if (await initStore() === 'locked') await lockScreen({ cold: true });   // solo password
  initAutoLock();
  window.addEventListener('hashchange', route);
  route();
  initInstall();
}

// Resta connesso: dopo il primo accesso la chiave resta sul telefono (90 giorni, riparte a ogni apertura)
async function keepSignedIn() {
  if (S.security.stay === false) return;
  const dev = await deviceInfo();
  if (!dev) await rememberDevice(S.security.stayDays || 90);
}

// Accesso con account: prima volta = nome utente e password (controllati dal server); poi basta l'impronta, o niente
async function accessFlow() {
  setUnlockHook(pw => { const s = getSession(); if (s) s.pw = pw; });
  let pick = lastUser();
  for (;;) {
    const known = knownUsers(), k = known.find(x => x.u === pick);
    if (k && hasUserData(k.u)) {
      setUser(k.u);
      const dev = await deviceInfo();
      let r = null;
      if (dev && !dev.cred && await unlockWithDevice()) r = { password: null };               // resta connesso: si apre da solo
      if (!r) r = await lockScreen({ cold: true, title: `Ciao ${k.name}`, canSwitch: true, bio: dev?.cred || null });
      if (r === 'switch') { pick = ''; forgetLast(); continue; }
      rememberDevice0(r);
      rememberUser(k.u, k.name);                         // alla prossima apertura si parte da questo account
      setSession({ user: k.u, name: S.account?.name || k.name, token: S.account?.token, exp: S.account?.exp, pw: r.password || undefined });
      refreshSession().catch(() => {});                  // rinnova l'accesso in silenzio (se sei offline resta quello di prima)
      return;
    }
    const res = await loginScreen({ known: known.filter(x => hasUserData(x.u)) });
    if (res.pick) { pick = res.pick; continue; }
    setUser(res.user);
    if (hasUserData(res.user)) {                         // c'erano già dati di questa persona su questo telefono
      if (!(await unlock(res.password))) { pick = res.user; rememberUser(res.user, res.name); toast('La password è diversa da quella usata qui prima: inserisci quella vecchia.', 6000); continue; }
    } else { await initStore(); await enableLock(res.password); }
    S.account = { user: res.user, name: res.name, token: res.token, exp: res.exp };
    S.profile && !S.profile.nome && (S.profile.nome = res.name);
    save(); rememberUser(res.user, res.name);
    await keepSignedIn();
    setSession({ ...S.account, pw: res.password });
    return;
  }
}
// dopo uno sblocco con password: ricrea la chiave del dispositivo se manca (es. scaduta)
function rememberDevice0(r) { if (r?.password) keepSignedIn().catch(() => {}); }

const ROUTES = { oggi: viewOggi, scheda: viewScheda, esercizi: viewEsercizi, coach: viewCoach, progressi: () => viewProgressi({ render, LIB, go }),
                 profilo: viewProfilo, allenamento: viewAllenamento, benvenuto: viewOnboarding, guida: viewGuida };
const TAB_OF = { oggi: 'oggi', profilo: 'oggi', progressi: 'progressi', scheda: 'scheda', esercizi: 'scheda', coach: 'coach' };

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
  if (needReload && !S.session && (name === 'oggi' || name === 'scheda' || name === 'coach' || name === 'progressi')) { needReload = false; location.reload(); return; }
  window.scrollTo(0, 0);
  ROUTES[name]();
  countUps(view);                                 // i numeri salgono da 0
}

function renderTabs(active) {
  tabsEl.hidden = !active;
  if (!active) return;
  const items = [['oggi', 'Oggi', 'oggi'], ['scheda', 'Scheda', 'scheda'], ['coach', 'Coach', 'coach'], ['progressi', 'Progressi', 'prog']];
  tabsEl.replaceChildren(h('div', { class: 'inner' }, items.map(([k, label, ic]) =>
    h('a', { class: 'tab' + (k === active ? ' on' : ''), href: '#/' + k }, tile(ic, 20), label))));
}

// Interruttore Palestra / Casa
function luogoSwitch(redraw) {
  return h('div', { class: 'seg' }, [['palestra', 'Palestra'], ['casa', 'Casa']].map(([v, t]) =>
    h('button', { class: 'seg-b' + ((S.luogo || 'palestra') === v ? ' on' : ''), onclick: () => { S.luogo = v; save(); redraw(); } }, tile(v, 16), t)));
}
const homeHint = () => (S.luogo === 'casa' && (S.profile.casa || 'libero') === 'libero')
  ? h('p', { class: 'muted small' }, 'A casa uso esercizi a corpo libero. Hai dei manubri? ', h('a', { href: '#/profilo' }, 'Dillo qui'))
  : null;
const kcalTxt = (exs) => `~${estKcal(exs)} kcal`;

const gear = () => h('a', { class: 'iconbtn', href: '#/profilo', 'aria-label': 'Impostazioni' }, icon('gear'));

// Aiuto: spiegazioni brevi, in parole semplici, per ogni schermata
const HELP = {
  oggi: ['Oggi', ['Qui vedi l\'allenamento di oggi.', 'Tocca il grande pulsante verde per cominciare: l\'app ti guida un esercizio alla volta.', 'I cerchi della settimana si colorano a ogni allenamento fatto.', 'In alto a destra, l\'ingranaggio apre le impostazioni.']],
  scheda: ['Scheda', ['Qui c\'è tutta la tua scheda, giorno per giorno.', 'Tocca un esercizio per vedere come si fa.', '"Palestra" o "Casa": scegli dove ti alleni, gli esercizi si adattano da soli.', 'Vuoi cambiare qualcosa? Tocca "Chiedi al coach di cambiarla".']],
  coach: ['Coach', ['Scrivi al coach come parleresti a una persona.', 'Per esempio: "mi fa male la spalla" o "ho poco tempo oggi".', 'Se serve cambiare la scheda, il coach te lo dice prima e aspetta il tuo "sì".', 'Toccando il titolo vedi le chat vecchie. Con + ne inizi una nuova.']],
  progressi: ['Progressi', ['Qui vedi come stai andando.', 'Scrivi il tuo peso ogni settimana: il grafico ti mostra il cambiamento.', 'Il grafico "Forza" sale quando riesci a sollevare di più.', 'In fondo trovi tutti gli allenamenti fatti.']],
  allenamento: ['Durante l\'allenamento', ['Guarda la foto: è l\'esercizio da fare. "Come si fa" ti spiega i passi.', 'Fai la serie, poi tocca ✓. Il riposo parte da solo e alla fine senti un suono.', 'I numeri sono già scritti: cambiali solo se hai usato un peso diverso.', 'Quando hai finito tocca "Prossimo esercizio".']],
};
function helpBtn(topic) {
  return h('button', { class: 'helpbtn', onclick: () => {
    const [title, lines] = HELP[topic];
    openSheet(h('div', { class: 'stack' }, h('h2', {}, title), h('ul', { class: 'helplist' }, lines.map(l => h('li', {}, l))), h('button', { class: 'btn big block', onclick: closeSheet }, 'Ho capito')));
  } }, tile('aiuto', 14), 'Aiuto');
}

/* ---------------------------- dettaglio esercizio ---------------------------- */
const exAnim = (ex) => h('div', { class: 'anim' }, ex.img.map(src => h('img', { src, alt: ex.nome })));

function showExercise(id) {
  const ex = EX(id); if (!ex) return;
  openSheet(h('div', { class: 'stack' },
    exAnim(ex),
    h('div', {}, h('h2', {}, ex.nome), h('p', { class: 'muted small' }, `${ex.muscoli} · ${ex.attrezzo}`)),
    h('ol', { class: 'steps' }, ex.passi.map(p => h('li', {}, p))),
    h('div', { class: 'tip row', style: 'gap:10px;align-items:flex-start' }, tile('idea', 16), h('span', {}, ex.consiglio)),
    h('a', { class: 'btn ghost block', href: ex.video, target: '_blank', rel: 'noopener' }, '▶ Guarda il video su YouTube'),
    h('button', { class: 'btn block', onclick: closeSheet }, 'Chiudi')));
}

function exRow(id, subtitle, onclick) {
  const ex = EX(id);
  return h('button', { class: 'ex-item', onclick: onclick || (() => showExercise(id)) },
    h('img', { class: 'thumb', src: ex.img[0], alt: '', loading: 'lazy' }),
    h('div', { class: 'grow' }, h('h3', {}, ex.nome), h('div', { class: 'muted small' }, subtitle || ex.muscoli)));
}

/* ---------------------------- primo avvio: "Prima di iniziare" ---------------------------- */
const inp = (props) => h('input', { class: 'bigin', type: 'number', inputmode: 'decimal', ...props });
const condBtn = (txt, on, onclick) => h('button', { class: 'cond' + (on ? ' on' : ''), role: 'checkbox', 'aria-checked': String(on), onclick }, h('i', {}, on ? '✓' : ''), txt);
const privacyBox = (txt) => h('div', { class: 'privacy' }, icon('heart'), h('span', {}, txt));

function viewOnboarding() {
  const d = { peso: '', altezza: '', eta: '', sesso: '', cond: new Set(), altro: '', farmaci: null, farmaciNote: '', ack: false,
              obiettivo: 'misto', livello: 'intermedio', giorni: 3, casa: 'libero', apiKey: S.settings.apiKey || '' };
  let step = 0, err = '';
  const salute = () => ({ condizioni: [...d.cond], altro: d.altro.trim(), farmaci: d.farmaci === true, farmaciNote: d.farmaciNote.trim() });
  const advice = () => Sal.hasAny(salute());                      // se c'è qualcosa da segnalare, c'è la schermata "consiglio"
  const order = () => advice() ? ['dati', 'salute', 'consiglio', 'obiettivi'] : ['dati', 'salute', 'obiettivi'];
  const pick = (title, key, opts) => {
    const box = h('div', { class: 'chips' });
    const drawc = () => box.replaceChildren(...opts.map(([v, t]) => h('button', { class: 'chip lg' + (d[key] === v ? ' on' : ''), onclick: () => { d[key] = v; drawc(); } }, t)));
    drawc(); return h('div', { class: 'stack' }, h('h3', {}, title), box);
  };

  function valid(name) {
    if (name === 'dati') {
      const p = parseFloat(d.peso), al = parseFloat(d.altezza), e = parseInt(d.eta);
      if (!(p >= 30 && p <= 300)) return 'Scrivi il tuo peso in chili (per esempio 70).';
      if (!(al >= 120 && al <= 230)) return 'Scrivi la tua altezza in centimetri (per esempio 170).';
      if (!(e >= 14 && e <= 100)) return 'Scrivi quanti anni hai.';
      if (!d.sesso) return 'Scegli uomo o donna (serve per calcolare le calorie).';
    }
    if (name === 'salute' && d.farmaci === null) return 'Rispondi: prendi dei farmaci? (Sì o No)';
    if (name === 'consiglio' && !d.ack) return 'Tocca la casella per confermare di aver letto.';
    return '';
  }

  function draw() {
    const names = order(), name = names[step], last = step === names.length - 1;
    const body = [];
    if (name === 'dati') body.push(
      h('div', {}, h('h1', {}, 'I tuoi dati'), h('p', { class: 'lead' }, 'Servono per calcolare le calorie e per consigliarti bene. Puoi cambiarli quando vuoi.')),
      h('label', { class: 'field2' }, 'Quanto pesi?', h('small', {}, 'Scrivi il peso in chili'), h('div', { class: 'inpbox' }, inp({ placeholder: '70', value: d.peso, oninput: e => d.peso = e.target.value }), h('span', {}, 'kg'))),
      h('label', { class: 'field2' }, 'Quanto sei alto/a?', h('div', { class: 'inpbox' }, inp({ placeholder: '170', value: d.altezza, oninput: e => d.altezza = e.target.value }), h('span', {}, 'cm'))),
      h('div', { class: 'row', style: 'gap:12px;align-items:flex-end' },
        h('label', { class: 'field2 grow' }, 'Anni', h('div', { class: 'inpbox' }, inp({ placeholder: '30', value: d.eta, oninput: e => d.eta = e.target.value }))),
        h('div', { class: 'field2 grow' }, 'Sesso', (() => { const bx = h('div', { class: 'chips' }); const dr = () => bx.replaceChildren(...[['uomo', 'Uomo'], ['donna', 'Donna']].map(([v, t]) => h('button', { class: 'chip lg' + (d.sesso === v ? ' on' : ''), onclick: () => { d.sesso = v; dr(); } }, t))); dr(); return bx; })())));
    if (name === 'salute') body.push(
      h('div', {}, h('h1', {}, 'La tua salute'), h('p', { class: 'lead' }, 'Tocca quello che hai. Se non hai niente, vai avanti.')),
      h('div', { class: 'stack', style: 'gap:10px' }, Sal.CONDIZIONI.map(([k, t]) => condBtn(t, d.cond.has(k), () => { d.cond.has(k) ? d.cond.delete(k) : d.cond.add(k); err = ''; draw(); }))),
      d.cond.has('altro') && h('input', { type: 'text', class: 'bigtext', placeholder: 'Cosa? (anche solo una parola)', value: d.altro, oninput: e => d.altro = e.target.value }),
      h('div', { class: 'field2' }, 'Prendi dei farmaci?', h('div', { class: 'row', style: 'gap:10px' }, [[true, 'Sì'], [false, 'No']].map(([v, t]) => h('button', { class: 'chip lg' + (d.farmaci === v ? ' on' : ''), onclick: () => { d.farmaci = v; err = ''; draw(); } }, t)))),
      d.farmaci === true && h('input', { type: 'text', class: 'bigtext', placeholder: 'Quali? (anche solo il nome)', value: d.farmaciNote, oninput: e => d.farmaciNote = e.target.value }),
      privacyBox('Queste informazioni restano solo sul tuo telefono, cifrate. Le legge il coach per essere prudente con te. Non sostituiscono il parere del medico.'));
    if (name === 'consiglio') {
      const s = salute(), items = [...s.condizioni.filter(k => k !== 'altro').map(k => Sal.label(k).toLowerCase()), ...(s.altro ? [s.altro] : []), ...(s.farmaci ? ['farmaci'] : [])];
      body.push(
        h('div', {}, h('h1', {}, 'Un consiglio importante')),
        h('div', { class: 'warn' }, icon('warn'), h('span', {}, 'Hai indicato: ', h('b', {}, items.join(', ')), '.', h('br'), h('br'), 'Prima di iniziare ti consiglio di ', h('b', {}, 'parlarne con il tuo medico'), ' e chiedergli se puoi fare attività fisica in palestra.')),
        privacyBox('Il coach terrà conto di quello che hai scritto: sceglierà esercizi più dolci e ti dirà di fermarti se qualcosa non va.'),
        condBtn('Ho capito: parlerò con il mio medico.', d.ack, () => { d.ack = !d.ack; err = ''; draw(); }));
    }
    if (name === 'obiettivi') body.push(
      h('div', {}, h('h1', {}, 'Il tuo obiettivo'), h('p', { class: 'lead' }, 'Ho già scelto le opzioni più comuni. Cambia solo se serve.')),
      pick('Obiettivo', 'obiettivo', OBIETTIVI), pick('Esperienza', 'livello', LIVELLI), pick('Giorni a settimana', 'giorni', [[2, '2'], [3, '3'], [4, '4'], [5, '5']]), pick('A casa che attrezzatura hai?', 'casa', CASA_OPT),
      useProxy()
        ? h('div', { class: 'card stack' }, h('h3', {}, 'Coach IA ✅'), h('p', { class: 'muted small' }, 'Il coach è già collegato: non devi inserire nessuna chiave. I tuoi messaggi al coach passano dal Gemini di chi gestisce l\'app.'))
        : h('div', { class: 'card stack' }, h('h3', {}, 'Coach IA (gratis)'),
            h('p', { class: 'muted small' }, 'Incolla la chiave di Gemini: serve per la scheda su misura e per la chat col coach. Resta solo sul tuo telefono.'),
            h('input', { type: 'password', placeholder: 'Chiave Gemini', value: d.apiKey, autocomplete: 'off', oninput: e => d.apiKey = e.target.value.trim() }),
            h('a', { class: 'small', href: 'https://aistudio.google.com/apikey', target: '_blank', rel: 'noopener' }, 'Come ottenere la chiave →')));

    render(h('div', { class: 'wizard' },
      h('div', { class: 'stepbar' }, names.map((_, i) => h('i', { class: i <= step ? 'on' : '' }))),
      ...body, err && h('p', { class: 'err', role: 'alert' }, err),
      h('div', { class: 'row', style: 'gap:10px;margin-top:6px' },
        step > 0 && h('button', { class: 'btn ghost', style: 'min-height:64px', 'aria-label': 'Indietro', onclick: () => { err = ''; step--; draw(); window.scrollTo(0, 0); } }, '‹'),
        h('button', { class: 'btn big grow', style: 'min-height:64px;font-size:20px', onclick: next }, last ? (d.apiKey || useProxy() ? 'Crea la mia scheda' : 'Crea la scheda (senza IA)') : 'Avanti'))));
  }

  async function next() {
    const names = order(), name = names[step];
    err = valid(name);
    if (err) { draw(); return; }
    if (step < names.length - 1) { step++; err = ''; draw(); window.scrollTo(0, 0); return; }
    const sal = { ...salute(), medico: d.ack, aggiornata: new Date().toISOString() };
    S.settings.apiKey = d.apiKey;
    S.profile = { nome: S.account?.name || '', obiettivo: d.obiettivo, livello: d.livello, giorni: d.giorni, casa: d.casa,
                  peso: parseFloat(d.peso), altezza: parseFloat(d.altezza), eta: parseInt(d.eta), sesso: d.sesso, salute: sal, note: Sal.hasAny(sal) ? Sal.summary(sal) : '' };
    S.pesi = [{ date: new Date().toISOString(), kg: S.profile.peso }];
    save();
    await buildPlan();
  }
  draw();
}

// Cerca un modello veloce (prima i "lite"): lo misura con una domanda minuscola e prende il primo sotto i 15 secondi
async function pickFastModel() {
  // provo insieme fino a 5 modelli (prima quelli "lite" e stabili) e prendo il più veloce che risponde
  try {
    const names = await listModels();
    const rank = n => (/lite/.test(n) ? 0 : 2) + (/preview|exp|latest/.test(n) ? 1 : 0);
    const cand = names.filter(n => n !== S.settings.model).sort((x, y) => rank(x) - rank(y)).slice(0, 5);
    const res = await Promise.all(cand.map(benchModel));
    S.lastBench = new Date().toISOString() + '\n' + res.map(r => `${r.name}: ${r.sec != null ? r.sec.toFixed(1) + ' s' : (r.err || 'errore')}`).join('\n'); save();
    const ok = res.filter(r => r.sec != null && r.sec < 20).sort((x, y) => x.sec - y.sec);
    if (ok.length) return ok[0].name;
  } catch (e) { S.lastBench = 'Elenco modelli: ' + e.message; save(); }
  return null;
}

// Schermata di attesa: barra con percentuale (stima del tempo) e quattro passi che si spuntano, con il nome della persona
function loadingScreen() {
  const nome = utente();
  const pct = h('div', { class: 'pct' }, '0%'), fill = h('i', { style: 'width:0%' });
  const title = h('h1', {}, nome ? `${nome}, il coach prepara la tua scheda` : 'Il coach prepara la tua scheda');
  const sub = h('p', { class: 'lead' }, 'Ci vogliono circa 20 secondi. Se il coach è lento, uso una scheda pronta.');
  const ico = h('div', { class: 'big-ic' }, '🧠');
  const rows = ['Leggo i tuoi dati', 'Scelgo gli esercizi giusti per te', 'Preparo i giorni di allenamento', 'Controllo che sia tutto sicuro'].map(t => h('div', { class: 'todo' }, h('span', { class: 'd' }), t));
  view.className = 'no-tabs'; renderTabs(null);
  render(h('div', { class: 'load' }, ico, h('div', {}, title, sub),
    h('div', { class: 'stack', style: 'gap:10px' }, pct, h('div', { class: 'pbar', role: 'progressbar', 'aria-valuemin': '0', 'aria-valuemax': '100', 'aria-label': 'Preparazione della scheda' }, fill)),
    h('div', { class: 'steps4' }, rows)));
  const apply = (p) => {
    fill.style.width = p + '%'; pct.textContent = Math.round(p) + '%';
    rows.forEach((r, i) => { const ok = p >= [25, 55, 80, 100][i], now = !ok && p >= [0, 25, 55, 80][i]; r.className = ok ? 'ok' : now ? 'now' : 'todo'; r.firstChild.textContent = ok ? '✓' : now ? '•' : ''; });
  };
  const t0 = Date.now(); let done = false;
  const timer = setInterval(() => { if (!done) apply(92 * (1 - Math.exp(-(Date.now() - t0) / 9000))); }, 200);   // sale piano piano: è una stima, non il vero avanzamento
  apply(0);
  return { async finish() {                               // la scheda è pronta: la barra scatta al 100%
    done = true; clearInterval(timer); apply(100);
    title.textContent = nome ? `${nome}, scheda pronta!` : 'Scheda pronta!'; sub.textContent = 'Ti porto subito a vederla.'; ico.textContent = '🎉';
    await new Promise(r => setTimeout(r, 1100));
  }, stop() { done = true; clearInterval(timer); } };
}

async function buildPlan() {
  const load = loadingScreen();
  let plan, note = '';
  if (aiReady()) {
    try { plan = await aiPlan(S.profile, LIB); }
    catch (e) {
      let last = e;
      if (/troppo/i.test(e.message)) {                       // il modello è lento: provo uno più veloce prima di arrendermi
        const m = await pickFastModel();
        if (m) {
          const old = S.settings.model; S.settings.model = m;
          try { plan = await aiPlan(S.profile, LIB); note = expert() ? `Il modello era lento: ne ho scelto uno più veloce (${m}).` : 'Scheda pronta! 🎉'; }
          catch (e2) { S.settings.model = old; last = e2; }
        }
      }
      if (!plan) { S.lastError = errorText(last); note = expert() ? 'IA non disponibile: ho usato una scheda pronta. Vedi Impostazioni → Avanzate → Copia ultimo errore.' : 'Il coach è occupato: ti ho preparato una scheda pronta. Più tardi puoi rifarla da Impostazioni → Rifai la scheda.'; }
    }
  }
  S.plan = Sal.adjustPlan(plan || templatePlan(S.profile), S.profile.salute);        // con schiena o articolazioni delicate: esercizi più dolci
  S.nextDay = 0; S.session = null; S.planBackup = null;
  save();
  await load.finish();
  const dest = S.seen?.guida ? '#/oggi' : '#/guida';
  if (location.hash === dest) route(); else go(dest);
  setTimeout(() => toast(note || 'Scheda pronta! 🎉'), 300);
}

/* ---------------------------- guida di benvenuto ---------------------------- */
function viewGuida() {
  const nome = utente();
  const SL = [
    ['👋', `Ciao${nome ? ' ' + nome : ''}!`, 'Ti spiego come funziona in 4 passi. Ci vuole meno di un minuto.'],
    ['▶', 'Ogni giorno: apri "Oggi"', 'Tocca il grande pulsante verde INIZIA. L\'app ti dice cosa fare, un esercizio alla volta.'],
    ['✓', 'Dopo ogni serie, tocca ✓', 'Il tempo di riposo parte da solo. Quando finisce, senti un suono. Poi passi al prossimo esercizio.'],
    ['💬', 'Hai un dubbio? Scrivi al coach', 'Scrivi come parleresti a una persona: "mi fa male la spalla", "ho poco tempo". Il coach ti risponde.'],
  ];
  let n = 0;
  const finish = () => { S.seen = { ...(S.seen || {}), guida: true }; save(); go('#/oggi'); };
  function draw() {
    const [e, t, p] = SL[n], last = n === SL.length - 1;
    view.className = 'no-tabs'; renderTabs(null);
    render(h('div', { class: 'guida' },
      h('div', { class: 'stack', style: 'gap:30px;margin-top:40px' }, h('div', { class: 'big-ic' }, e),
        h('div', { class: 'stack center' }, h('h1', {}, t), h('p', { class: 'lead' }, p))),
      h('div', { class: 'stack', style: 'gap:18px' },
        h('div', { class: 'dots' }, SL.map((_, i) => h('i', { class: i === n ? 'on' : '' }))),
        h('button', { class: 'btn big block', style: 'min-height:64px;font-size:20px', onclick: () => last ? finish() : (n++, draw()) }, last ? 'Ho capito, cominciamo' : 'Avanti'),
        !last && h('button', { class: 'linkbtn', style: 'font-size:16px', onclick: finish }, 'Salta'))));
  }
  draw();
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
    return h('div', { class: 'day-dot' + (done ? ' done' : '') + (d.toDateString() === today ? ' today' : ''), style: `--n:${i}` }, h('i'), l);
  }));
}
const saluto = () => { const hr = new Date().getHours(); return hr < 12 ? 'Buongiorno' : hr < 18 ? 'Buon pomeriggio' : 'Buonasera'; };
const utente = () => S.profile?.nome || S.account?.name || '';
const oggiTxt = () => new Date().toLocaleDateString('it-IT', { weekday: 'long', day: 'numeric', month: 'long' });

// Promemoria in cima a "Oggi": peso (ogni settimana) e salute (ogni 3 mesi)
function reminderCards() {
  const out = [], now = Date.now(), r = S.remind || {};
  const lastW = S.pesi?.at(-1)?.date, days = lastW ? (now - new Date(lastW)) / 864e5 : 999;
  if (r.pesoDays > 0 && days >= r.pesoDays && !(r.pesoSnooze > now)) {
    const field = inp({ placeholder: String(S.profile.peso || '70'), 'aria-label': 'Peso in chili' });
    const save1 = () => {
      const kg = parseFloat(String(field.value).replace(',', '.'));
      if (!(kg >= 30 && kg <= 300)) return toast('Scrivi il peso in chili (per esempio 70)');
      S.pesi = [...(S.pesi || []), { date: new Date().toISOString(), kg }]; S.profile.peso = kg; save(); play('check'); toast('Peso aggiornato ✅'); viewOggi();
    };
    out.push(
      h('div', { class: 'remind' }, h('div', { class: 'ic' }, tile('peso', 26)), h('div', { class: 'grow' }, h('h3', {}, 'Aggiorna il tuo peso'), h('p', { class: 'muted small' }, lastW ? `L'ultima volta è stato ${Math.round(days)} giorni fa. Serve per calorie e grafici.` : 'Serve per calorie e grafici.'))),
      h('div', { class: 'card stack' }, h('div', { class: 'row', style: 'gap:10px' }, h('div', { class: 'inpbox grow' }, field, h('span', {}, 'kg')), h('button', { class: 'btn big', style: 'min-height:56px', onclick: save1 }, 'Salva')),
        h('button', { class: 'linkbtn', onclick: () => { S.remind = { ...r, pesoSnooze: now + 7 * 864e5 }; save(); viewOggi(); } }, 'Ricordamelo tra una settimana')));
  }
  const sd = S.profile?.salute?.aggiornata;
  if (r.salute !== false && sd && (now - new Date(sd)) / 864e5 >= 90 && !(r.saluteSnooze > now)) {
    out.push(h('div', { class: 'remind' }, h('div', { class: 'ic' }, tile('salute', 26)), h('div', { class: 'grow' }, h('h3', {}, 'Rivedi la tua salute'), h('p', { class: 'muted small' }, 'Sono passati 3 mesi. È cambiato qualcosa? (nuove cure, infortuni, gravidanza…)'),
      h('div', { class: 'row', style: 'gap:8px;margin-top:10px' },
        h('button', { class: 'btn small', onclick: () => { S.profile.salute.aggiornata = new Date().toISOString(); save(); viewOggi(); } }, 'Tutto uguale'),
        h('button', { class: 'btn ghost small', onclick: () => go('#/profilo') }, 'Aggiorna')))));
  }
  return out;
}

function viewOggi() {
  const day = S.plan.giorni[S.nextDay % S.plan.giorni.length];
  const wk = weekCount(), target = S.profile.giorni;
  const exs = adaptDay(day, S.luogo);
  const kcalWeek = Math.round(thisWeek().reduce((a, w) => a + (w.kcal || 0), 0) / 10) * 10;
  const first = !S.seen?.start && !S.history.length && !S.session;      // la prima volta: invito a toccare il pulsante giusto
  const startBtn = h('button', { class: 'btn big block start' + (first ? ' pulse' : ''), onclick: () => {
    S.seen = { ...(S.seen || {}), start: true };
    if (!S.session) startSession(S.nextDay % S.plan.giorni.length);
    go('#/allenamento');
  } }, S.session ? '▶ RIPRENDI L\'ALLENAMENTO' : '▶ INIZIA L\'ALLENAMENTO');
  render(
    h('div', { class: 'row between' },
      h('div', {}, h('div', { class: 'eyebrow' }, `${saluto()} · ${oggiTxt()}`), h('h1', {}, utente() || 'Ciao')),
      h('div', { class: 'row', style: 'gap:8px' }, helpBtn('oggi'), gear())),
    ...(!S.session ? reminderCards() : []),
    !S.session && luogoSwitch(viewOggi),
    !S.session && homeHint(),
    h('div', { class: 'hero' },
      h('div', { class: 'kicker' }, S.session ? `Allenamento in corso · ${S.session.luogo === 'casa' ? 'Casa' : 'Palestra'}` : 'Il tuo allenamento di oggi'),
      h('h1', { class: 'hero-title' }, day.nome),
      h('div', { class: 'meta' }, h('span', {}, tile('tempo', 14), estMin(exs) + ' min'), h('span', {}, tile('kcal', 14), kcalTxt(exs)), h('span', {}, tile('palestra', 14), exs.length + ' esercizi')),
      h('div', { class: 'chips' }, [...new Set(exs.map(e => EX(e.id)?.gruppo))].filter(Boolean).map(g => h('span', { class: 'chip' }, g))),
      first && h('div', { class: 'hint-bubble' }, '👇 Tocca qui per cominciare'),
      startBtn),
    h('div', { class: 'card stack' },
      h('div', { class: 'row between' }, h('h3', {}, 'Questa settimana'), h('span', { class: 'muted small' }, `${wk} / ${target}${kcalWeek ? ' · ~' + kcalWeek + ' kcal' : ''}`)),
      weekDots(),
      h('p', { class: 'muted small' }, 'Ogni allenamento fatto colora un cerchio.')),
    nutritionCard(),
    h('a', { class: 'card row between linkcard', href: '#/coach' },
      h('div', {}, h('h3', {}, 'Hai un dubbio? Scrivi al coach'), h('p', { class: 'muted small' }, 'Come faresti con una persona')),
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
    h('div', { class: 'row between' }, h('div', {}, h('h1', {}, S.plan.nome), h('p', { class: 'muted' }, 'Tocca un esercizio per vedere come si fa.')), h('div', { class: 'row', style: 'gap:8px' }, helpBtn('scheda'), gear())),
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
  render(h('div', { class: 'row between' }, h('div', { class: 'row' }, h('a', { class: 'iconbtn', href: '#/scheda', 'aria-label': 'Indietro' }, '‹'), h('h1', {}, 'Esercizi')), gear()),
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
    const chk = h('button', { class: 'chk', 'aria-label': 'Serie fatta', 'data-nosound': '' }, icon('check'));
    const cells = [h('div', { class: 'n' }, si + 1), kg, reps, chk];
    const paint = () => cells.forEach(c => c.classList.toggle('set-done', st.done));
    chk.addEventListener('click', () => {
      st.done = !st.done; paint(); save(); upd();
      if (st.done) { play('check'); buzz(28); }
      if (st.done && ex.target.recupero) startRest(ex.target.recupero);
      if (!st.done) stopRest();
    });
    paint();
    return h('div', { style: 'display:contents' }, cells);
  });

  const goTo = (i) => { s.cur = i; save(); stopRest(); viewAllenamento(); window.scrollTo(0, 0); };

  render(
    h('div', { class: 'sticky-head' },
      h('div', {}, h('div', { class: 'muted small' }, s.dayName + (s.luogo === 'casa' ? ' · Casa' : '')), h('h3', {}, `Esercizio ${s.cur + 1} di ${n}`)),
      h('div', { class: 'row', style: 'gap:8px' }, helpBtn('allenamento'), h('button', { class: 'btn ghost small', onclick: exitMenu }, 'Fine'))),
    h('div', { class: 'segs' }, segEls),
    h('button', { class: 'anim-btn', onclick: () => showExercise(ex.id), 'aria-label': 'Come si fa' }, exAnim(info), h('span', { class: 'pill' }, 'Come si fa ›')),
    h('div', {}, h('h1', { class: 'wk-title' }, info.nome), h('p', { class: 'muted' }, `${ex.target.serie} serie da ${ex.target.ripetizioni}${ex.target.recupero ? ' · riposo ' + ex.target.recupero + ' secondi' : ''}. Fai la serie, poi tocca ✓.`)),
    sg && h('div', { class: 'hint' }, 'Ultima volta: ', sg.txt, sg.up ? h('span', {}, ' · ', h('b', {}, `prova ${sg.up} kg 🔥`)) : ''),
    h('div', { id: 'rest-slot' }),
    h('div', { class: 'sets' },
      h('div', { class: 'hd' }, ''), h('div', { class: 'hd' }, time ? '' : 'Peso (kg)'), h('div', { class: 'hd' }, time ? '' : 'Quante volte'), h('div', { class: 'hd' }, 'Fatto'), rows),
    h('p', { class: 'muted small center' }, time ? 'Tocca ✓ quando hai finito.' : 'I numeri sono già scritti: cambiali solo se hai fatto diverso.'),
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
  play('win'); buzz([30, 60, 30]); confetti();
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
function stopRest() { clearInterval(restTimer); restTimer = null; document.getElementById('rest-root').replaceChildren(); document.getElementById('rest-slot')?.replaceChildren(); }
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
    if (left === 0) { clearInterval(restTimer); restTimer = null; play('done'); buzz([200, 100, 200]); t.textContent = 'Via! 💥'; setTimeout(stopRest, 2500); }
  };
  const slot = document.getElementById('rest-slot');
  (slot || document.getElementById('rest-root')).replaceChildren(h('div', { class: 'rest' + (slot ? ' inline' : '') }, ring,
    h('div', { class: 'grow' }, h('div', { class: 'muted small' }, 'Riposo: riprendi tra…'), t),
    h('button', { class: 'btn ghost small', onclick: () => { end += 15000; draw(); } }, '+15s'),
    h('button', { class: 'btn small', onclick: stopRest }, 'Salta')));
  draw(); restTimer = setInterval(draw, 250);
}

/* ---------------------------- coach IA ---------------------------- */
const STATUS = { pending: 'Sto per modificare la scheda', applied: 'Modifica applicata ✅', rejected: 'Nessuna modifica fatta', undone: 'Modifica annullata' };

function relDate(t) {
  const d = new Date(t), now = new Date(), dd = Math.round((new Date(now.toDateString()) - new Date(d.toDateString())) / 864e5);
  return dd === 0 ? 'Oggi' : dd === 1 ? 'Ieri' : d.toLocaleDateString('it-IT', { day: 'numeric', month: 'short' });
}

function viewCoach() {
  const list = h('div', { class: 'chat' });
  const input = h('textarea', { rows: 1, placeholder: 'Scrivi al coach…', enterkeyhint: 'send', 'data-nosound': '' });
  const grow = () => { input.style.height = 'auto'; input.style.height = Math.min(input.scrollHeight, 140) + 'px'; };   // la casella cresce col testo
  const sendBtn = h('button', { class: 'btn', 'data-nosound': '', onclick: () => send() }, 'Invia');
  const note = h('div', { class: 'dict-note' });
  const clearNote = () => { note.textContent = ''; sendBtn.classList.remove('glow'); };
  input.addEventListener('input', () => { grow(); if (!input.value.trim()) clearNote(); });
  let busy = false, animateFrom = Infinity;               // dal messaggio animateFrom in poi: comparsa animata
  const titleEl = h('h1', {}), subEl = h('div', { class: 'eyebrow', style: 'text-transform:none' });
  const bottom = () => window.scrollTo({ top: document.body.scrollHeight, behavior: getTheme().anim ? 'smooth' : 'auto' });
  const refreshHead = () => { const c = Chats.current(); titleEl.textContent = c?.title || 'Coach'; subEl.textContent = c ? `${c.messages.length} messaggi` : 'Scrivimi quello che vuoi'; };

  function proposalCard(m, isNew) {
    const p = m.proposal;
    const setStatus = (st) => { p.status = st; save(); draw(); };
    return h('div', { class: 'proposal' + (p.status === 'pending' ? ' pending' : '') + (isNew ? ' enter' : '') },
      h('div', { class: 'kicker' }, STATUS[p.status]),
      h('ul', {}, p.changes.map(c => h('li', {}, c.desc))),
      p.status === 'pending' && h('div', { class: 'row' },
        h('button', { class: 'btn grow', onclick: () => {
          const ok = normChanges(p.changes, LIB);        // ricontrolla: la scheda potrebbe essere cambiata
          if (!ok.length) { toast('Queste modifiche non sono più applicabili'); return setStatus('rejected'); }
          applyChanges(ok);
          Chats.allMessages().forEach(x => x.proposal && (x.proposal.undoable = false));
          p.undoable = true; setStatus('applied'); play('check');
          toast(S.session ? 'Fatto! Allenamento aggiornato' : 'Fatto! Scheda aggiornata');
        } }, 'Sì, applica'),
        h('button', { class: 'btn ghost grow', onclick: () => setStatus('rejected') }, 'No, lascia così')),
      p.status === 'applied' && p.undoable && S.planBackup &&
        h('button', { class: 'btn ghost small', onclick: () => { if (undoChanges()) setStatus('undone'); } }, 'Annulla modifica'));
  }

  function draw() {
    const c = Chats.current(); refreshHead();
    const msgs = c?.messages.length ? c.messages : [{ role: 'model', text: 'Ciao! Sono il tuo coach. Dimmi se qualcosa ti dà fastidio, se hai poco tempo o se vuoi cambiare un esercizio: ti dico io cosa modificare, e prima di toccare la scheda ti chiedo il permesso. 💪' }];
    list.replaceChildren(...msgs.flatMap((m, i) => {
      const isNew = !!c && i >= animateFrom;
      const b = h('div', { class: 'msg ' + (m.role === 'user' ? 'me' : 'ai') + (isNew ? ' enter' : '') });
      b.append(m.role === 'user' ? document.createTextNode(m.text) : mdLite(m.text, isNew));
      return [b, m.proposal && proposalCard(m, isNew)];
    }).filter(Boolean));
    animateFrom = Infinity; bottom();
  }

  // Elenco di tutte le chat, con anteprima e cestino
  function chatsSheet() {
    const items = Chats.sorted();
    openSheet(h('div', { class: 'stack' },
      h('div', { class: 'row between' }, h('h2', {}, 'Le tue chat'),
        h('button', { class: 'btn small', onclick: () => { Chats.startNew(); closeSheet(); viewCoach(); } }, '+ Nuova chat')),
      h('p', { class: 'muted small' }, 'I titoli li scrive il coach. Il coach si ricorda di cosa avete parlato.'),
      items.length
        ? items.map(c => {
            const last = c.messages.at(-1)?.text || '';
            return h('div', { class: 'chat-item' + (c.id === S.activeChat ? ' on' : '') },
              c.id === S.activeChat && h('span', { class: 'dot' }),
              h('button', { class: 'chat-open grow', onclick: () => { Chats.open(c.id); closeSheet(); viewCoach(); } },
                h('b', {}, c.title || 'Chat'), h('div', { class: 'muted small ellipsis' }, last.replace(/\*\*/g, ''))),
              h('span', { class: 't' }, relDate(c.updated)),
              h('button', { class: 'ic-d', 'aria-label': 'Cancella la chat', onclick: () => {
                if (!confirm('Cancellare questa chat?')) return;
                Chats.remove(c.id); closeSheet(); viewCoach(); } }, icon('trash')));
          })
        : h('p', { class: 'muted' }, 'Nessuna chat ancora: scrivi qualcosa al coach.')));
  }

  async function send(text) {
    text = (text || input.value).trim();
    if (!text || busy) return;
    if (!aiReady()) return toast('Aggiungi la chiave Gemini in Impostazioni');
    busy = true; input.value = ''; grow(); clearNote();
    const chat = Chats.push({ role: 'user', text });
    animateFrom = chat.messages.length - 1; draw(); play('send'); buzz(10);
    const cnt = h('span', { class: 'muted small cnt' });
    const typing = h('div', { class: 'msg ai enter' }, h('div', { class: 'dots-anim' }, h('span'), h('span'), h('span'), cnt));
    list.append(typing); bottom();
    const t0 = Date.now();
    const tick = setInterval(() => { const s = Math.round((Date.now() - t0) / 1000); cnt.textContent = s < 4 ? '' : ` ${s} s` + (s >= 15 ? (expert() ? ' · Gemini è lento: prova un modello più veloce in Impostazioni' : ' · ci sta mettendo un po\', un attimo…') : ''); }, 500);
    try {
      const hist = chat.messages.slice(-30).map(m => ({ role: m.role, parts: [{ text: m.text }] }));
      while (hist.length && hist[0].role !== 'user') hist.shift();
      const ask = () => gemini({ system: coachSystem(LIB), contents: hist, json: true, temperature: 0.5 });
      let raw;
      try { raw = await ask(); }
      catch (e) {
        if (!/troppo|in tempo/i.test(e.message)) throw e;
        cnt.textContent = ' · cerco un modello più veloce…';
        const m = await pickFastModel();                    // il modello è lento: ne scelgo uno più veloce e riprovo una volta
        if (!m) throw e;
        S.settings.model = m; save(); if (expert()) toast(`Il modello era lento: ne ho scelto uno più veloce (${m}).`, 5000);
        raw = await ask();
      }
      const { text: reply, changes } = parseReply(raw);
      const ok = normChanges(changes, LIB);
      Chats.push({ role: 'model', text: reply, ...(ok.length ? { proposal: { status: 'pending', changes: ok } } : {}) });
      animateFrom = chat.messages.length - 1; play('receive'); buzz(12);
      if (!chat.aiTitled && chat.messages.length >= 2) Chats.aiTitle(chat).then(refreshHead).catch(() => {});   // titolo scritto dal coach
    } catch (e) { Chats.popLast(); input.value = text; play('error'); showError(e); }
    clearInterval(tick); busy = false; draw();
  }
  input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } });

  /* --- dettatura: tocchi il microfono, parli, tocchi Fine; il testo resta nella casella per controllarlo --- */
  let voice = null;
  async function dictate() {
    if (voice || busy) return;
    if (voiceMode() === 'rec' && !aiReady()) return toast('Aggiungi la chiave Gemini in Impostazioni');
    const title = h('span', {}, 'Ti ascolto…'), time = h('b', { class: 'vp-time' }, '0:00');
    const fin = h('span', { class: 'fin' }), tmp = h('span', { class: 'tmp' });
    const live = h('div', { class: 'vp-text' }, fin, tmp);
    const hint = h('p', { class: 'vp-hint' }, 'Parla pure: tocca Fine solo quando hai finito.');
    const bars = h('div', { class: 'vp-bars' }, Array.from({ length: 25 }, (_, i) => h('i', { style: `--i:${i}` })));
    const btnFine = h('button', { class: 'btn big vp-fine', 'data-nosound': '' }, '■ Fine'), btnNo = h('button', { class: 'btn ghost', 'data-nosound': '' }, 'Annulla');
    const panel = h('div', { class: 'voice-panel enter' },
      h('div', { class: 'row between' }, h('div', { class: 'vp-title' }, h('span', { class: 'rec-dot' }), title), time), live, bars,
      h('div', { class: 'row' }, btnNo, btnFine), hint);
    const setRec = () => { live.hidden = true; title.textContent = 'Sto registrando…'; hint.textContent = 'Parla pure: quando tocchi Fine trascrivo io, in pochi secondi.'; };
    const close = () => { clearInterval(tick); panel.remove(); voice = null; };
    let t0 = Date.now();
    const tick = setInterval(() => {
      if (!panel.isConnected || !list.isConnected) return end(false);               // sono uscito dalla chat
      const s = Math.floor((Date.now() - t0) / 1000); time.textContent = `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
      if (voice?.mode === 'rec' && s >= 115) end(true);                              // limite della registrazione
    }, 250);
    async function end(keep) {
      const v = voice; if (!v) return;
      if (!keep) { v.cancel(); return close(); }
      btnFine.disabled = btnNo.disabled = true; bars.classList.add('busy'); title.textContent = 'Trascrivo…'; hint.textContent = 'Pochi secondi…';
      try {
        const text = await v.stop();
        close();
        if (!text) return toast('Non ho sentito niente. Riprova.');
        input.value = (input.value.trim() + ' ' + text).trim(); grow();
        note.textContent = '✍️ Controlla il testo, poi tocca Invia'; sendBtn.classList.add('glow'); play('check'); buzz(12);
        input.scrollTop = input.scrollHeight;
      } catch (e) { close(); showError(e); }
    }
    try {
      voice = await startVoice({
        onText: (f, i) => { fin.textContent = f; tmp.textContent = (f && i ? ' ' : '') + i; live.scrollTop = live.scrollHeight; },
        onMode: setRec,
        onFail: (msg) => { close(); toast(msg, 6000); },
      });
    } catch (e) { return toast(e.message, 6000); }
    if (voice.mode === 'rec') setRec();
    buzz(14); document.body.append(panel);
    btnFine.onclick = () => end(true); btnNo.onclick = () => end(false);
  }


  const sugg = ['Mi fa male una cosa', 'Cambia un esercizio', 'Ho poco tempo oggi', 'Mi sembra troppo facile'];
  render(
    h('div', { class: 'row between' },
      h('div', { class: 'coach-head' }, h('div', { class: 'avatar' }, icon('dumbbell')),
        h('button', { class: 'coach-title', onclick: chatsSheet, 'aria-label': 'Le tue chat' }, h('div', {}, titleEl, subEl), icon('chev'))),
      h('div', { class: 'row', style: 'gap:8px' },
        h('button', { class: 'iconbtn', 'aria-label': 'Nuova chat', onclick: () => { Chats.startNew(); viewCoach(); } }, icon('plus')), gear())),
    !aiReady() && h('div', { class: 'card stack' }, h('p', {}, 'Per parlare col coach serve la chiave Gemini (gratuita).'),
      h('a', { class: 'btn small', href: '#/profilo' }, 'Aggiungila qui')),
    list,
    !Chats.messages().length && h('div', { class: 'chips' }, sugg.map(q => h('button', { class: 'chip', onclick: () => send(q) }, q)),
      h('button', { class: 'chip', onclick: () => { const [t, l] = HELP.coach; openSheet(h('div', { class: 'stack' }, h('h2', {}, t), h('ul', { class: 'helplist' }, l.map(x => h('li', {}, x))), h('button', { class: 'btn big block', onclick: closeSheet }, 'Ho capito'))); } }, '❓ Come funziona')),
    h('div', { style: 'height:64px' }),
    h('div', { class: 'composer' }, note, h('div', { class: 'in' }, input,
      voiceMode() && h('button', { class: 'micbtn', 'aria-label': 'Parla al coach', 'data-nosound': '', onclick: dictate }, icon('mic')), sendBtn)));
  draw();
}

function downloadFile(name, text, type = 'application/json') {
  const a = h('a', { href: URL.createObjectURL(new Blob([text], { type })), download: name }); document.body.append(a); a.click(); a.remove();
}

/* ---------------------------- account (sito su Cloudflare) ---------------------------- */
function accountCard() {
  const ses = getSession();
  const pwField = (label, ac) => h('label', { class: 'field' }, label, h('input', { type: 'password', autocomplete: ac, autocapitalize: 'off' }));
  const val = (l) => l.querySelector('input').value;
  const box = h('div', { class: 'stack' });

  function changeSheet() {
    const o = pwField('Password attuale', 'current-password'), n1 = pwField('Nuova password (almeno 8 caratteri)', 'new-password'), n2 = pwField('Ripeti la nuova password', 'new-password');
    const err = h('p', { class: 'err' });
    const btn = h('button', { class: 'btn block', onclick: async () => {
      err.textContent = '';
      if (val(n1).length < 8) return err.textContent = 'Usa almeno 8 caratteri.';
      if (val(n1) !== val(n2)) return err.textContent = 'Le due password non coincidono.';
      btn.disabled = true; btn.textContent = 'Controllo…';
      try {
        await changeAccountPassword(val(o), val(n1));         // prima il server…
        await changePassword(val(o), val(n1));                // …poi i dati sul telefono
        closeSheet(); toast('Password cambiata ✅');
      } catch (e) { err.textContent = e.message; btn.disabled = false; btn.textContent = 'Cambia password'; }
    } }, 'Cambia password');
    openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Cambia password'), o, n1, n2, err, btn));
  }
  const chips = (opts, cur, set) => h('div', { class: 'chips' }, opts.map(([v, t]) => h('button', { class: 'chip' + (cur === v ? ' on' : ''), onclick: () => set(v) }, t)));

  async function draw() {
    const dev = await deviceInfo(), canBio = await bioAvailable();
    const stay = S.security.stay !== false && !!dev, bioOn = !!dev?.cred;
    box.replaceChildren(
      h('p', {}, '👤 ', h('b', {}, S.account?.name || ses?.name || ''), '  ', h('span', { class: 'muted small' }, '@' + (S.account?.user || ses?.user || ''))),
      h('p', { class: 'muted small' }, 'I tuoi dati sono cifrati con la tua password: nemmeno chi gestisce l\'app può leggerli.'),
      h('div', { class: 'stack' }, h('h3', {}, 'Resta connesso'),
        chips([[30, '30 giorni'], [90, '90 giorni'], [3650, 'Finché non esco'], [0, 'No']], stay ? S.security.stayDays : 0, async (v) => {
          if (v === 0) { S.security.stay = false; save(); await forgetDevice(); }
          else { S.security.stay = true; S.security.stayDays = v; save(); await forgetDevice(); await rememberDevice(v); }
          draw(); }),
        h('p', { class: 'muted small' }, stay ? 'Per questo tempo non ti chiedo la password. Il tempo riparte ogni volta che usi l\'app.' : 'La password verrà chiesta a ogni apertura.')),
      canBio && h('div', { class: 'setrow' }, h('div', {}, h('b', {}, 'Sblocco con impronta'), h('div', { class: 'muted small' }, 'Impronta o volto, come il telefono. Vale solo su questo telefono.')),
        h('button', { class: 'switch' + (bioOn ? ' on' : ''), role: 'switch', 'aria-checked': String(bioOn), 'aria-label': 'Sblocco con impronta', 'data-nosound': '', onclick: async () => {
          try {
            if (bioOn) await rememberDevice(S.security.stayDays || 90, null);
            else { if (!dev) { S.security.stay = true; await rememberDevice(S.security.stayDays || 90); } await rememberDevice(S.security.stayDays || 90, await bioRegister(S.account?.name)); toast('Impronta attivata ✅'); }
          } catch { toast('Non è stato possibile attivare l\'impronta'); }
          draw(); } })),
      bioOn && h('div', { class: 'stack' }, h('h3', {}, 'Blocca l\'app dopo'),
        chips([[0, 'Subito'], [1, '1 min'], [5, '5 min'], [15, '15 min'], [-1, 'Mai']], S.security.autoLockMin, (v) => { S.security.autoLockMin = v; save(); draw(); }),
        h('p', { class: 'muted small' }, 'Dopo questo tempo in background l\'app si riblocca e si riapre con l\'impronta (non serve la password).')),
      h('div', { class: 'tip' }, 'La password la chiedo solo: al primo accesso, su un telefono nuovo, dopo ' + (S.security.stayDays >= 3650 ? 'tanto tempo' : (S.security.stayDays || 90) + ' giorni') + ' senza usare l\'app, o se l\'impronta non funziona.'),
      h('button', { class: 'btn ghost block', onclick: () => softLock() }, 'Blocca ora'),
      h('button', { class: 'btn ghost block', onclick: changeSheet }, 'Cambia password'),
      h('button', { class: 'btn ghost block', onclick: () => { if (confirm('Uscire da questo account? Dovrai rimettere la password per rientrare. I dati restano cifrati sul telefono.')) { forgetDevice().then(() => { forgetLast(); location.hash = ''; location.reload(); }); } } }, 'Esci da questo account'));
  }
  draw();
  return h('div', { class: 'card stack' }, h('h2', {}, 'Account e accesso'), box);
}

/* ---------------------------- sicurezza: blocco con password ---------------------------- */
const MIN_PW = 8;
function securityCard() {
  if (accountsMode()) return accountCard();
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

/* ---------------------------- aspetto: colori, suoni, animazioni ---------------------------- */
function appearanceCard() {
  const box = h('div', { class: 'stack' });
  const toggle = (key, title, desc) => {
    const on = !!getTheme()[key];
    return h('div', { class: 'setrow' }, h('div', {}, h('b', {}, title), h('div', { class: 'muted small' }, desc)),
      h('button', { class: 'switch' + (on ? ' on' : ''), role: 'switch', 'aria-checked': String(on), 'aria-label': title, 'data-nosound': '', onclick: () => {
        setTheme({ [key]: !on }); if (key === 'sound' && !on) play('check'); if (key === 'haptics' && !on) buzz(30); draw(); } }));
  };
  function draw() {
    const T = getTheme(), cur = T.accent.toLowerCase();
    const preset = PRESETS.some(([, hex]) => hex === cur);
    box.replaceChildren(
      h('div', { class: 'stack' }, h('h3', {}, 'Colore principale'),
        h('div', { class: 'chips', style: 'gap:10px' },
          PRESETS.map(([name, hex]) => h('button', { class: 'sw' + (hex === cur ? ' sel' : ''), style: `background:${hex}`, 'aria-label': name, onclick: () => { setTheme({ accent: hex }); draw(); } }, hex === cur && icon('check'))),
          h('label', { class: 'sw rainbow' + (!preset ? ' sel' : ''), 'aria-label': 'Scegli un colore tuo' }, h('span', {}, '+'),
            h('input', { type: 'color', value: cur, oninput: e => setTheme({ accent: e.target.value }), onchange: draw }))),
        h('p', { class: 'muted small' }, 'Il "+" apre la tavolozza: scegli qualsiasi colore. L\'app si ricolora subito.')),
      h('div', { class: 'stack' }, h('h3', {}, 'Sfondo'),
        h('div', { class: 'row', style: 'gap:10px' }, Object.entries(BACKGROUNDS).map(([k, v]) =>
          h('button', { class: 'bgopt' + (T.bg === k ? ' sel' : ''), onclick: () => { setTheme({ bg: k }); draw(); } },
            h('div', { class: 'pv', style: `background:${v.bg}` }, h('i', { style: `background:${v.card}` }), h('i', { style: `background:${v.card2}` })), v.name)))),
      h('div', {}, toggle('sound', 'Suoni', 'Un piccolo "tic" quando tocchi e un suono per ogni serie fatta'),
        toggle('haptics', 'Vibrazione', 'Una vibrazione leggera ai tocchi. Su iPhone recenti è un piccolo "tic"'),
        toggle('anim', 'Animazioni', 'Effetti, coriandoli, numeri che salgono'),
        toggle('big', 'Testo più grande', 'Scritte più grandi in tutta l\'app')));
  }
  draw();
  return h('div', { class: 'card stack' }, h('h2', {}, 'Aspetto'), box);
}

function bodyCard() {
  const t = targets(S.profile);
  return h('div', { class: 'card stack' }, h('h2', {}, 'Calorie e proteine'),
    t ? h('div', { class: 'stack' },
          h('div', { class: 'stats' },
            h('div', { class: 'stat' }, h('b', {}, t.kcal), h('span', {}, 'kcal al giorno')),
            h('div', { class: 'stat' }, h('b', {}, t.prot + ' g'), h('span', {}, 'proteine')),
            h('div', { class: 'stat' }, h('b', {}, t.fat + ' g'), h('span', {}, 'grassi'))),
          h('p', { class: 'muted small' }, `Mantenimento circa ${t.mantenimento} kcal. Il resto è carboidrati (~${t.carb} g). Stima indicativa: pesati ogni settimana e correggi di ±100-150 kcal se serve. Non sostituisce il parere di un medico o di un nutrizionista.`))
      : h('p', { class: 'muted' }, 'Inserisci peso, altezza, età e sesso in "La tua salute" per calcolare calorie e proteine.'));
}

/* ---------------------------- la tua salute ---------------------------- */
function healthCard() {
  const P = S.profile, sal = P.salute || {};
  const touch = () => { P.salute = { ...(P.salute || {}), aggiornata: new Date().toISOString() }; P.note = Sal.hasAny(P.salute) ? Sal.summary(P.salute) : ''; save(); };
  const row = (emoji, t, sub, btn, onclick) => h('div', { class: 'setrow2' }, h('div', { class: 'ic2' }, emoji), h('div', { class: 'grow' }, h('b', {}, t), h('div', { class: 'muted small' }, sub)), h('button', { class: 'chip', onclick }, btn));

  function datiSheet() {
    const f = { peso: P.peso || '', altezza: P.altezza || '', eta: P.eta || '', sesso: P.sesso || '' };
    const err = h('p', { class: 'err' });
    const sx = h('div', { class: 'chips' }); const drs = () => sx.replaceChildren(...[['uomo', 'Uomo'], ['donna', 'Donna']].map(([v, t]) => h('button', { class: 'chip lg' + (f.sesso === v ? ' on' : ''), onclick: () => { f.sesso = v; drs(); } }, t))); drs();
    const field = (lab, key, unit) => h('label', { class: 'field2' }, lab, h('div', { class: 'inpbox' }, inp({ value: f[key], oninput: e => f[key] = e.target.value }), unit && h('span', {}, unit)));
    openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Peso e misure'), field('Peso', 'peso', 'kg'), field('Altezza', 'altezza', 'cm'), field('Anni', 'eta'), h('div', { class: 'field2' }, 'Sesso', sx), err,
      h('button', { class: 'btn big block', onclick: () => {
        const p = parseFloat(String(f.peso).replace(',', '.')), al = parseFloat(f.altezza), e = parseInt(f.eta);
        if (!(p >= 30 && p <= 300) || !(al >= 120 && al <= 230) || !(e >= 14 && e <= 100) || !f.sesso) return err.textContent = 'Controlla i numeri e scegli uomo o donna.';
        if (p !== P.peso) S.pesi = [...(S.pesi || []), { date: new Date().toISOString(), kg: p }];
        Object.assign(P, { peso: p, altezza: al, eta: e, sesso: f.sesso }); save(); closeSheet(); toast('Salvato ✅'); viewProfilo();
      } }, 'Salva')));
  }
  function condSheet() {
    const c = new Set(sal.condizioni || []); let altro = sal.altro || '';
    const box = h('div', { class: 'stack' });
    const drawc = () => box.replaceChildren(
      h('div', { class: 'stack', style: 'gap:10px' }, Sal.CONDIZIONI.map(([k, t]) => condBtn(t, c.has(k), () => { c.has(k) ? c.delete(k) : c.add(k); drawc(); }))),
      c.has('altro') && h('input', { type: 'text', class: 'bigtext', placeholder: 'Cosa? (anche solo una parola)', value: altro, oninput: e => altro = e.target.value }),
      c.size > 0 && h('div', { class: 'warn' }, icon('warn'), h('span', {}, 'Con questi problemi ti consiglio di ', h('b', {}, 'parlarne con il tuo medico'), ' prima di allenarti. Il coach sceglierà esercizi più dolci.')));
    drawc();
    openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Problemi di salute'), h('p', { class: 'muted' }, 'Tocca quelli che hai.'), box,
      h('button', { class: 'btn big block', onclick: () => { P.salute = { ...sal, condizioni: [...c], altro: altro.trim() }; touch(); closeSheet(); toast('Salvato ✅'); viewProfilo(); } }, 'Salva')));
  }
  function farmaciSheet() {
    let on = sal.farmaci === true, note = sal.farmaciNote || '';
    const box = h('div', { class: 'stack' });
    const drawf = () => box.replaceChildren(h('div', { class: 'row', style: 'gap:10px' }, [[true, 'Sì'], [false, 'No']].map(([v, t]) => h('button', { class: 'chip lg' + (on === v ? ' on' : ''), onclick: () => { on = v; drawf(); } }, t))),
      on && h('input', { type: 'text', class: 'bigtext', placeholder: 'Quali? (anche solo il nome)', value: note, oninput: e => note = e.target.value }));
    drawf();
    openSheet(h('div', { class: 'stack' }, h('h2', {}, 'Farmaci'), h('p', { class: 'muted' }, 'Prendi dei farmaci? Il coach non dà consigli sui farmaci: li usa solo per essere prudente.'), box,
      h('button', { class: 'btn big block', onclick: () => { P.salute = { ...sal, farmaci: on, farmaciNote: on ? note.trim() : '' }; touch(); closeSheet(); toast('Salvato ✅'); viewProfilo(); } }, 'Salva')));
  }
  const conds = Sal.hasAny({ condizioni: sal.condizioni, altro: sal.altro }) ? Sal.summary({ condizioni: sal.condizioni, altro: sal.altro }) : 'Nessuno indicato';
  return h('div', { class: 'card' }, h('h2', { style: 'margin-bottom:6px' }, 'La tua salute'),
    row(tile('peso', 22), 'Peso e misure', P.peso ? `${P.peso} kg · ${P.altezza || '?'} cm · ${P.eta || '?'} anni` : 'Da inserire', 'Aggiorna', datiSheet),
    row(tile('salute', 22), 'Problemi di salute', conds, 'Modifica', condSheet),
    row(tile('pillola', 22), 'Farmaci', sal.farmaci ? `Sì${sal.farmaciNote ? ': ' + sal.farmaciNote : ''}` : 'No', 'Modifica', farmaciSheet),
    privacyBox('Ti ricordo di rivedere questi dati ogni 3 mesi e di aggiornare il peso ogni settimana. Se cambia qualcosa (nuova cura, infortunio), aggiornali: il coach si adatta.'));
}

function healthRemindersCard() {
  const r = S.remind || (S.remind = { pesoDays: 7, salute: true });
  const box = h('div', { class: 'stack' });
  const draw = () => box.replaceChildren(
    h('div', { class: 'stack' }, h('h3', {}, 'Peso: ricordamelo'),
      h('div', { class: 'chips' }, [[0, 'Mai'], [7, 'Ogni settimana'], [14, 'Ogni 2 settimane']].map(([v, t]) => h('button', { class: 'chip lg' + (r.pesoDays === v ? ' on' : ''), onclick: () => { r.pesoDays = v; delete r.pesoSnooze; save(); draw(); } }, t))),
      h('p', { class: 'muted small' }, 'Quando apri l\'app compare un avviso, con il campo già pronto.')),
    h('div', { class: 'setrow' }, h('div', {}, h('b', {}, 'Rivedi la salute ogni 3 mesi')), h('button', { class: 'switch' + (r.salute !== false ? ' on' : ''), role: 'switch', 'aria-checked': String(r.salute !== false), 'aria-label': 'Rivedi la salute ogni 3 mesi', 'data-nosound': '', onclick: () => { r.salute = r.salute === false; save(); draw(); } })));
  draw();
  return h('div', { class: 'card stack' }, h('h2', {}, 'Promemoria della salute'), box);
}

function helpCard() {
  return h('div', { class: 'card' }, h('h2', { style: 'margin-bottom:6px' }, 'Aiuto'),
    h('button', { class: 'setrow2 fullrow', onclick: () => go('#/guida') }, h('div', { class: 'ic2' }, tile('aiuto', 22)), h('div', { class: 'grow' }, h('b', {}, 'Rivedi la guida'), h('div', { class: 'muted small' }, 'Le 4 schermate di benvenuto')), h('span', { class: 'arrow' }, '›')));
}

/* ---------------------------- impostazioni ---------------------------- */
let taps = 0, lastTap = 0;
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
    h('div', { class: 'row' }, h('a', { class: 'iconbtn', href: '#/oggi', 'aria-label': 'Indietro' }, '‹'), h('h1', { onclick: () => {      // 5 tocchi: opzioni da esperto (scelta di modello e chiave)
      taps = (Date.now() - lastTap > 1500 ? 0 : taps) + 1; lastTap = Date.now();
      if (taps >= 5) { taps = 0; S.settings.expert = !S.settings.expert; save(); toast(S.settings.expert ? 'Opzioni da esperto attivate' : 'Opzioni da esperto nascoste'); viewProfilo(); } } }, 'Impostazioni')),
    securityCard(),
    appearanceCard(),
    healthCard(),
    healthRemindersCard(),
    bodyCard(),
    remindersCard(),
    helpCard(),
    h('div', { class: 'card stack' }, h('h2', {}, 'Casa'),
      h('div', { class: 'stack' }, h('h3', {}, 'Attrezzatura a casa'),
        h('div', { class: 'chips' }, CASA_OPT.map(([v, t]) => h('button', { class: 'chip lg' + ((S.profile.casa || 'libero') === v ? ' on' : ''), onclick: (e) => {
          S.profile.casa = v; save(); e.target.parentElement.querySelectorAll('.chip').forEach(c => c.classList.remove('on')); e.target.classList.add('on'); toast('Salvato'); } }, t)))),
    ),
    expert() && h('div', { class: 'card stack' }, h('h2', {}, 'Coach IA (Gemini)'),
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
          try { await gemini({ contents: [{ role: 'user', parts: [{ text: 'Rispondi solo: ok' }] }] }); const lt = lastTiming; toast(`Collegamento riuscito ✅ (${((Date.now() - t0) / 1000).toFixed(1)} s${lt?.server != null ? ' · Google ' + lt.server.toFixed(1) + ' s' : ''})`, 5000); }
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
        ...(!expert() ? [] : [h('label', { class: 'field' }, 'Modello Gemini', modelIn),
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
          e.target.disabled = false; e.target.textContent = 'Scegli il modello'; } }, 'Scegli il modello')]),
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
