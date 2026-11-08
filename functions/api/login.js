// Accesso con nome utente e password. Gli account li crei tu (vedi CLOUDFLARE.md): nessuna registrazione libera.
import { json, err, hashPassword, equal, unb64u, newToken, TOKEN_DAYS } from '../_lib/auth.js';

export async function onRequestPost({ request, env }) {
  if (!env.APP) return err(500, 'Server non configurato: manca il collegamento all\'archivio KV (nome "APP").');
  if (!env.SESSION_SECRET) return err(500, 'Server non configurato: manca il segreto SESSION_SECRET.');
  let body; try { body = await request.json(); } catch { return err(400, 'Richiesta non valida.'); }
  const user = String(body.user || '').trim().toLowerCase().slice(0, 40);
  const password = String(body.password || '').slice(0, 200);

  // freno ai tentativi: 10 errori ogni 15 minuti per indirizzo
  const ip = request.headers.get('CF-Connecting-IP') || 'x';
  const rk = `rl:login:${ip}:${Math.floor(Date.now() / 900000)}`;
  const fails = parseInt(await env.APP.get(rk) || '0', 10);
  if (fails >= 10) return err(429, 'Troppi tentativi. Riprova tra 15 minuti.');

  const rec = JSON.parse(await env.APP.get('user:' + user) || 'null');
  const hash = await hashPassword(password, rec ? unb64u(rec.s) : new Uint8Array(16));   // stesso lavoro anche se l'utente non esiste
  if (!rec || !equal(hash, unb64u(rec.h))) {
    await env.APP.put(rk, String(fails + 1), { expirationTtl: 1800 });
    return err(401, 'Nome utente o password sbagliati.');
  }
  return json({ token: await newToken(user, rec.v || 1, env.SESSION_SECRET), exp: Math.floor(Date.now() / 1000) + TOKEN_DAYS * 86400, user, name: rec.n || user });
}
