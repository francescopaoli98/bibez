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
    gambe: '<path d="M9 3v7l-2 11M15 3v7l2 11M9 10h6"/>',
    petto: '<path d="M3 9c3-3 6-3 9 0 3-3 6-3 9 0v4c-3 3-6 3-9 0-3 3-6 3-9 0z"/>',
    schiena: '<path d="M12 3v18M5 6c3 2 4 5 4 9M19 6c-3 2-4 5-4 9"/>',
    spalle: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3-7 8-7s8 3 8 7"/>',
    braccia: '<path d="M5 19l5-5M14 10l5-5M3 17l4 4M17 3l4 4M8 16l8-8"/>',
    core: '<rect x="8" y="3.5" width="8" height="17" rx="3"/><path d="M8 9.5h8M8 14.5h8M12 3.5v17"/>',
    cardio: '<path d="M3 12h4l2-5 4 10 2-5h6"/>',
    trophy: '<path d="M7 4h10v5a5 5 0 0 1-10 0zM7 6H4v2a3 3 0 0 0 3 3M17 6h3v2a3 3 0 0 1-3 3M12 14v4M8 21h8"/>',
    aspetto: '<circle cx="12" cy="12" r="9"/><circle cx="8.5" cy="10" r="1"/><circle cx="12" cy="7.5" r="1"/><circle cx="15.5" cy="10" r="1"/>',
    promemoria: '<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 21h4"/>',
    sicurezza: '<rect x="5" y="11" width="14" height="10" rx="3"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
    avanzate: '<path d="M4 7h10M18 7h2M4 17h2M10 17h10"/><circle cx="16" cy="7" r="2"/><circle cx="8" cy="17" r="2"/>',
    // --- set "tessere": linea + riempimento morbido (.f) ---
    oggi: '<rect class="f" x="3.5" y="5" width="17" height="15.5" rx="3.5"/><path d="M8 3v4M16 3v4M3.5 10h17"/><path d="M9 15.2l2.2 2.2 4.3-4.4"/>',
    scheda: '<rect class="f" x="5" y="4" width="14" height="17" rx="3"/><rect x="9" y="2.5" width="6" height="3.5" rx="1.2"/><path d="M9 11h6M9 15h4"/>',
    coach: '<path class="f" d="M20.5 12a8.5 8.5 0 0 1-12.3 7.6L4 20.8l1.3-4A8.5 8.5 0 1 1 20.5 12z"/><path d="M12 7.8l1.1 2.9 2.9 1.1-2.9 1.1L12 15.8l-1.1-2.9L8 11.8l2.9-1.1z" fill="currentColor" stroke="none"/>',
    prog: '<rect class="f" x="3.5" y="3.5" width="17" height="17" rx="3.5"/><path d="M7 15.5l3.5-4 3 2.5 4-5.5"/><path d="M14.5 8.5h3v3"/>',
    casa: '<path class="f" d="M4 11l8-7 8 7v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z"/><path d="M10 21v-5a2 2 0 0 1 4 0v5"/>',
    palestra: '<path d="M7 12h10"/><rect class="f" x="3.8" y="7.5" width="3.4" height="9" rx="1.4"/><rect class="f" x="16.8" y="7.5" width="3.4" height="9" rx="1.4"/><path d="M2 10.5v3M22 10.5v3"/>',
    tempo: '<circle class="f" cx="12" cy="13.5" r="7.5"/><path d="M10 2.8h4M12 2.8V6M12 13.5V9.6M18.2 7.2l1.2-1.2"/>',
    kcal: '<path class="f" d="M12 21.2c-4 0-6.5-2.6-6.5-6 0-3 2-4.8 3.2-7 .4 1.8 1.4 2.8 2.3 3.2C11 8 12 5 14 3c.5 3.5 4.5 5.8 4.5 11.2 0 3.7-2.5 7-6.5 7z"/><path d="M12 21c-1.8 0-3-1.2-3-2.8 0-1.6 1.4-2.4 3-4.2 1.6 1.8 3 2.6 3 4.2 0 1.6-1.2 2.8-3 2.8z"/>',
    peso: '<rect class="f" x="3.5" y="4" width="17" height="16" rx="4"/><path d="M8.5 10.5a4.5 4.5 0 0 1 7 0"/><path d="M12 11l1.5-1.8"/>',
    salute: '<path class="f" d="M12 20.5C5.5 16 3 12.5 3 9a4.5 4.5 0 0 1 9-1 4.5 4.5 0 0 1 9 1c0 3.5-2.5 7-9 11.5z"/><path d="M7 12h3l1.5-3 2 5 1.5-2h2"/>',
    pillola: '<g transform="rotate(-45 12 12)"><rect class="f" x="2.5" y="8.5" width="19" height="7" rx="3.5"/><path d="M12 8.5v7"/></g>',
    idea: '<path class="f" d="M12 3a6 6 0 0 0-3.5 10.900c.6.5 1 1.2 1 2.100h5c0-.9.4-1.6 1-2.100A6 6 0 0 0 12 3z"/><path d="M9.5 18.5h5M10.5 21h3"/>',
    fatto: '<circle class="f" cx="12" cy="12" r="9"/><path d="M8 12.300l2.8 2.8 5.2-5.6"/>',
    aiuto: '<circle class="f" cx="12" cy="12" r="9"/><path d="M9.5 9.7a2.5 2.5 0 1 1 3.5 2.300c-.7.4-1 .9-1 1.7"/><path d="M12 17h.01"/>',
    send: '<path d="M5 12h14M13 6l6 6-6 6"/>',
    mic: '<rect x="9" y="2" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0 0 14 0M12 18v4"/>',
    home: '<path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/>',
    list: '<path d="M8 6h13M8 12h13M8 18h13"/><circle cx="3.5" cy="6" r="1"/><circle cx="3.5" cy="12" r="1"/><circle cx="3.5" cy="18" r="1"/>',
    dumbbell: '<path d="M6 7v10M3 9v6M18 7v10M21 9v6M6 12h12"/>',
    chat: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-5.4A8 8 0 1 1 21 12z"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
    check: '<path d="M5 12l5 5L20 7"/>',
    gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    minus: '<path d="M5 12h14"/>',
    chart: '<path d="M3 20h18"/><path d="M6 16v-5M11 16V7M16 16v-8M21 16V4"/>',
    help: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.4-1 .9-1 1.7"/><path d="M12 17h.01"/>',
    heart: '<path d="M12 21C5 16 2 12 2 8.5A4.5 4.5 0 0 1 12 6a4.5 4.5 0 0 1 10 2.5C22 12 19 16 12 21z"/>',
    warn: '<path d="M12 3l10 18H2z"/><path d="M12 10v5M12 18h.01"/>',
    finger: '<path d="M12 10a2 2 0 0 0-2 2c0 1.02-.1 2.51-.26 4"/><path d="M14 13.12c0 2.38 0 6.38-1 8.88"/><path d="M17.29 21.02c.12-.6.43-2.3.5-3.02"/><path d="M2 12a10 10 0 0 1 18-6"/><path d="M2 16h.01"/><path d="M21.8 16c.2-2 .131-5.354 0-6"/><path d="M5 19.5C5.5 18 6 15 6 12a6 6 0 0 1 .34-2"/><path d="M8.65 22c.21-.66.45-1.32.57-2"/><path d="M9 6.8a6 6 0 0 1 9 5.2v2"/>',
    history: '<path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/><path d="M12 7v5l3 2"/>',
    trash: '<path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14M10 10v6M14 10v6"/>',
  };
  const s = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  s.setAttribute('viewBox', '0 0 24 24');
  s.innerHTML = paths[name] || '';
  return s;
}

