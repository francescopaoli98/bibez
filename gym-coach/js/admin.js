// Strumento locale per creare gli account (hash PBKDF2 identico a quello del server). Niente rete.
const ITER = 100000;
const te = new TextEncoder();
const b64u = (buf) => btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const $ = (id) => document.getElementById(id);

async function hash(password, salt) {
  const base = await crypto.subtle.importKey('raw', te.encode(password), 'PBKDF2', false, ['deriveBits']);
  return crypto.subtle.deriveBits({ name: 'PBKDF2', salt, iterations: ITER, hash: 'SHA-256' }, base, 256);
}
function el(tag, attrs = {}, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) k === 'class' ? (e.className = v) : k.startsWith('on') ? e.addEventListener(k.slice(2), v) : e.setAttribute(k, v);
  kids.forEach(x => e.append(x)); return e;
}
async function copy(text, btn) {
  try { await navigator.clipboard.writeText(text); btn.textContent = 'Copiato ✓'; } catch { btn.textContent = 'Seleziona e copia a mano'; }
  setTimeout(() => { btn.textContent = 'Copia'; }, 2000);
}
function block(title, text) {
  const ta = el('textarea', { readonly: '', rows: '3' }); ta.value = text; ta.addEventListener('click', () => ta.select());
  const b = el('button', { class: 'btn ghost small' }, 'Copia'); b.addEventListener('click', () => copy(text, b));
  return el('div', { class: 'stack' }, el('h3', {}, title), ta, b);
}

$('go').addEventListener('click', async () => {
  const user = $('u').value.trim().toLowerCase(), name = $('n').value.trim() || user, pw = $('p').value;
  const err = $('err'); err.textContent = '';
  if (!/^[a-z0-9._-]{2,30}$/.test(user)) return err.textContent = 'Nome utente: 2-30 caratteri tra lettere minuscole, numeri, punto, trattino.';
  if (pw.length < 8) return err.textContent = 'La password deve avere almeno 8 caratteri.';
  $('go').disabled = true; $('go').textContent = 'Calcolo…';
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const value = JSON.stringify({ n: name, s: b64u(salt), h: b64u(await hash(pw, salt)), v: Math.max(1, parseInt($('v').value) || 1) });
  $('go').disabled = false; $('go').textContent = 'Crea le righe'; $('p').value = '';
  $('out').prepend(el('div', { class: 'card stack' },
    el('h2', {}, `Account: ${name}`),
    el('p', { class: 'muted small' }, 'In Cloudflare: Workers & Pages → KV → il namespace → Add entry. Incolla le due righe qui sotto.'),
    block('Key (chiave)', 'user:' + user), block('Value (valore)', value)));
});

$('sec').addEventListener('click', () => {
  const s = b64u(crypto.getRandomValues(new Uint8Array(32)));
  const out = $('secout'); out.replaceChildren(block('SESSION_SECRET', s));
});
