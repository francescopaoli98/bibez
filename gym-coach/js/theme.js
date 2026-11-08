// Colori del tema modificabili (colore principale e sfondo). Salvati sul dispositivo e applicati subito.
const KEY = 'gymcoach:theme';
export const PRESETS = [
  ['Lime', '#b6ff3b'], ['Azzurro', '#38d6ff'], ['Rosa', '#ff5fa2'], ['Arancio', '#ff9f3b'], ['Viola', '#a78bfa'], ['Menta', '#3df5b5'], ['Rosso', '#ff5a5f'], ['Giallo', '#ffd93b'],
];
export const BACKGROUNDS = {
  grafite: { name: 'Grafite', bg: '#0a0d12', card: '#141922', card2: '#1b222d', line: '#252d3a' },
  nero:    { name: 'Nero',    bg: '#000000', card: '#0e0f12', card2: '#17181c', line: '#25262b' },
  notte:   { name: 'Notte',   bg: '#070b1a', card: '#0f1630', card2: '#171f3f', line: '#263056' },
};
const DEFAULT = { accent: '#b6ff3b', bg: 'grafite', sound: true, haptics: true };
let T = { ...DEFAULT };
try { T = { ...DEFAULT, ...JSON.parse(localStorage.getItem(KEY) || '{}') }; } catch {}
export const getTheme = () => T;

const hexRgb = (h) => { const n = parseInt(h.replace('#', ''), 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255]; };
const rgbHex = ([r, g, b]) => '#' + [r, g, b].map(v => Math.round(Math.max(0, Math.min(255, v))).toString(16).padStart(2, '0')).join('');
const shade = (hex, amt) => rgbHex(hexRgb(hex).map(v => amt >= 0 ? v + (255 - v) * amt : v * (1 + amt)));
const luminance = (hex) => { const [r, g, b] = hexRgb(hex).map(v => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }); return .2126 * r + .7152 * g + .0722 * b; };

export function applyTheme() {
  const st = document.documentElement.style, a = /^#[0-9a-f]{6}$/i.test(T.accent) ? T.accent : DEFAULT.accent, bg = BACKGROUNDS[T.bg] || BACKGROUNDS.grafite;
  st.setProperty('--accent', a);
  st.setProperty('--accent-rgb', hexRgb(a).join(','));
  st.setProperty('--accent-hi', shade(a, .35));
  st.setProperty('--accent-lo', shade(a, -.14));
  st.setProperty('--accent-ink', luminance(a) > .35 ? '#10140a' : '#ffffff');      // testo leggibile sopra il colore
  for (const k of ['bg', 'card', 'card2', 'line']) st.setProperty('--' + k, bg[k]);
  document.querySelector('meta[name=theme-color]')?.setAttribute('content', bg.bg);
}
export function setTheme(patch) {
  T = { ...T, ...patch };
  try { localStorage.setItem(KEY, JSON.stringify(T)); } catch {}
  applyTheme();
}
