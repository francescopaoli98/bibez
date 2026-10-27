import { Skia, type SkPath } from '@shopify/react-native-skia';
import type { Fx } from './themes';

// Geometria delle onde: dato l'avanzamento p (0..1) restituisce
//   reveal = zona dove si vede già il tema nuovo
//   rim    = la stessa zona, un po' più grande, colorata come bordo dell'onda
// Le forme "crescono" con p: quadratini, macchie di colore, barre da equalizzatore...

export type Direction = 'ltr' | 'rtl';

export interface WaveSeed {
  cols: number;
  rows: number;
  org: number[];
  px: number[];
  pt: { sx: number; sy: number; a: number; b: number }[];
  br: number[];
}

const CELL = 20;
const ROW_STEP = 14;
const BARS = 30;
const BLOBS = 90;

// Numeri casuali scelti una volta per transizione, così le forme non "tremano" tra un frame e l'altro
export function makeSeed(width: number, height: number): WaveSeed {
  const r = Math.random;
  const cols = Math.ceil(width / CELL);
  const rows = Math.ceil(height / CELL);
  const org: number[] = [];
  let v = 0;
  for (let k = 0; k < Math.ceil(height / ROW_STEP) + 3; k++) {
    v = v * 0.55 + (r() * 2 - 1) * 0.9;
    org.push(Math.max(-1, Math.min(1, v)));
  }
  const px: number[] = [];
  for (let k = 0; k < cols * rows; k++) px.push(r());
  const pt = [];
  for (let k = 0; k < BLOBS; k++) pt.push({ sx: r(), sy: r(), a: r(), b: r() });
  const br: number[] = [];
  for (let k = 0; k < BARS; k++) br.push(r());
  return { cols, rows, org, px, pt, br };
}

const clamp = (x: number, a: number, b: number) => Math.max(a, Math.min(b, x));
const ease = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

export function buildWave(
  fx: Fx,
  p: number,
  dir: Direction,
  seed: WaveSeed,
  W: number,
  H: number,
): { reveal: SkPath; rim: SkPath } {
  const ltr = dir === 'ltr';
  const reveal = Skia.PathBuilder.Make();
  const rim = Skia.PathBuilder.Make();
  const rect = (b: typeof reveal, x: number, y: number, w: number, h: number) => {
    b.addRect(Skia.XYWHRect(x, y, w, h));
  };

  if (fx === 'bar' || fx === 'wave' || fx === 'organic') {
    // fronte che avanza: dritto (bar), ondulato (wave) o irregolare (organic)
    const e = ease(p);
    const A = fx === 'bar' ? 0 : fx === 'wave' ? 26 : 24;
    const front = (y: number, k: number, extra: number) => {
      let w = 0;
      if (fx === 'wave') w = A * Math.sin((y / H) * Math.PI * 5 + e * 7);
      if (fx === 'organic') w = A * (seed.org[k] ?? 0);
      const x = e * (W + 2 * A + 16) - A - 8 + w + extra;
      return ltr ? x : W - x;
    };
    const poly = (b: typeof reveal, extra: number) => {
      b.moveTo(ltr ? 0 : W, -2);
      for (let k = 0, y = 0; y <= H + ROW_STEP; k++, y += ROW_STEP) b.lineTo(front(y, k, extra), y);
      b.lineTo(ltr ? 0 : W, H + 2);
      b.close();
    };
    poly(reveal, 0);
    poly(rim, 8 * Math.sin(p * Math.PI));
    return { reveal: reveal.build(), rim: rim.build() };
  }

  if (fx === 'pixel') {
    // quadratini che nascono piccoli, crescono a scatti e si mangiano i vicini
    const q = -0.1 + p * 1.25;
    const { cols, rows } = seed;
    for (let i = 0; i < cols; i++) {
      const nx = ltr ? i / (cols - 1) : 1 - i / (cols - 1);
      for (let j = 0; j < rows; j++) {
        const ny = j / (rows - 1);
        const start = 0.5 * nx + 0.1 * Math.sin(ny * Math.PI * 3.2 + 1) + seed.px[i * rows + j] * 0.32;
        const g = clamp((q - start) / 0.22, 0, 1);
        const gq = g > 0 ? Math.ceil(g * 5) / 5 : 0;
        const g2 = clamp((q - start + 0.2) / 0.22, 0, 1);
        const gq2 = g2 > 0 ? Math.ceil(g2 * 5) / 5 : 0;
        const cx = i * CELL + CELL / 2;
        const cy = j * CELL + CELL / 2;
        if (gq > 0) {
          const s = gq * CELL * 1.6;
          rect(reveal, cx - s / 2, cy - s / 2, s, s);
        }
        if (gq2 > 0 && gq < 1) {
          const s2 = gq2 * CELL * 1.6 + 5;
          rect(rim, cx - s2 / 2, cy - s2 / 2, s2, s2);
        }
      }
    }
    return { reveal: reveal.build(), rim: rim.build() };
  }

  if (fx === 'paint') {
    // macchie di colore che nascono da punti sparsi, si allargano e si fondono
    const q = p * 1.3;
    const k = W / 390;
    for (const s of seed.pt) {
      const sx = ltr ? s.sx : 1 - s.sx;
      const start = 0.5 * sx + 0.12 * Math.sin(s.sy * Math.PI * 2.4) + s.a * 0.18;
      const t = clamp((q - start) / 0.45, 0, 1);
      const r = (1 - Math.pow(1 - t, 3)) * (100 + s.b * 90) * k;
      if (r > 0.5) {
        reveal.addCircle(s.sx * W, s.sy * H, r);
        rim.addCircle(s.sx * W, s.sy * H, r * 1.14 + 4);
      }
    }
    if (p > 0.985) rect(reveal, 0, 0, W, H);
    return { reveal: reveal.build(), rim: rim.build() };
  }

  // 'bars': barre da equalizzatore che si alzano dal centro
  const bw = W / BARS;
  const q = p * 1.1;
  for (let i = 0; i < BARS; i++) {
    const nx = ltr ? i / (BARS - 1) : 1 - i / (BARS - 1);
    const start = 0.55 * nx + seed.br[i] * 0.2;
    const g = clamp((q - start) / 0.32, 0, 1);
    if (g <= 0) continue;
    const jit = 0.78 + 0.22 * Math.abs(Math.sin(i * 1.7 + p * 30));
    const ht = H * (1 - Math.pow(1 - g, 3)) * (1 - (1 - jit) * (1 - g));
    const ht2 = Math.min(H + 4, ht + 44);
    rect(reveal, i * bw - 0.5, (H - ht) / 2, bw + 1, ht);
    rect(rim, i * bw - 0.5, (H - ht2) / 2, bw + 1, ht2);
  }
  return { reveal: reveal.build(), rim: rim.build() };
}
