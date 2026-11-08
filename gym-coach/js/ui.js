// Piccoli helper per costruire il DOM senza librerie.
export function h(tag, attrs, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v == null || v === false) continue;
    if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
    else if (k === 'class') el.className = v;
    else if (k === 'html') el.innerHTML = v;          // usare solo con testo fidato
    else if (k === 'value') el.value = v;
    else el.setAttribute(k, v === true ? '' : v);
  }
  for (const kid of kids.flat(Infinity)) {
    if (kid == null || kid === false) continue;
    el.append(kid.nodeType ? kid : document.createTextNode(kid));
  }
  return el;
}

export function icon(name) {
  const paths = {
    home: '<path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/>',
    list: '<path d="M8 6h13M8 12h13M8 18h13"/><circle cx="3.5" cy="6" r="1"/><circle cx="3.5" cy="12" r="1"/><circle cx="3.5" cy="18" r="1"/>',
    dumbbell: '<path d="M6 7v10M3 9v6M18 7v10M21 9v6M6 12h12"/>',
    chat: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-5.4A8 8 0 1 1 21 12z"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
    check: '<path d="M5 12l5 5L20 7"/>',
  };
  const s = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  s.setAttribute('viewBox', '0 0 24 24');
  s.innerHTML = paths[name] || '';
  return s;
}

let toastT;
export function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg; t.classList.add('show');
  clearTimeout(toastT); toastT = setTimeout(() => t.classList.remove('show'), 2600);
}

// Pannello che sale dal basso
export function openSheet(content) {
  const root = document.getElementById('sheet-root');
  closeSheet();
  const back = h('div', { class: 'backdrop', onclick: closeSheet });
  const sheet = h('div', { class: 'sheet' }, h('div', { class: 'grab' }), content);
  root.append(back, sheet);
  document.body.style.overflow = 'hidden';
}
export function closeSheet() {
  document.getElementById('sheet-root').replaceChildren();
  document.body.style.overflow = '';
}

// Markdown minimale e sicuro (grassetto + elenchi) per le risposte del coach
export function mdLite(text) {
  const box = h('div');
  let ul = null;
  const inline = (s) => {
    const frag = document.createDocumentFragment();
    s.split(/(\*\*[^*]+\*\*)/g).forEach(p => {
      if (/^\*\*[^*]+\*\*$/.test(p)) frag.append(h('b', {}, p.slice(2, -2)));
      else if (p) frag.append(document.createTextNode(p));
    });
    return frag;
  };
  for (const line of text.split('\n')) {
    const m = line.match(/^\s*(?:[-*•]|\d+\.)\s+(.*)$/);
    if (m) {
      if (!ul) { ul = h('ul'); box.append(ul); }
      const li = h('li'); li.append(inline(m[1])); ul.append(li);
    } else {
      ul = null;
      if (line.trim()) { const p = h('p'); p.append(inline(line)); box.append(p); }
    }
  }
  return box;
}
