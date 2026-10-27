// Genera i suoni dei temi come file WAV (16 bit, mono, 22050 Hz).
// Sono creati da zero da questo script, quindi senza problemi di diritti.
// Uso:  node scripts/make-sounds.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RATE = 22050;
const OUT = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'sounds');
mkdirSync(OUT, { recursive: true });

const buffer = (seconds) => new Float32Array(Math.ceil(seconds * RATE));
const expDecay = (t, dur) => Math.exp((-6 * t) / dur); // ~0 alla fine della durata

// onda quadra (8 bit)
function square(buf, at, dur, freq, vol) {
  const start = Math.floor(at * RATE);
  const n = Math.floor(dur * RATE);
  for (let i = 0; i < n && start + i < buf.length; i++) {
    const t = i / RATE;
    const env = i < 40 ? i / 40 : expDecay(t, dur) + 0.0; // piccolo attacco anti-click
    buf[start + i] += (Math.sin(2 * Math.PI * freq * t) >= 0 ? 1 : -1) * vol * env;
  }
}

// seno con glissando di frequenza (cassa)
function sweep(buf, at, dur, f0, f1, vol) {
  const start = Math.floor(at * RATE);
  const n = Math.floor(dur * RATE);
  let phase = 0;
  for (let i = 0; i < n && start + i < buf.length; i++) {
    const t = i / n;
    const f = f0 * Math.pow(f1 / f0, t);
    phase += (2 * Math.PI * f) / RATE;
    buf[start + i] += Math.sin(phase) * vol * expDecay(i / RATE, dur);
  }
}

// rumore filtrato con passa-basso che si apre/chiude (swoosh / soffio)
function whoosh(buf, at, dur, lo, hi, vol, bright = false) {
  const start = Math.floor(at * RATE);
  const n = Math.floor(dur * RATE);
  let y = 0;
  let prev = 0;
  for (let i = 0; i < n && start + i < buf.length; i++) {
    const t = i / n;
    const cutoff = lo * Math.pow(hi / lo, t);
    const a = 1 - Math.exp((-2 * Math.PI * cutoff) / RATE);
    const x = Math.random() * 2 - 1;
    y += a * (x - y);
    const sample = bright ? y - prev * 0 : y;
    prev = y;
    const env = Math.sin(Math.PI * t) ** 1.5; // sale e scende
    buf[start + i] += sample * vol * env * 3;
  }
}

// colpetto di rumore acuto (hi-hat)
function tick(buf, at, dur, vol) {
  const start = Math.floor(at * RATE);
  const n = Math.floor(dur * RATE);
  let prev = 0;
  for (let i = 0; i < n && start + i < buf.length; i++) {
    const x = Math.random() * 2 - 1;
    buf[start + i] += (x - prev) * vol * expDecay(i / RATE, dur);
    prev = x;
  }
}

function writeWav(name, buf) {
  let peak = 0;
  for (const v of buf) peak = Math.max(peak, Math.abs(v));
  const gain = peak > 0.9 ? 0.9 / peak : 1;
  const data = Buffer.alloc(buf.length * 2);
  buf.forEach((v, i) => data.writeInt16LE(Math.max(-1, Math.min(1, v * gain)) * 32767, i * 2));
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + data.length, 4);
  header.write('WAVEfmt ', 8);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20); // PCM
  header.writeUInt16LE(1, 22); // mono
  header.writeUInt32LE(RATE, 24);
  header.writeUInt32LE(RATE * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(data.length, 40);
  writeFileSync(join(OUT, name), Buffer.concat([header, data]));
  console.log(name, `${(buf.length / RATE).toFixed(2)}s`, `${((44 + data.length) / 1024).toFixed(0)} KB`);
}

// Arcade: scala di beep a 8 bit che sale + tintinnio finale
{
  const b = buffer(1.3);
  for (let k = 0; k < 18; k++) square(b, k * 0.055, 0.05, 220 * Math.pow(2, k / 6), 0.3);
  square(b, 1.02, 0.14, 1568, 0.3);
  writeWav('arcade.wav', b);
}

// Studio: cinque colpi di cassa a ritmo + colpetti di hi-hat
{
  const b = buffer(1.1);
  [0, 0.2, 0.4, 0.6, 0.8].forEach((t) => sweep(b, t, 0.22, 110, 45, 0.9));
  [0.1, 0.3, 0.5, 0.7, 0.9].forEach((t) => tick(b, t, 0.05, 0.25));
  writeWav('studio.wav', b);
}

// Atelier: pennellata, rumore morbido che si apre e un glissando leggero
{
  const b = buffer(1.15);
  whoosh(b, 0, 1.05, 350, 2200, 0.35);
  sweep(b, 0.1, 0.6, 300, 520, 0.12);
  writeWav('atelier.wav', b);
}

// Soft: soffio d'aria per i temi normali
{
  const b = buffer(0.7);
  whoosh(b, 0, 0.65, 300, 1400, 0.25);
  writeWav('soft.wav', b);
}
