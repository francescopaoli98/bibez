const GIORNI = ['domenica', 'lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato'];
const MESI = [
  'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
  'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
];

export function startOfDay(d: Date = new Date()): number {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x.getTime();
}

export function startOfNextDay(d: Date = new Date()): number {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  x.setDate(x.getDate() + 1);
  return x.getTime();
}

// es. "martedì 27 ottobre"
export function longDate(d: Date = new Date()): string {
  return `${GIORNI[d.getDay()]} ${d.getDate()} ${MESI[d.getMonth()]}`;
}

// es. "MAR 27 OTT" (per i temi che scrivono in maiuscolo)
export function shortDate(d: Date = new Date()): string {
  return `${GIORNI[d.getDay()].slice(0, 3)} ${d.getDate()} ${MESI[d.getMonth()].slice(0, 3)}`.toUpperCase();
}

// "Oggi", "Domani", "Venerdì" (entro la settimana) oppure "5 nov" / "15 gen 2027"
export function dayLabel(ms: number, now: Date = new Date()): string {
  const days = Math.round((startOfDay(new Date(ms)) - startOfDay(now)) / 86400000);
  if (days === 0) return 'Oggi';
  if (days === 1) return 'Domani';
  const d = new Date(ms);
  if (days > 1 && days < 7) {
    const name = GIORNI[d.getDay()];
    return name.charAt(0).toUpperCase() + name.slice(1);
  }
  const short = `${d.getDate()} ${MESI[d.getMonth()].slice(0, 3)}`;
  return d.getFullYear() === now.getFullYear() ? short : `${short} ${d.getFullYear()}`;
}

// es. "Domani · 15:00" oppure solo "Domani" se non c'è l'ora
export function dueLabel(ms: number, hasTime: boolean, now: Date = new Date()): string {
  return hasTime ? `${dayLabel(ms, now)} · ${clock(ms)}` : dayLabel(ms, now);
}

// es. "15:00"
export function clock(ms: number): string {
  const d = new Date(ms);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}
