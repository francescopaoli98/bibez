// Rinnovo dell'accesso senza password: se il gettone è ancora valido ne dà uno nuovo (altri 90 giorni da adesso).
// Così chi usa l'app almeno una volta ogni 90 giorni non rifà mai il login.
import { json, err, checkToken, newToken, TOKEN_DAYS } from '../_lib/auth.js';

export async function onRequestPost({ request, env }) {
  const who = await checkToken(request, env);
  if (!who) return err(401, 'Accesso scaduto: rifai il login.');
  return json({ token: await newToken(who.user, who.rec.v || 1, env.SESSION_SECRET), exp: Math.floor(Date.now() / 1000) + TOKEN_DAYS * 86400, user: who.user, name: who.rec.n || who.user });
}
