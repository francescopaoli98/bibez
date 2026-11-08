// Proxy verso Gemini per Cloudflare Pages Functions.
// La chiave di Google vive SOLO qui (secret GEMINI_API_KEY): non arriva mai sul telefono.
// Accesso consentito solo a chi ha fatto il login con Cloudflare Access (il token viene verificato qui).
// Nessun log: i testi passano e basta.
//
// Variabili da impostare nel progetto Pages (vedi CLOUDFLARE.md):
//   GEMINI_API_KEY      (Secret)  chiave di Google AI Studio
//   ACCESS_TEAM_DOMAIN  es. "miosito.cloudflareaccess.com"
//   ACCESS_AUD          "Application Audience (AUD) Tag" dell'applicazione Access
//   ALLOWED_EMAILS      facoltativo, email separate da virgola (extra controllo)
//   DAILY_LIMIT         facoltativo, richieste al giorno per persona (default 300; serve il KV "RATE")

const GOOGLE = 'https://generativelanguage.googleapis.com/v1beta/';
const MODEL_OK = /^models\/gemini-[a-z0-9.\-]+:generateContent$/;
const MAX_BODY = 200_000;

const json = (obj, status = 200) => new Response(JSON.stringify(obj), {
  status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});
const err = (status, message) => json({ error: { message } }, status);

const b64 = (s) => Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/')), c => c.charCodeAt(0));
let jwksCache = { at: 0, keys: null };

async function verifyAccess(request, env) {
  const token = request.headers.get('Cf-Access-Jwt-Assertion');
  if (!token || !env.ACCESS_TEAM_DOMAIN || !env.ACCESS_AUD) return null;
  const [h, p, s] = token.split('.');
  if (!h || !p || !s) return null;
  try {
    const header = JSON.parse(new TextDecoder().decode(b64(h)));
    const claims = JSON.parse(new TextDecoder().decode(b64(p)));
    if (Date.now() / 1000 > claims.exp) return null;
    const aud = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
    if (!aud.includes(env.ACCESS_AUD)) return null;
    if (claims.iss !== `https://${env.ACCESS_TEAM_DOMAIN}`) return null;
    if (!jwksCache.keys || Date.now() - jwksCache.at > 3600_000) {
      const r = await fetch(`https://${env.ACCESS_TEAM_DOMAIN}/cdn-cgi/access/certs`);
      jwksCache = { at: Date.now(), keys: (await r.json()).keys };
    }
    const jwk = jwksCache.keys.find(k => k.kid === header.kid);
    if (!jwk) return null;
    const key = await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
    const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64(s), new TextEncoder().encode(`${h}.${p}`));
    return ok ? (claims.email || '').toLowerCase() : null;
  } catch { return null; }
}

export async function onRequest({ request, env, params }) {
  if (!env.GEMINI_API_KEY) return err(500, 'Proxy non configurato: manca GEMINI_API_KEY.');
  const email = await verifyAccess(request, env);
  if (!email) return err(401, 'Accesso non autorizzato. Ricarica la pagina per fare di nuovo il login.');
  const allowed = (env.ALLOWED_EMAILS || '').toLowerCase().split(',').map(x => x.trim()).filter(Boolean);
  if (allowed.length && !allowed.includes(email)) return err(403, 'Questa email non è autorizzata.');

  const path = [].concat(params.path || []).join('/');
  const isList = request.method === 'GET' && path === 'models';
  const isGen = request.method === 'POST' && MODEL_OK.test(path);
  if (!isList && !isGen) return err(404, 'Richiesta non consentita.');

  let body;
  if (isGen) {
    body = await request.text();
    if (body.length > MAX_BODY) return err(413, 'Richiesta troppo grande.');
  }

  // limite giornaliero per persona (solo se hai collegato il KV "RATE")
  if (env.RATE && isGen) {
    const day = new Date().toISOString().slice(0, 10), k = `rl:${email}:${day}`;
    const n = parseInt(await env.RATE.get(k) || '0', 10);
    if (n >= parseInt(env.DAILY_LIMIT || '300', 10)) return err(429, 'Limite giornaliero raggiunto. Riprova domani.');
    await env.RATE.put(k, String(n + 1), { expirationTtl: 172800 });
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
