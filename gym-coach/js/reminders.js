// Promemoria allenamenti: file calendario (.ics) con eventi settimanali e avviso 15 minuti prima.
// Funziona su Google Calendar / Calendario iPhone senza server né notifiche push.
import { S, save } from './store.js';
import { h, toast } from './ui.js';

const NOMI = [['1', 'Lun'], ['2', 'Mar'], ['3', 'Mer'], ['4', 'Gio'], ['5', 'Ven'], ['6', 'Sab'], ['0', 'Dom']];
const BYDAY = { 0: 'SU', 1: 'MO', 2: 'TU', 3: 'WE', 4: 'TH', 5: 'FR', 6: 'SA' };
const DEFAULT = { 2: [1, 4], 3: [1, 3, 5], 4: [1, 2, 4, 5], 5: [1, 2, 3, 4, 5] };
const pad = (n) => String(n).padStart(2, '0');
const stamp = (d) => `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}`;

export function buildICS(days, time) {
  const [hh, mm] = time.split(':').map(Number);
  const now = new Date();
  const dtstamp = now.toISOString().replace(/[-:]/g, '').replace(/\.\d+/, '');
  const ev = days.map(wd => {
    const d = new Date(now); d.setHours(0, 0, 0, 0);
    while (d.getDay() !== wd || (d.getTime() === new Date(now).setHours(0, 0, 0, 0) && (hh * 60 + mm) <= now.getHours() * 60 + now.getMinutes())) d.setDate(d.getDate() + 1);
    return ['BEGIN:VEVENT', `UID:gymcoach-${wd}-${time.replace(':', '')}@gym-coach`, `DTSTAMP:${dtstamp}`,
      `DTSTART:${stamp(d)}T${pad(hh)}${pad(mm)}00`, 'DURATION:PT1H', `RRULE:FREQ=WEEKLY;BYDAY=${BYDAY[wd]}`,
      'SUMMARY:Allenamento 💪 (Gym Coach)', 'DESCRIPTION:Apri Gym Coach e inizia l\'allenamento di oggi.',
      'BEGIN:VALARM', 'TRIGGER:-PT15M', 'ACTION:DISPLAY', 'DESCRIPTION:Tra 15 minuti: allenamento', 'END:VALARM', 'END:VEVENT'].join('\r\n');
  });
  return ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//Gym Coach//IT', 'CALSCALE:GREGORIAN', ...ev, 'END:VCALENDAR'].join('\r\n');
}

export function remindersCard() {
  const r = S.reminder || { days: DEFAULT[S.profile?.giorni] || [1, 3, 5], time: '18:00' };
  const chips = h('div', { class: 'chips' });
  const drawChips = () => chips.replaceChildren(...NOMI.map(([v, t]) =>
    h('button', { class: 'chip lg' + (r.days.includes(+v) ? ' on' : ''), onclick: () => {
      r.days = r.days.includes(+v) ? r.days.filter(x => x !== +v) : [...r.days, +v]; S.reminder = r; save(); drawChips(); } }, t)));
  drawChips();
  const time = h('input', { type: 'time', value: r.time, onchange: e => { r.time = e.target.value || '18:00'; S.reminder = r; save(); } });
  return h('div', { class: 'card stack' }, h('h2', {}, 'Promemoria allenamenti'),
    h('p', { class: 'muted small' }, 'Scegli giorni e ora: scarichi un file che aggiunge al calendario del telefono un evento settimanale, con avviso 15 minuti prima.'),
    chips, h('label', { class: 'field' }, 'Ora', time),
    h('button', { class: 'btn block', onclick: () => {
      if (!r.days.length) return toast('Scegli almeno un giorno');
      S.reminder = r; save();
      const url = URL.createObjectURL(new Blob([buildICS(r.days, r.time)], { type: 'text/calendar' }));
      const a = h('a', { href: url, download: 'gym-coach-promemoria.ics' }); document.body.append(a); a.click(); a.remove();
      toast('File scaricato: aprilo per aggiungerlo al calendario');
    } }, 'Aggiungi al calendario'));
}
