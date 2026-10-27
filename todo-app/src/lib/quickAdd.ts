// Quick add: da una frase come "Chiama Marco domani alle 15 #lavoro !importante"
// ricava titolo, data/ora, lista e importanza. Funzione pura, senza dipendenze.

export interface ProjectRef {
  id: string;
  name: string;
  color?: string;
}

export interface QuickAddResult {
  title: string;
  dueAt: number | null; // null = nessuna data scritta
  hasTime: boolean;
  important: boolean;
  project: ProjectRef | null;
  remindMinutes: number | null;
}

// Toglie gli accenti mantenendo la lunghezza (serve per tenere gli indici allineati al testo originale)
const ACCENTS: Record<string, string> = { à: 'a', è: 'e', é: 'e', ì: 'i', í: 'i', ò: 'o', ó: 'o', ù: 'u', ú: 'u', '’': "'" };
const fold = (s: string) => s.toLowerCase().replace(/[àèéìíòóùú’]/g, (c) => ACCENTS[c]);

const WEEKDAYS = ['domenica', 'lunedi', 'martedi', 'mercoledi', 'giovedi', 'venerdi', 'sabato'];
const MONTHS = [
  ['gennaio', 'gen'], ['febbraio', 'feb'], ['marzo', 'mar'], ['aprile', 'apr'],
  ['maggio', 'mag'], ['giugno', 'giu'], ['luglio', 'lug'], ['agosto', 'ago'],
  ['settembre', 'set'], ['ottobre', 'ott'], ['novembre', 'nov'], ['dicembre', 'dic'],
];
const MONTH_RE = MONTHS.map((m) => `${m[0]}|${m[1]}`).join('|');
const NUMBER_WORDS: Record<string, number> = {
  un: 1, uno: 1, una: 1, due: 2, tre: 3, quattro: 4, cinque: 5, sei: 6, sette: 7, otto: 8, nove: 9, dieci: 10,
};
const DAYPART_HOUR: Record<string, number> = { mattina: 9, mattino: 9, pomeriggio: 15, sera: 20 };

const addDays = (d: Date, n: number) => {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
};
const midnight = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

// Prossima occorrenza futura di una data "giorno/mese" (se già passata, anno dopo)
function nextDayMonth(now: Date, day: number, month: number, year?: number): Date | null {
  const make = (y: number) => {
    const d = new Date(y, month, day);
    return d.getMonth() === month && d.getDate() === day ? d : null; // scarta es. 31 aprile
  };
  if (year !== undefined) return make(year);
  const today = midnight(now);
  const thisYear = make(now.getFullYear());
  if (thisYear && thisYear >= today) return thisYear;
  return make(now.getFullYear() + 1);
}

// Parole di collegamento rimaste appese a inizio/fine titolo dopo aver tolto data e ora
const DANGLING = /(?:^|\s)(?:il|lo|la|alle|ore|per|entro|di|a|ad|da|del|nel|in|e)$/i;
const LEADING = /^(?:il|alle|ore|entro)\s+/i;

