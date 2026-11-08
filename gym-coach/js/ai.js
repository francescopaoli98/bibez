// Chiamate a Gemini direttamente dal telefono. La chiave resta solo sul dispositivo.
import { S } from './store.js';

export class AIError extends Error {}

export async function gemini({ system, contents, json = false, temperature = 0.7 }) {
  const { apiKey, model } = S.settings;
  if (!apiKey) throw new AIError('Manca la chiave Gemini. Aggiungila in Profilo.');
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model || 'gemini-flash-latest')}:generateContent`;
  const body = {
    contents,
    generationConfig: { temperature, ...(json ? { responseMimeType: 'application/json' } : {}) },
  };
  if (system) body.systemInstruction = { parts: [{ text: system }] };

  let res;
  try {
    res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify(body),
    });
  } catch {
    throw new AIError('Nessuna connessione. Controlla la rete e riprova.');
  }
  if (!res.ok) {
    let msg = '';
    try { msg = (await res.json()).error?.message || ''; } catch {}
    if (res.status === 400 || res.status === 403) throw new AIError('Chiave non valida o modello non disponibile. ' + msg);
    if (res.status === 429) throw new AIError('Limite gratuito raggiunto. Riprova tra un minuto.');
    throw new AIError(`Errore Gemini (${res.status}). ${msg}`);
  }
  const data = await res.json();
  const text = data.candidates?.[0]?.content?.parts?.map(p => p.text || '').join('') || '';
  if (!text) throw new AIError('Risposta vuota dal coach. Riprova.');
  return text;
}