// Tessera colorata con la scintilla del logo: ogni funzione ha il suo colore
const TILES = {aspetto:['#a6ff2e','#4d9a0a'],promemoria:['#ff9a3c','#e0431f'],sicurezza:['#2dd4bf','#0f766e'],avanzate:['#8d99b0','#3a4658'],trophy:['#fde047','#ca8a04'],gambe:['#2dd4bf','#0f766e'],petto:['#f472b6','#be185d'],schiena:['#60a5fa','#1d4ed8'],spalle:['#fde047','#ca8a04'],braccia:['#a78bfa','#6d28d9'],core:['#ff9a3c','#e0431f'],cardio:['#ff6b6b','#b91c1c'],casa:['#2dd4bf','#0f766e'],palestra:['#818cf8','#4338ca'],tempo:['#38bdf8','#0369a1'],kcal:['#ff9a3c','#e0431f'],peso:['#f472b6','#be185d'],salute:['#ff6b6b','#b91c1c'],pillola:['#a78bfa','#6d28d9'],idea:['#fde047','#ca8a04'],fatto:['#4ade80','#15803d'],aiuto:['#60a5fa','#1d4ed8'],oggi:['#a6ff2e','#4d9a0a'],scheda:['#60a5fa','#1d4ed8'],coach:['#c084fc','#7e22ce'],prog:['#ff9a3c','#e0431f']};
export function tile(name, size = 20) {
  const [a, b] = TILES[name] || TILES.oggi, s = Math.round(size * 1.7);
  const g = icon(name); g.setAttribute('class', 'glyph'); g.style.setProperty('--g', size + 'px');
  const sp = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); sp.setAttribute('viewBox', '0 0 24 24'); sp.setAttribute('class', 'sp');
  sp.innerHTML = '<path d="M12 1l2.6 7.4L22 11l-7.4 2.6L12 21l-2.6-7.4L2 11l7.4-2.6z"/>';
  return h('span', { class: 'tile', style: `width:${s}px;height:${s}px;background:linear-gradient(150deg,${a},${b})` }, g, sp);
}

let toastT;
export function toast(msg, ms) {
  const t = document.getElementById('toast');
  t.textContent = msg; t.classList.add('show');
  clearTimeout(toastT); toastT = setTimeout(() => t.classList.remove('show'), ms || Math.min(9000, 2600 + msg.length * 45));
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
export function mdLite(text, stagger = false) {
  const box = h('div');
  let n = 0;                                  // con stagger i blocchi compaiono uno dopo l'altro
  const tag = (el) => { if (stagger) { el.classList.add('reveal'); el.style.setProperty('--i', n++); } return el; };
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
      const li = tag(h('li')); li.append(inline(m[1])); ul.append(li);
    } else {
      ul = null;
      if (line.trim()) { const p = tag(h('p')); p.append(inline(line)); box.append(p); }
    }
  }
  return box;
}