export function parseQuickAdd(input: string, projects: ProjectRef[], now: Date = new Date()): QuickAddResult {
  const raw = input;
  let work = fold(raw);
  const used: boolean[] = new Array(raw.length).fill(false);

  const find = (re: RegExp) => re.exec(work);
  const consume = (m: RegExpExecArray) => {
    const start = m.index;
    const end = start + m[0].length;
    for (let i = start; i < end; i++) used[i] = true;
    work = work.slice(0, start) + ' '.repeat(end - start) + work.slice(end);
  };

  // ---- importante: "!" oppure "!importante" / "!alta" / "!urgente"
  let important = false;
  const imp = find(/(?:^|\s)!(?:importante|alta|urgente|imp)?(?=\s|$)/);
  if (imp) {
    important = true;
    consume(imp);
  }

  // ---- lista: "#lavoro" (anche solo l'inizio del nome: "#dopp")
  let project: ProjectRef | null = null;
  const tagRe = /(?:^|\s)#([a-z0-9]+)(?=\s|$)/g;
  let tag: RegExpExecArray | null;
  while ((tag = tagRe.exec(work)) !== null) {
    const wanted = tag[1];
    const hit =
      projects.find((p) => fold(p.name) === wanted) ??
      projects.find((p) => fold(p.name).startsWith(wanted));
    if (hit) {
      project = hit;
      consume(tag);
      break;
    }
  }

  // ---- data
  let date: Date | null = null; // giorno senza ora
  let relative: number | null = null; // istante assoluto per "tra 2 ore"

  const rel = find(
    /\b(?:tra|fra)\s+(?:(\d+|due|tre|quattro|cinque|sei|sette|otto|nove|dieci|un|una)\s+(minuti|minuto|min|ore|ora|giorni|giorno|settimane|settimana|mesi|mese)|(un'ora|mezz'ora))\b/,
  );
  if (rel) {
    consume(rel);
    let mins = 0;
    if (rel[3]) {
      mins = rel[3] === 'mezz\'ora' ? 30 : 60;
    } else {
      const n = /^\d+$/.test(rel[1]) ? Number(rel[1]) : NUMBER_WORDS[rel[1]];
      const unit = rel[2];
      if (unit.startsWith('min')) mins = n;
      else if (unit.startsWith('or')) mins = n * 60;
      else if (unit.startsWith('giorn')) mins = n * 60 * 24;
      else if (unit.startsWith('settiman')) mins = n * 60 * 24 * 7;
      else mins = n * 60 * 24 * 30;
    }
    const at = new Date(now.getTime() + mins * 60000);
    at.setSeconds(0, 0);
    // per giorni/settimane/mesi basta il giorno, non l'ora
    if (mins >= 60 * 24) date = midnight(at);
    else relative = at.getTime();
  }

  if (!date && relative === null) {
    const md = find(new RegExp(`\\b(?:il\\s+)?(\\d{1,2})\\s+(${MONTH_RE})\\b(?:\\s+(\\d{4}))?`));
    if (md) {
      const monthIdx = MONTHS.findIndex((m) => m[0] === md[2] || m[1] === md[2]);
      const d = nextDayMonth(now, Number(md[1]), monthIdx, md[3] ? Number(md[3]) : undefined);
      if (d) {
        date = d;
        consume(md);
      }
    }
  }

  if (!date && relative === null) {
    const nd = find(/\b(?:il\s+)?(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?\b/);
    if (nd) {
      let year: number | undefined;
      if (nd[3]) year = nd[3].length === 2 ? 2000 + Number(nd[3]) : Number(nd[3]);
      const d = nextDayMonth(now, Number(nd[1]), Number(nd[2]) - 1, year);
      if (d) {
        date = d;
        consume(nd);
      }
    }
  }

  if (!date && relative === null) {
    const wd = find(
      /\b(?:(?:il|di|questo|prossimo|prossima)\s+)?(lunedi|martedi|mercoledi|giovedi|venerdi|sabato|domenica)(?:\s+(?:prossimo|prossima))?\b/,
    );
    if (wd) {
      consume(wd);
      const target = WEEKDAYS.indexOf(wd[1]);
      let diff = (target - now.getDay() + 7) % 7;
      if (diff === 0) diff = 7; // "lunedì" detto di lunedì = lunedì prossimo
      date = addDays(midnight(now), diff);
    }
  }

  let eveningToday = false;
  if (!date && relative === null) {
    const w = find(/\b(dopodomani|domani|oggi|stasera)\b/);
    if (w) {
      consume(w);
      if (w[1] === 'dopodomani') date = addDays(midnight(now), 2);
      else if (w[1] === 'domani') date = addDays(midnight(now), 1);
      else date = midnight(now);
      if (w[1] === 'stasera') eveningToday = true;
    }
  }

  if (!date && relative === null) {
    const dom = find(/\bil\s+(\d{1,2})\b/);
    if (dom) {
      const day = Number(dom[1]);
      if (day >= 1 && day <= 31) {
        const thisMonth = new Date(now.getFullYear(), now.getMonth(), day);
        const valid = thisMonth.getMonth() === now.getMonth();
        const base = valid && day >= now.getDate() ? thisMonth : new Date(now.getFullYear(), now.getMonth() + 1, day);
        if (base.getDate() === day) {
          date = midnight(base);
          consume(dom);
        }
      }
    }
  }

  // ---- ora
  let hour: number | null = null;
  let minute = 0;
  if (relative === null) {
    const t1 = find(/\b(?:alle|ore|h)\s*(\d{1,2})(?:[:.h](\d{2}))?\b/);
    const t2 = find(/\b(\d{1,2}):(\d{2})\b/);
    const t = t1 ?? t2;
    if (t) {
      const h = Number(t[1]);
      const m = t[2] ? Number(t[2]) : 0;
      if (h <= 23 && m <= 59) {
        hour = h;
        minute = m;
        consume(t);
      }
    }
    if (hour === null) {
      const noon = find(/\bmezzogiorno\b/);
      if (noon) {
        hour = 12;
        consume(noon);
      }
    }
  }

  // ---- momento della giornata: "di sera", "pomeriggio"...
  let part: string | null = null;
  if (relative === null) {
    const p = find(/\b(?:(?:di|del|nel|la)\s+)?(mattina|mattino|pomeriggio|sera)\b/);
    if (p) {
      part = p[1];
      consume(p);
    }
  }
  if (eveningToday && !part) part = 'sera';

  if (hour !== null && part && (part === 'sera' || part === 'pomeriggio') && hour < 12) hour += 12;
  if (hour === null && part) hour = DAYPART_HOUR[part];

  // ---- data finale
  let dueAt: number | null = null;
  let hasTime = false;
  if (relative !== null) {
    dueAt = relative;
    hasTime = true;
  } else if (date && hour !== null) {
    dueAt = new Date(date.getFullYear(), date.getMonth(), date.getDate(), hour, minute).getTime();
    hasTime = true;
  } else if (date) {
    dueAt = date.getTime();
  } else if (hour !== null) {
    // solo l'ora: oggi se è ancora futura, altrimenti domani
    let at = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute);
    if (at.getTime() <= now.getTime()) at = addDays(at, 1);
    dueAt = at.getTime();
    hasTime = true;
  }

  // ---- titolo: quello che resta
  let title = '';
  for (let i = 0; i < raw.length; i++) if (!used[i]) title += raw[i];
  title = title.replace(/\s+/g, ' ').trim();
  for (let guard = 0; guard < 6; guard++) {
    const next = title.replace(DANGLING, '').replace(LEADING, '').replace(/[,;:\-–]+$/, '').trim();
    if (next === title) break;
    title = next;
  }

  // Se non resta nulla da chiamare "titolo", il testo scritto vale com'è
  if (!title) {
    return { title: raw.trim(), dueAt: null, hasTime: false, important: false, project: null, remindMinutes: null };
  }
  title = title.charAt(0).toUpperCase() + title.slice(1);

  return { title, dueAt, hasTime, important, project, remindMinutes: hasTime ? 10 : null };
}
