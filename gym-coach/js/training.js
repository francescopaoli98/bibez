// Logica allenamento condivisa: progressione, serie, sessione in corso.
import { S, save } from './store.js';

let LIB = [];
export const setLib = (l) => { LIB = l; };

export const isTime = (r) => /sec|min/.test(String(r));
export function topReps(rep) { const n = String(rep).match(/\d+/g); return n ? +n[n.length - 1] : 0; }

export function lastPerf(id) {
  for (let i = S.history.length - 1; i >= 0; i--) {
    const e = S.history[i].exercises.find(x => x.id === id);
    if (e && e.sets.length) return e.sets;
  }
  return null;
}

// Ultima volta + eventuale proposta di aumento carico (+2,5 kg se hai fatto tutte le ripetizioni massime)
export function suggestion(id, target) {
  const last = lastPerf(id);
  if (!last) return null;
  const best = last.reduce((a, s) => (s.kg > a.kg ? s : a), last[0]);
  const all = last.every(s => s.reps >= topReps(target.ripetizioni));
  return { txt: last.map(s => `${s.kg || 0}kg×${s.reps}`).join(', '), up: all && best.kg > 0 ? best.kg + 2.5 : null, kg: best.kg };
}

// Serie già precompilate: così per ogni serie basta un tocco sul ✓
export function newSets(t) {
  const sg = suggestion(t.id, t);
  const time = isTime(t.ripetizioni);
  return Array.from({ length: t.serie }, () => ({
    kg: !time && sg?.kg ? String(sg.kg) : '',
    reps: time ? '' : String(topReps(t.ripetizioni) || ''),
    done: false,
  }));
}

/* ---------- Casa / Palestra ---------- */
const homeOk = (e, equip) => e && (e.casa === 'libero' || (equip === 'manubri' && e.casa === 'manubri'));
const FALLBACK = { spalle: ['petto'], braccia: ['petto', 'core'], schiena: ['core'], gambe: ['core'] };
const TIMED = new Set(['Plank', 'Side_Bridge', 'Mountain_Climbers', 'Flutter_Kicks', 'Star_Jump']);

// A casa: tiene gli esercizi già fattibili e sostituisce gli altri con un equivalente dello stesso gruppo
export function adaptDay(day, luogo) {
  if (luogo !== 'casa') return day.esercizi;
  const equip = S.profile?.casa || 'libero';
  const info = (id) => LIB.find(e => e.id === id);
  const used = new Set(day.esercizi.map(t => t.id).filter(id => homeOk(info(id), equip)));
  const out = [];
  for (const t of day.esercizi) {
    const e = info(t.id);
    if (homeOk(e, equip)) { out.push(t); continue; }
    let alt = null;
    for (const g of [e?.gruppo, ...(FALLBACK[e?.gruppo] || [])]) {
      alt = LIB.find(x => x.gruppo === g && homeOk(x, equip) && !used.has(x.id));
      if (alt) break;
    }
    if (!alt) continue;                       // niente di equivalente a casa: lo salto
    used.add(alt.id);
    out.push(TIMED.has(alt.id) || /min/.test(t.ripetizioni)
      ? { id: alt.id, serie: 3, ripetizioni: '30-45 sec', recupero: 30 }
      : { ...t, id: alt.id });
  }
  return out;
}

/* ---------- Stima di tempo e calorie (indicativa) ---------- */
const avg = (str) => { const n = (String(str).match(/\d+/g) || ['0']).map(Number); return n.reduce((a, b) => a + b, 0) / n.length; };
export function estMin(exs) { return Math.max(1, Math.round(exs.reduce((a, e) => a + e.serie * (45 + (e.recupero || 60)) / 60, 0))); }
// kcal = MET × peso × ore. MET: forza 5.5, cardio 6.5, recupero 2.5, cambio attrezzo 3
export function estKcal(exs) {
  const kg = S.profile?.peso || 75;
  let h = 0;
  for (const t of exs) {
    const info = LIB.find(e => e.id === t.id);
    const sets = t.serie || 1, rep = String(t.ripetizioni);
    const act = /min/.test(rep) ? sets * avg(rep) * 60 : /sec/.test(rep) ? sets * avg(rep) : sets * 40;
    const rest = Math.max(0, sets - 1) * (t.recupero || 0);
    h += ((info?.gruppo === 'cardio' ? 6.5 : 5.5) * act + 2.5 * rest + 3 * 45) / 3600;
  }
  return Math.round(h * kg / 10) * 10;
}

// Versione corta (~15 minuti): i primi esercizi del giorno, 2 serie ciascuno
export function shortList(exs, minutes = 15) {
  const out = [];
  for (const t of exs) {
    const s = { ...t, serie: Math.min(t.serie, 2) };
    if (out.length >= 3 && estMin([...out, s]) > minutes) break;
    out.push(s);
  }
  return out;
}
const pick = (day, luogo, short) => short ? shortList(adaptDay(day, luogo)) : adaptDay(day, luogo);

export function startSession(dayIndex, short = false) {
  const day = S.plan.giorni[dayIndex];
  const luogo = S.luogo || 'palestra';
  S.session = {
    dayIndex, dayName: day.nome, startedAt: Date.now(), cur: 0, luogo, short,
    exercises: pick(day, luogo, short).map(t => ({ id: t.id, target: t, sets: newSets(t) })),
  };
  save();
}

// Se la scheda cambia durante l'allenamento (es. dal coach), aggiorna gli esercizi non ancora iniziati
export function syncSession() {
  const s = S.session;
  const day = s && S.plan.giorni[s.dayIndex];
  if (!day) return;
  const old = s.exercises;
  const next = pick(day, s.luogo, s.short).map(t => {
    const ex = old.find(x => x.id === t.id);
    if (!ex) return { id: t.id, target: t, sets: newSets(t) };
    if (ex.sets.some(x => x.done)) return ex;
    return JSON.stringify(ex.target) === JSON.stringify(t) ? ex : { id: t.id, target: t, sets: newSets(t) };
  });
  for (const ex of old) if (!next.some(x => x.id === ex.id) && ex.sets.some(x => x.done)) next.push(ex);
  s.exercises = next;
  s.cur = Math.min(s.cur || 0, next.length - 1);
  save();
}
