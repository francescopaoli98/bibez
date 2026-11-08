// Proxy verso Gemini: la chiave di Google vive SOLO sul server (secret GEMINI_API_KEY) e non arriva mai sul telefono.
// Funziona solo con un account valido dell'app (gettone firmato nell'intestazione Authorization). Nessun log.
import { err, checkToken } from './auth.js';

const GOOGLE = 'https://generativelanguage.googleapis.com/v1beta/';
const MODEL_OK = /^models\/gemini-[a-z0-9.\-]+:generateContent$/;
const MAX_BODY = 200_000;

export async function handleGemini({ request, env, path }) {
  if (!env.GEMINI_API_KEY) return err(500, 'Proxy non configurato: manca GEMINI_API_KEY.');
  const who = await checkToken(request, env);
  if (!who) return err(401, 'Accesso non valido: rifai il login.');

  const isList = request.method === 'GET' && path === 'models';
  const isGen = request.method === 'POST' && MODEL_OK.test(path);
  if (!isList && !isGen) return err(404, 'Richiesta non consentita.');

  let body;
  if (isGen) {
    body = await request.text();
    if (body.length > MAX_BODY) return err(413, 'Richiesta troppo grande.');
    // limite giornaliero per persona
    const k = `rl:gem:${who.user}:${new Date().toISOString().slice(0, 10)}`;
    const n = parseInt(await env.APP.get(k) || '0', 10);
    if (n >= parseInt(env.DAILY_LIMIT || '300', 10)) return err(429, 'Limite giornaliero raggiunto. Riprova domani.');
    await env.APP.put(k, String(n + 1), { expirationTtl: 172800 });
  }

  const upstream = await fetch(GOOGLE + path + (isList ? '?pageSize=200' : ''), {
    method: request.method,
    headers: { 'Content-Type': 'application/json', 'x-goog-api-key': env.GEMINI_API_KEY },
    body,
  });
  return new Response(upstream.body, {
    status: upstream.status,
    headers: { 'Content-Type': upstream.headers.get('Content-Type') || 'application/json', 'Cache-Control': 'no-store' },
  });
}
