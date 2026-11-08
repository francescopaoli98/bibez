// Schermate di accesso: login con account (primo accesso) e blocco con password (aperture successive).
import { S, unlock, verifyPassword, lockEnabled, resetAll, deviceInfo, unlockWithDevice } from './store.js';
import { h, icon } from './ui.js';
import { bioVerify } from './bio.js';
import { apiLogin } from './account.js';

const FAILS = 'gymcoach:fails';
const root = () => document.getElementById('lock-root');
const getFails = () => { try { return JSON.parse(localStorage.getItem(FAILS)) || { n: 0, until: 0 }; } catch { return { n: 0, until: 0 }; } };
let active = false;
let unlockHook = () => {};
export const setUnlockHook = (fn) => { unlockHook = fn; };       // riceve la password appena inserita (per rinnovare l'accesso)

// Dopo 5 errori: attese sempre più lunghe (5 s, 10 s, 20 s… fino a 5 minuti)
function registerFail() {
  const f = getFails(); f.n++;
  f.until = f.n >= 5 ? Date.now() + Math.min(300, 5 * 2 ** (f.n - 5)) * 1000 : 0;
  localStorage.setItem(FAILS, JSON.stringify(f));
  return f;
}
const logo = () => h('img', { src: 'icons/icon-192.png', alt: '', class: 'lock-logo' });
const close = () => { root().replaceChildren(); document.body.classList.remove('locked'); active = false; };

/* ---- blocco: impronta (se attiva) oppure password ---- */
export function lockScreen({ cold, title = 'Gym Coach', canSwitch = false, bio = null } = {}) {
  if (active) return new Promise(() => {});
  active = true; document.body.classList.add('locked');
  return new Promise(resolve => {
    let timer = null;
    const finish = (password) => { clearInterval(timer); localStorage.removeItem(FAILS); if (password) unlockHook(password); close(); resolve({ password: password || null }); };

    /* --- password --- */
    function passwordView(note) {
      const input = h('input', { type: 'password', placeholder: 'Password', autocomplete: 'current-password', enterkeyhint: 'go', 'aria-label': 'Password' });
      const msg = h('p', { class: 'err center', role: 'alert' }, note || '');
      const btn = h('button', { class: 'btn big block' }, 'Sblocca');
      const tick = () => {
        const left = Math.ceil((getFails().until - Date.now()) / 1000);
        if (left > 0) { msg.textContent = `Troppi tentativi. Riprova tra ${left} s.`; btn.disabled = true; }
        else { clearInterval(timer); timer = null; btn.disabled = false; if (msg.textContent.startsWith('Troppi')) msg.textContent = ''; }
      };
      const startTick = () => { clearInterval(timer); tick(); timer = setInterval(tick, 500); };
      async function submit() {
        if (btn.disabled || !input.value) return;
        const pw = input.value;
        btn.disabled = true; btn.textContent = 'Controllo…'; msg.textContent = '';
        const ok = cold ? await unlock(pw) : await verifyPassword(pw);
        btn.textContent = 'Sblocca';
        if (ok) return finish(pw);
        const f = registerFail(); input.value = '';
        const box = root().firstChild; box?.classList.remove('shake'); void box?.offsetWidth; box?.classList.add('shake');
        if (f.until > Date.now()) startTick(); else { msg.textContent = 'Password sbagliata.'; btn.disabled = false; input.focus(); }
      }
      btn.addEventListener('click', submit);
      input.addEventListener('keydown', e => { if (e.key === 'Enter') submit(); });
      const forgot = h('button', { class: 'linkbtn', onclick: () => {
        if (!confirm('Se hai dimenticato la password i dati di questo telefono non si possono recuperare. Vuoi CANCELLARLI e ricominciare da zero?')) return;
        if (!confirm('Ultima conferma: scheda, storico e chat salvati qui verranno cancellati.')) return;
        resetAll(); location.hash = ''; location.reload();
      } }, 'Password dimenticata?');
      setTimeout(() => { startTick(); input.focus(); }, 50);
      return [h('p', { class: 'muted center' }, 'Inserisci la password per entrare.'), input, msg, btn, bio && h('button', { class: 'linkbtn', onclick: () => mount(bioView()) }, 'Usa l\'impronta'), forgot];
    }

    /* --- impronta --- */
    function bioView(note) {
      const msg = h('p', { class: 'err center', role: 'alert' }, note || '');
      let busy = false;
      async function tryBio() {
        if (busy) return; busy = true; msg.textContent = '';
        try {
          await bioVerify(bio);
          if (cold && !(await unlockWithDevice())) { busy = false; return mount(passwordView('Serve la password: la chiave di questo telefono è scaduta.')); }
          return finish(null);
        } catch { busy = false; msg.textContent = 'Impronta non riconosciuta. Riprova, oppure usa la password.'; }
      }
      setTimeout(tryBio, 350);                                // prova subito, senza dover toccare niente
      return [h('p', { class: 'muted center' }, 'Appoggia il dito per entrare.'),
        h('button', { class: 'bio', 'aria-label': 'Sblocca con l\'impronta', onclick: tryBio }, icon('finger')),
        msg, h('button', { class: 'btn big block', onclick: tryBio }, 'Sblocca con l\'impronta'),
        h('button', { class: 'linkbtn', onclick: () => mount(passwordView()) }, 'Usa la password')];
    }

    const sw = canSwitch && h('button', { class: 'linkbtn', onclick: () => { clearInterval(timer); close(); resolve('switch'); } }, 'Non sei tu? Cambia account');
    function mount(parts) { clearInterval(timer); root().replaceChildren(h('div', { class: 'lock' }, logo(), h('h1', {}, title), ...parts, sw)); }
    mount(bio ? bioView() : passwordView());
  });
}

