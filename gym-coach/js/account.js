// Account dell'app: due persone (tu e Irene), create da chi gestisce l'app. Il server controlla la password;
// i dati restano sul telefono, cifrati con la stessa password.
import { S, save } from './store.js';

// Attivo sul sito di Cloudflare (*.pages.dev). In locale si prova con localStorage 'gymcoach:accounts' = '1'.
export const accountsMode = () => /\.(pages|workers)\.dev$/.test(location.hostname) || localStorage.getItem('gymcoach:accounts') === '1';

const USERS = 'gymcoach:users', LAST = 'gymcoach:lastuser';
export const knownUsers = () => { try { return JSON.parse(localStorage.getItem(USERS)) || []; } catch { return []; } };
export const lastUser = () => localStorage.getItem(LAST) || '';
export function rememberUser(u, name) {
  const list = knownUsers().filter(k => k.u !== u); list.push({ u, name });
  localStorage.setItem(USERS, JSON.stringify(list)); localStorage.setItem(LAST, u);
}
export const forgetLast = () => localStorage.removeItem(LAST);

let session = null;                  // {user, name, token, exp, pw}  (la password resta solo in memoria)
export const getSession = () => session;
export const setSession = (s) => { session = s; };

async function api(path, body, token) {
  let res;
  try {
    res = await fetch(path, { method: 'POST', cache: 'no-store', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) }, body: JSON.stringify(body) });
  } catch { throw Object.assign(new Error('Nessuna connessione: per questa operazione serve internet.'), { offline: true }); }
  const data = await res.json().catch(() => null);
  if (!res.ok) throw Object.assign(new Error(data?.error?.message || `Errore (${res.status})`), { status: res.status });
  return data;
}
export const apiLogin = (user, password) => api('/api/login', { user, password });

function applyToken(d) {
  if (!session) return;
  session.token = d.token; session.exp = d.exp;
  S.account = { ...(S.account || {}), user: session.user, name: session.name, token: d.token, exp: d.exp }; save();
}
// Rinnova il gettone con la password già inserita (silenzioso: se sei offline resta quello di prima)
export async function refreshSession() {
  if (session?.token) {                                     // prima il rinnovo senza password (altri 90 giorni)
    try { const d = await api('/api/refresh', {}, session.token); applyToken(d); return; }
    catch (e) { if (e.offline || !session.pw) throw e; }
  }
  if (!session?.pw) throw new Error('Accedi di nuovo.');
  applyToken(await apiLogin(session.user, session.pw));
}
export async function changeAccountPassword(oldPw, newPw) {
  if (!session?.token) throw new Error('Accedi di nuovo.');
  const d = await api('/api/password', { old: oldPw, new: newPw }, session.token);
  session.pw = newPw; applyToken(d);
}
