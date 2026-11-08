// Chiamate a Gemini direttamente dal telefono. La chiave resta solo sul dispositivo.
import { S, save } from './store.js';

export class AIError extends Error {}
const BASE = 'https://generativelanguage.googleapis.com/v1beta';
const TIMEOUT_MS = 45000;
// Come chiedere risposte rapide, dal più nuovo al più vecchio. Il primo che il modello accetta viene ricordato.
const THINK_MODES = [{ thinkingLevel: 'minimal' }, { thinkingBudget: 0 }, null];

// Una richiesta con tempo massimo: se Gemini non risponde non resti a caricare all'infinito
async function request(path, { method = 'GET', body, ms = TIMEOUT_MS } = {}) {
  const { apiKey } = S.settings;
  if (!apiKey) throw new AIError('Manca la chiave Gemini. Aggiungila in Impostazioni.');
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort(), S.settings.timeoutMs || ms);
  try {
    const res = await fetch(BASE + path, {
      method, signal: ctl.signal,
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
      body: body ? JSON.stringify(body) : undefined,
    });
    let data = null;
    try { data = await res.json(); } catch {}
    return { status: res.status, ok: res.ok, data };
  } catch (e) {
    if (e.name === 'AbortError') throw new AIError('Gemini ci sta mettendo troppo. Riprova, oppure scegli un modello più veloce in Impostazioni → Avanzate.');
    throw new AIError('Nessuna connessione. Controlla la rete e riprova.');
  } finally { clearTimeout(timer); }
}

export async function gemini({ system, contents, json = false, temperature = 0.7, model: modelName, ms }) {
  const name = modelName || S.settings.model || 'gemini-flash-latest';
  const gen = { temperature, ...(json ? { responseMimeType: 'application/json' } : {}) };
  const body = { contents, generationConfig: gen };
  if (system) body.systemInstruction = { parts: [{ text: system }] };
  const path = `/models/${encodeURIComponent(name)}:generateContent`;

  // prova i modi per limitare il "ragionamento" (che rallenta molto): passa al successivo se il modello lo rifiuta
  S.settings.think = S.settings.think || {};
  let r, i = S.settings.think[name] ?? 0;
  for (; i < THINK_MODES.length; i++) {
    body.generationConfig = { ...gen, ...(THINK_MODES[i] ? { thinkingConfig: THINK_MODES[i] } : {}) };
    r = await request(path, { method: 'POST', body, ms });
    // un 400 che non riguarda la chiave: probabilmente il modello non accetta questa impostazione, prova la successiva
    if (!(r.status === 400 && !/api key/i.test(r.data?.error?.message || '') && i < THINK_MODES.length - 1)) break;
  }
  if (r.ok && S.settings.think[name] !== i) { S.settings.think[name] = i; save(); }
  // modello sovraccarico (503): un secondo tentativo
  if (r.status === 503) { await new Promise(res => setTimeout(res, 1500)); r = await request(path, { method: 'POST', body, ms }); }

  if (!r.ok) {
    const msg = r.data?.error?.message || '';
    if (r.status === 400 && /api key/i.test(msg)) throw new AIError('Chiave non valida. Controllala in Impostazioni.');
    if (r.status === 403) throw new AIError('Gemini ha rifiutato la chiave o l\'accesso (403). ' + msg);
    if (r.status === 400) throw new AIError('Gemini ha rifiutato la richiesta (400). ' + msg);
    if (r.status === 404) throw new AIError('Modello non trovato. Sceglilo di nuovo in Impostazioni → Avanzate.');
    if (r.status === 429) throw new AIError('Limite gratuito raggiunto. Riprova tra un minuto.');
    if (r.status === 503) throw new AIError('Gemini è sovraccarico in questo momento. Riprova tra poco.');
    throw new AIError(`Errore Gemini (${r.status}). ${msg}`);
  }
  const text = r.data?.candidates?.[0]?.content?.parts?.filter(p => !p.thought).map(p => p.text || '').join('') || '';
  if (!text) throw new AIError('Risposta vuota dal coach. Riprova.');
  return text;
}

// Misura quanto ci mette ogni modello a rispondere a una domanda minuscola
export async function benchModel(name) {
  const t0 = performance.now();
  try {
    await gemini({ model: name, ms: 25000, contents: [{ role: 'user', parts: [{ text: 'Rispondi solo: ok' }] }] });
    return { name, sec: (performance.now() - t0) / 1000 };
  } catch (e) { return { name, sec: null, err: e.message }; }
}

// Elenco dei modelli veloci disponibili per la tua chiave
export async function listModels() {
  const r = await request('/models?pageSize=200', { ms: 15000 });
  if (!r.ok) throw new AIError('Non riesco a leggere i modelli: ' + (r.data?.error?.message || r.status));
  return (r.data.models || [])
    .filter(m => (m.supportedGenerationMethods || []).includes('generateContent'))
    .map(m => m.name.replace(/^models\//, ''))
    .filter(n => /flash/.test(n) && !/image|tts|live|audio|embed|vision|thinking-exp/.test(n))
    .sort();
}