/* ---- accesso con account (nome utente + password, controllati dal server) ---- */
export function loginScreen({ known = [] } = {}) {
  if (active) return new Promise(() => {});
  active = true; document.body.classList.add('locked');
  return new Promise(resolve => {
    const user = h('input', { type: 'text', placeholder: 'Nome utente', autocomplete: 'username', autocapitalize: 'none', autocorrect: 'off', 'aria-label': 'Nome utente' });
    const pw = h('input', { type: 'password', placeholder: 'Password', autocomplete: 'current-password', enterkeyhint: 'go', 'aria-label': 'Password' });
    const msg = h('p', { class: 'err center', role: 'alert' });
    const btn = h('button', { class: 'btn big block' }, 'Accedi');
    async function submit() {
      if (btn.disabled || !user.value.trim() || !pw.value) return;
      btn.disabled = true; btn.textContent = 'Accesso…'; msg.textContent = '';
      try {
        const d = await apiLogin(user.value.trim(), pw.value);
        const password = pw.value; pw.value = '';
        close(); resolve({ ...d, password });
      } catch (e) {
        msg.textContent = e.message; btn.disabled = false; btn.textContent = 'Accedi';
        const box = root().firstChild; box?.classList.remove('shake'); void box?.offsetWidth; box?.classList.add('shake');
      }
    }
    btn.addEventListener('click', submit);
    [user, pw].forEach(i => i.addEventListener('keydown', e => { if (e.key === 'Enter') submit(); }));
    const people = known.length > 0 && h('div', { class: 'stack' }, h('p', { class: 'muted small center' }, 'Già su questo telefono:'),
      h('div', { class: 'chips', style: 'justify-content:center' }, known.map(k => h('button', { class: 'chip lg', onclick: () => { close(); resolve({ pick: k.u }); } }, k.name))));

    root().replaceChildren(h('div', { class: 'lock' }, logo(), h('h1', {}, 'Gym Coach'),
      h('p', { class: 'muted center' }, 'Accedi con il tuo account.'), user, pw, msg, btn, people,
      h('p', { class: 'muted small center' }, 'Gli account li crea chi gestisce l\'app.')));
    setTimeout(() => user.focus(), 50);
  });
}

// Mentre l'app è in background copre i contenuti; al ritorno, dopo un po', chiede l'impronta (o la password)
export function initAutoLock() {
  let hiddenAt = 0;
  document.addEventListener('visibilitychange', async () => {
    if (!lockEnabled()) return;
    if (document.hidden) { hiddenAt = Date.now(); document.body.classList.add('veil'); return; }
    document.body.classList.remove('veil');
    const dev = await deviceInfo();
    if (dev && !dev.cred) return;                           // resta connesso senza impronta: niente da chiedere
    const min = S.security?.autoLockMin ?? 5;
    if (min >= 0 && Date.now() - hiddenAt >= min * 60000) lockScreen({ cold: false, bio: dev?.cred || null });
  });
}
export const softLock = async () => { if (!lockEnabled()) return; const dev = await deviceInfo(); return lockScreen({ cold: false, bio: dev?.cred || null }); };
