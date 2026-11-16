// Più schede in parallelo. S.plan / S.nextDay restano la scheda "aperta" (così tutto il resto dell'app funziona uguale);
// S.schede contiene tutte le schede e S.sel dice quale è caricata in S.plan.
import { S, save, luogoFor } from './store.js';

export const TIPI = [['palestra', 'Solo palestra'], ['casa', 'Solo casa'], ['misto', 'Adattabile']];
export const tipoTxt = (t) => (TIPI.find(x => x[0] === t) || TIPI[2])[1];
export const tipoIcon = (t) => (t === 'casa' ? 'casa' : t === 'palestra' ? 'palestra' : 'aspetto');

export function ensureSchede() {
  if (!S.plan) return;
  if (!S.schede.length) { S.schede = [{ id: 's1', nome: 'Scheda principale', tipo: 'misto', on: true, plan: S.plan, next: S.nextDay || 0 }]; S.sel = 's1'; save(); }
  else if (!S.schede.some(x => x.id === S.sel)) { S.sel = S.schede[0].id; S.plan = S.schede[0].plan; S.nextDay = S.schede[0].next || 0; }
}
export const cur = () => S.schede.find(x => x.id === S.sel);
export const activeSchede = () => S.schede.filter(x => x.on);
export function selectScheda(id) {
  const e = S.schede.find(x => x.id === id); if (!e || id === S.sel) return;
  save();                                                    // il salvataggio riporta S.plan nella scheda corrente
  S.plan = e.plan; S.nextDay = e.next || 0; S.sel = id; S.planBackup = null; save();
}
export function addScheda({ nome, tipo, plan }) {
  const id = 's' + Date.now().toString(36);
  S.schede.push({ id, nome, tipo, on: true, plan, next: 0 }); save(); return id;
}
export function removeScheda(id) {
  if (S.schede.length < 2) return false;
  const wasCur = id === S.sel;
  S.schede = S.schede.filter(x => x.id !== id);
  if (wasCur) selectScheda(S.schede[0].id) || (S.sel = S.schede[0].id, S.plan = S.schede[0].plan, S.nextDay = S.schede[0].next || 0);
  if (!S.schede.some(x => x.on)) S.schede[0].on = true;
  save(); return true;
}
export { luogoFor };
