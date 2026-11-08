// Utilità condivise per gli account: password (PBKDF2), gettoni firmati (HMAC) e risposte JSON.
// Non è una route: contiene solo funzioni.
const te = new TextEncoder();

export const ITER = 100_000;                 // il massimo che Cloudflare Workers consente per PBKDF2
export const TOKEN_DAYS = 90;

export const json = (obj, status = 200) => new Response(JSON.stringify(obj), {
  status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});
export const err = (status, message) => json({ error: { message } }, status);

export const b64u = (buf) => btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
export const unb64u = (s) => Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0));

export async function hashPassword(password, salt) {
  const base = await crypto.subtle.importKey('raw', te.encode(password), 'PBKDF2', false, ['deriveBits']);
  return new Uint8Array(await crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations: ITER, hash: 'SHA-256' }, base, 256));
}
export function equal(a, b) {                // confronto a tempo costante
  if (a.length !== b.length) return false;
  let d = 0; for (let i = 0; i < a.length; i++) d |= a[i] ^ b[i];
  return d === 0;
}

const hmacKey = (secret, usages) => crypto.subtle.importKey('raw', te.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, usages);

export async function signToken(payload, secret) {
  const p = b64u(te.encode(JSON.stringify(payload)));
  const sig = await crypto.subtle.sign('HMAC', await hmacKey(secret, ['sign']), te.encode(p));
  return `${p}.${b64u(sig)}`;
}
export const newToken = (user, v, secret) =>
  signToken({ u: user, v, exp: Math.floor(Date.now() / 1000) + TOKEN_DAYS * 86400 }, secret);

// Controlla firma, scadenza e che l'account esista ancora (e con la stessa "versione": cambiando password i vecchi gettoni muoiono)
export async function checkToken(request, env) {
  const m = /^Bearer (.+)$/.exec(request.headers.get('Authorization') || '');
  if (!m || !env.SESSION_SECRET || !env.APP) return null;
  const [p, s] = m[1].split('.');
  if (!p || !s) return null;
  try {
    const ok = await crypto.subtle.verify('HMAC', await hmacKey(env.SESSION_SECRET, ['verify']), unb64u(s), te.encode(p));
    if (!ok) return null;
    const c = JSON.parse(new TextDecoder().decode(unb64u(p)));
    if (!c.u || Date.now() / 1000 > c.exp) return null;
    const rec = JSON.parse(await env.APP.get('user:' + c.u) || 'null');
    if (!rec || (rec.v || 1) !== c.v) return null;
    return { user: c.u, rec };
  } catch { return null; }
}
