// Cambio password (dall'app, con la password attuale). I vecchi gettoni smettono di valere.
import { json, err, hashPassword, equal, unb64u, b64u, checkToken, newToken, TOKEN_DAYS } from '../_lib/auth.js';

export async function onRequestPost({ request, env }) {
  const who = await checkToken(request, env);
  if (!who) return err(401, 'Accesso non valido: rifai il login.');
  let body; try { body = await request.json(); } catch { return err(400, 'Richiesta non valida.'); }
  const oldPw = String(body.old || '').slice(0, 200), newPw = String(body.new || '').slice(0, 200);
  if (newPw.length < 8) return err(400, 'La nuova password deve avere almeno 8 caratteri.');
  if (!equal(await hashPassword(oldPw, unb64u(who.rec.s)), unb64u(who.rec.h))) return err(403, 'La password attuale non è corretta.');

  const salt = crypto.getRandomValues(new Uint8Array(16));
  const rec = { ...who.rec, s: b64u(salt), h: b64u(await hashPassword(newPw, salt)), v: (who.rec.v || 1) + 1 };
  await env.APP.put('user:' + who.user, JSON.stringify(rec));
  return json({ token: await newToken(who.user, rec.v, env.SESSION_SECRET), exp: Math.floor(Date.now() / 1000) + TOKEN_DAYS * 86400 });
}
