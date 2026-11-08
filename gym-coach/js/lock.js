// Schermata di blocco: password all'apertura e dopo un po' in background.
import { S, unlock, verifyPassword, lockEnabled, resetAll } from './store.js';
import { h } from './ui.js';

const FAILS = 'gymcoach:fails';
const root = () => document.getElementById('lock-root');
const getFails = () => { try { return JSON.parse(localStorage.getItem(FAILS)) || { n: 0, until: 0 }; } catch { return { n: 0, until: 0 }; } };
let active = false;

// Dopo 5 errori: attese sempre più lunghe (5 s, 10 s, 20 s… fino a 5 minuti)
function registerFail() {
  const f = getFails(); f.n++;
  f.until = f.n >= 5 ? Date.now() + Math.min(300, 5 * 2 ** (f.n - 5)) * 1000 : 0;
  localStorage.setItem(FAILS, JSON.stringify(f));
  return f;
}

export function lockScreen({ cold }) {
  if (active) return new Promise(() => {});
  active = true;
  document.body.classList.add('locked');
  return new Promise(resolve => {
    const input = h('input', { type: 'password', placeholder: 'Password', autocomplete: 'current-password', enterkeyhint: 'go', 'aria-label': 'Password' });
    const msg = h('p', { class: 'err center', role: 'alert' });
    const btn = h('button', { class: 'btn big block' }, 'Sblocca');
    let timer = null;

    const tick = () => {
      const left = Math.ceil((getFails().until - Date.now()) / 1000);
      if (left > 0) { msg.textContent = `Troppi tentativi. Riprova tra ${left} s.`; btn.disabled = true; }
      else { clearInterval(timer); timer = null; btn.disabled = false; if (msg.textContent.startsWith('Troppi')) msg.textContent = ''; }
    };
    const startTick = () => { clearInterval(timer); tick(); timer = setInterval(tick, 500); };

    async function submit() {
      if (btn.disabled || !input.value) return;
      btn.disabled = true; btn.textContent = 'Controllo…'; msg.textContent = '';
      const ok = cold ? await unlock(input.value) : await verifyPassword(input.value);
      btn.textContent = 'Sblocca';
      if (ok) {
        localStorage.removeItem(FAILS); clearInterval(timer);
        root().replaceChildren(); document.body.classList.remove('locked'); active = false; resolve(); return;
      }
      const f = registerFail(); input.value = '';
      root().firstChild?.classList.remove('shake'); void root().firstChild?.offsetWidth; root().firstChild?.classList.add('shake');
      if (f.until > Date.now()) startTick(); else { msg.textContent = 'Password sbagliata.'; btn.disabled = false; input.focus(); }
    }
    btn.addEventListener('click', submit);
    input.addEventListener('keydown', e => { if (e.key === 'Enter') submit(); });

    const forgot = h('button', { class: 'linkbtn', onclick: () => {
      if (!confirm('Se hai dimenticato la password i dati non si possono recuperare. Vuoi CANCELLARE tutto e ricominciare da zero?')) return;
      if (!confirm('Ultima conferma: scheda, storico, chat e impostazioni verranno cancellati.')) return;
      resetAll(); location.hash = ''; location.reload();
    } }, 'Password dimenticata?');

    root().replaceChildren(h('div', { class: 'lock' },
      h('img', { src: 'icons/icon-192.png', alt: '', class: 'lock-logo' }),
      h('h1', {}, 'Gym Coach'), h('p', { class: 'muted center' }, 'Inserisci la password per entrare.'),
      input, msg, btn, forgot));
    startTick(); setTimeout(() => input.focus(), 50);
  });
}

// Mentre l'app è in background copre i contenuti; al ritorno chiede la password se è passato abbastanza tempo
export function initAutoLock() {
  let hiddenAt = 0;
  document.addEventListener('visibilitychange', () => {
    if (!lockEnabled()) return;
    if (document.hidden) { hiddenAt = Date.now(); document.body.classList.add('veil'); return; }
    document.body.classList.remove('veil');
    const min = S.security?.autoLockMin ?? 5;
    if (min >= 0 && Date.now() - hiddenAt >= min * 60000) lockScreen({ cold: false });
  });
}
export const softLock = () => lockEnabled() && lockScreen({ cold: false });
