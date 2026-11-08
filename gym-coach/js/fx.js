// Effetti visivi: numeri che salgono, coriandoli.
const reduce = () => window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

export function countUps(root) {
  if (reduce()) return;
  root.querySelectorAll('.stat b').forEach(el => {
    const m = /^(\d+(?:[.,]\d+)?)(.*)$/.exec(el.textContent.trim());
    if (!m) return;
    const end = parseFloat(m[1].replace(',', '.')), dec = (m[1].split(/[.,]/)[1] || '').length, suffix = m[2], t0 = performance.now(), dur = 700;
    const step = (t) => {
      const k = Math.min(1, (t - t0) / dur), v = end * (1 - (1 - k) ** 3);
      el.textContent = (dec ? v.toFixed(dec) : Math.round(v)) + suffix;
      if (k < 1) requestAnimationFrame(step);
    };
    el.textContent = '0' + suffix; requestAnimationFrame(step);
  });
}

export function confetti() {
  if (reduce()) return;
  const box = document.createElement('div'); box.className = 'confetti';
  const cols = ['var(--accent)', 'var(--accent-hi)', '#ffffff', 'var(--accent-lo)'];
  for (let i = 0; i < 44; i++) {
    const s = document.createElement('i');
    s.style.cssText = `--x:${(Math.random() - .5) * 120}vw;--y:${-30 - Math.random() * 50}vh;--r:${Math.random() * 900 - 450}deg;--d:${1.1 + Math.random() * .9}s;left:${35 + Math.random() * 30}%;background:${cols[i % cols.length]};animation-delay:${Math.random() * .15}s`;
    box.append(s);
  }
  document.body.append(box); setTimeout(() => box.remove(), 2400);
}
