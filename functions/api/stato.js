// Controllo della configurazione: dice solo se le tre cose necessarie ci sono (sì/no). Nessun dato, nessun nome.
import { json } from '../_lib/auth.js';

export async function onRequestGet({ env }) {
  return json({ archivio_kv: !!env.APP, segreto_sessione: !!env.SESSION_SECRET, chiave_gemini: !!env.GEMINI_API_KEY });
}
