// Dati dell'app, salvati solo sul telefono (localStorage).
// Con il blocco attivo tutto viene CIFRATO (AES-GCM, chiave derivata dalla password con PBKDF2):
// senza password i dati sul telefono sono illeggibili, anche per chi guarda i file.
const KEY = 'gymcoach:v1';          // dati in chiaro (blocco non attivo)
const ENC = 'gymcoach:enc';          // dati cifrati (blocco attivo)
const FAILS = 'gymcoach:fails';

// Con gli account ogni persona ha i suoi dati sul telefono (chiavi con il suffisso del nome utente)
let user = '';
export const setUser = (u) => { user = u || ''; };
const K = () => (user ? `${KEY}:${user}` : KEY);
const E = () => (user ? `${ENC}:${user}` : ENC);
export const hasUserData = (u) => !!localStorage.getItem(u ? `${ENC}:${u}` : ENC);
const ITER = 600_000;

const DEFAULT = {
  profile: null,            // {nome, obiettivo, livello, giorni, casa, peso, altezza, eta, sesso, note}
  plan: null,               // {nome, giorni:[{nome, esercizi:[{id, serie, ripetizioni, recupero}]}]}
  history: [],              // allenamenti completati
  pesi: [],                 // [{date, kg}] peso corporeo
  reminder: null,           // {days:[1,3,5], time:'18:00'}
  settings: { apiKey: '', model: 'gemini-flash-latest' },
  account: null,            // {user, name, token, exp}: l'account con cui hai fatto accesso
  security: { autoLockMin: -1, stay: true, stayDays: 90, v: 2 },   // blocco dopo N minuti in background (-1 = mai: la password solo all'apertura); resta connesso (giorni)
  session: null,            // allenamento in corso
  chat: [],                 // (vecchio formato, migrato in chats)
  memoria: [],              // cose durevoli che il coach ricorda (poche righe, modificabili)
  chats: [],                // [{id, title, created, updated, messages:[{role, text, proposal?}]}]
  activeChat: null,         // id della chat aperta (null = nuova chat vuota)
  remind: { pesoDays: 7, salute: true },   // promemoria: peso ogni N giorni (0 = mai), rivedere la salute ogni 3 mesi
  seen: {},                 // cose già viste (guida, primo avvio…)
  luogo: 'palestra',        // 'palestra' | 'casa' (dove ti alleni oggi)
  nextDay: 0,               // indice del prossimo giorno in scheda
  planBackup: null,         // scheda prima dell'ultima modifica del coach (per annullare)
};

// Oggetto condiviso da tutti i moduli: viene riempito all'avvio (initStore) o dopo lo sblocco.
export const S = structuredClone(DEFAULT);

function applyData(d) {
  Object.assign(S, structuredClone(DEFAULT), d || {});
  S.settings = { ...DEFAULT.settings, ...((d && d.settings) || {}) };
  S.security = { ...DEFAULT.security, ...((d && d.security) || {}) };
  if ((S.security.v || 0) < 2) { S.security.autoLockMin = -1; S.security.v = 2; }     // chi aveva il vecchio valore (5 minuti): ora la password si chiede solo all'apertura
  if (S.chat?.length && !S.chats.length) {                 // migra la vecchia chat unica nello storico
    const first = S.chat.find(m => m.role === 'user')?.text || 'Chat';
    S.chats = [{ id: 'c' + Date.now().toString(36), title: first.length > 30 ? first.slice(0, 28) + '…' : first, created: Date.now(), updated: Date.now(), messages: S.chat }];
    S.chat = [];
  }
}

/* ---------- cifratura ---------- */
const te = new TextEncoder(), td = new TextDecoder();
const toB64 = (u8) => { let s = ''; for (let i = 0; i < u8.length; i += 0x8000) s += String.fromCharCode(...u8.subarray(i, i + 0x8000)); return btoa(s); };
const fromB64 = (s) => Uint8Array.from(atob(s), c => c.charCodeAt(0));

let aesKey = null;                   // chiave in memoria solo mentre il blocco è sbloccato
let meta = null;                     // {salt, iter}
let chain = Promise.resolve();       // scritture cifrate in ordine

async function derive(password, salt, iter) {
  const base = await crypto.subtle.importKey('raw', te.encode(password), 'PBKDF2', false, ['deriveKey']);
  return crypto.subtle.deriveKey({ name: 'PBKDF2', salt, iterations: iter, hash: 'SHA-256' }, base, { name: 'AES-GCM', length: 256 }, false, ['encrypt', 'decrypt']);
}
async function writeEnc(json) {
  if (!aesKey || !meta) return;
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ct = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, aesKey, te.encode(json)));
  localStorage.setItem(E(), JSON.stringify({ v: 1, salt: toB64(meta.salt), iter: meta.iter, iv: toB64(iv), ct: toB64(ct) }));
}
function readBlob() { try { return JSON.parse(localStorage.getItem(E())); } catch { return null; } }
async function decryptBlob(blob, password) {
  try {
    const salt = fromB64(blob.salt);
    const key = await derive(password, salt, blob.iter);
    const pt = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: fromB64(blob.iv) }, key, fromB64(blob.ct));
    return { key, salt, iter: blob.iter, data: JSON.parse(td.decode(pt)) };
  } catch { return null; }        // password sbagliata (il tag di autenticazione non torna)
}

