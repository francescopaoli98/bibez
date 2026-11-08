// Salvataggio dati locale (localStorage). Tutto resta sul telefono.
const KEY = 'gymcoach:v1';
const DEFAULT = {
  profile: null,            // {obiettivo, livello, giorni, note}
  plan: null,               // {nome, giorni:[{nome, esercizi:[{id, serie, ripetizioni, recupero}]}]}
  history: [],
  pesi: [],                 // [{date, kg}] peso corporeo
  reminder: null,           // {days:[1,3,5], time:'18:00'}              // allenamenti completati
  settings: { apiKey: '', model: 'gemini-flash-latest' },
  session: null,            // allenamento in corso
  chat: [],                 // [{role:'user'|'model', text}]
  luogo: 'palestra',        // 'palestra' | 'casa' (dove ti alleni oggi)
  nextDay: 0,               // indice del prossimo giorno in scheda
  planBackup: null,         // scheda prima dell'ultima modifica del coach (per annullare)
};

export const S = (() => {
  try { return { ...DEFAULT, ...JSON.parse(localStorage.getItem(KEY) || '{}'),
    settings: { ...DEFAULT.settings, ...(JSON.parse(localStorage.getItem(KEY) || '{}').settings || {}) } }; }
  catch { return structuredClone(DEFAULT); }
})();

export function save() {
  try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) { console.warn('save failed', e); }
}
export function resetAll() { localStorage.removeItem(KEY); }
export function exportJSON() { return JSON.stringify(S, null, 2); }
