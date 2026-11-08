// Logica allenamento condivisa: progressione, serie, sessione in corso.
import { S, save } from './store.js';

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

export function startSession(dayIndex) {
  const day = S.plan.giorni[dayIndex];
  S.session = {
    dayIndex, dayName: day.nome, startedAt: Date.now(), cur: 0,
    exercises: day.esercizi.map(t => ({ id: t.id, target: t, sets: newSets(t) })),
  };
  save();
}

// Se la scheda cambia durante l'allenamento (es. dal coach), aggiorna gli esercizi non ancora iniziati
export function syncSession() {
  const s = S.session;
  const day = s && S.plan.giorni[s.dayIndex];
  if (!day) return;
  const old = s.exercises;
  const next = day.esercizi.map(t => {
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