export const lockEnabled = () => !!localStorage.getItem(E());

/* ---------- chiave del dispositivo: per restare connessi senza riscrivere la password ----------
   La chiave AES (non estraibile: nemmeno l'app può leggerne i byte) resta nel browser per N giorni.
   Il tempo riparte a ogni apertura. Con l'impronta attiva, prima di usarla si chiede l'impronta. */
const IDBNAME = 'gymcoach-dev', IDBSTORE = 'keys';
const idb = () => new Promise((res, rej) => { const r = indexedDB.open(IDBNAME, 1); r.onupgradeneeded = () => r.result.createObjectStore(IDBSTORE); r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); });
const idbDo = async (mode, fn) => { const db = await idb(); return new Promise((res, rej) => { const q = fn(db.transaction(IDBSTORE, mode).objectStore(IDBSTORE)); q.onsuccess = () => res(q.result ?? null); q.onerror = () => rej(q.error); }); };
const devId = () => user || '_';
const devGet = () => idbDo('readonly', s => s.get(devId())).catch(() => null);
const devPut = (v) => idbDo('readwrite', s => s.put(v, devId()));

export async function deviceInfo() {
  const r = await devGet();
  return r && r.expiresAt > Date.now() ? { days: r.days, cred: r.cred || null, expiresAt: r.expiresAt } : null;
}
export async function rememberDevice(days = 90, cred) {
  if (!aesKey) return false;
  const prev = await devGet();
  try { await devPut({ key: aesKey, days, expiresAt: Date.now() + days * 864e5, cred: cred !== undefined ? cred : (prev?.cred || null) }); return true; } catch { return false; }
}
export async function forgetDevice() { try { await idbDo('readwrite', s => s.delete(devId())); } catch {} }
export async function unlockWithDevice() {
  const rec = await devGet(), blob = readBlob();
  if (!rec || !blob || rec.expiresAt <= Date.now()) return false;
  try {
    const pt = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: fromB64(blob.iv) }, rec.key, fromB64(blob.ct));
    aesKey = rec.key; meta = { salt: fromB64(blob.salt), iter: blob.iter }; applyData(JSON.parse(td.decode(pt)));
    rec.expiresAt = Date.now() + rec.days * 864e5; await devPut(rec).catch(() => {});      // il tempo riparte
    return true;
  } catch { return false; }
}

export async function initStore() {
  if (lockEnabled()) return 'locked';
  try { applyData(JSON.parse(localStorage.getItem(K()) || '{}')); } catch { applyData({}); }
  return 'ok';
}
export async function unlock(password) {
  const blob = readBlob(); if (!blob) return false;
  const r = await decryptBlob(blob, password); if (!r) return false;
  aesKey = r.key; meta = { salt: r.salt, iter: r.iter }; applyData(r.data);
  return true;
}
export async function verifyPassword(password) { const blob = readBlob(); return !!(blob && await decryptBlob(blob, password)); }

export async function enableLock(password) {
  meta = { salt: crypto.getRandomValues(new Uint8Array(16)), iter: ITER };
  aesKey = await derive(password, meta.salt, meta.iter);
  await writeEnc(JSON.stringify(S));
  localStorage.removeItem(K());                   // via i dati in chiaro
}
export async function disableLock(password) {
  if (!(await verifyPassword(password))) return false;
  await chain;
  localStorage.setItem(K(), JSON.stringify(S));
  localStorage.removeItem(E()); aesKey = null; meta = null; await forgetDevice();
  return true;
}
export async function changePassword(oldPw, newPw) {
  if (!(await verifyPassword(oldPw))) return false;
  await chain;
  const prevDev = await devGet();
  meta = { salt: crypto.getRandomValues(new Uint8Array(16)), iter: ITER };
  aesKey = await derive(newPw, meta.salt, meta.iter);
  await writeEnc(JSON.stringify(S));
  if (prevDev) await devPut({ ...prevDev, key: aesKey }).catch(() => {});        // la chiave del dispositivo segue la nuova password
  return true;
}

export function save() {
  try {
    if (lockEnabled() || aesKey) {
      const snap = JSON.stringify(S);
      chain = chain.then(() => writeEnc(snap)).catch(e => console.warn('save failed', e));
    } else localStorage.setItem(K(), JSON.stringify(S));
  } catch (e) { console.warn('save failed', e); }
}

export function resetAll() { [K(), E(), FAILS].forEach(k => localStorage.removeItem(k)); aesKey = null; meta = null; forgetDevice(); }
// Il backup non contiene mai la chiave Gemini
export function exportJSON() { const c = structuredClone(S); c.settings.apiKey = ''; return JSON.stringify(c, null, 2); }
export function importJSON(text) {
  const d = JSON.parse(text);
  if (!d || typeof d !== 'object' || !d.profile || !d.plan) throw new Error('Il file non sembra un backup di Gym Coach.');
  const keep = { apiKey: S.settings.apiKey, ownKey: S.settings.ownKey, model: S.settings.model };
  applyData(d); Object.assign(S.settings, keep); save();
}
