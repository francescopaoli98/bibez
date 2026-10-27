// Prova del parser del quick add. Esegui con:  node src/lib/quickAdd.test.mjs
import assert from 'node:assert/strict';
import { parseQuickAdd } from './quickAdd.ts';

// Martedì 27 ottobre 2026, ore 10:00
const NOW = new Date(2026, 9, 27, 10, 0);
const PROJECTS = [
  { id: 'p1', name: 'Lavoro' },
  { id: 'p2', name: 'Doppiaggio' },
  { id: 'p3', name: 'Casa' },
];
const at = (y, mo, d, h, mi) => new Date(y, mo - 1, d, h ?? 0, mi ?? 0).getTime();
const run = (s) => parseQuickAdd(s, PROJECTS, NOW);

const cases = [
  ['Chiama Marco domani alle 15 #lavoro !importante', {
    title: 'Chiama Marco', dueAt: at(2026, 10, 28, 15), hasTime: true, important: true, project: 'p1', remindMinutes: 10,
  }],
  ['Comprare il latte', { title: 'Comprare il latte', dueAt: null, hasTime: false, important: false, project: null, remindMinutes: null }],
  ['Dentista lunedì alle 9:30', { title: 'Dentista', dueAt: at(2026, 11, 2, 9, 30), hasTime: true }],
  ['Palestra stasera', { title: 'Palestra', dueAt: at(2026, 10, 27, 20), hasTime: true }],
  ['Rispondere a Giulia tra 2 ore', { title: 'Rispondere a Giulia', dueAt: at(2026, 10, 27, 12), hasTime: true }],
  ['Pagare affitto il 5 novembre', { title: 'Pagare affitto', dueAt: at(2026, 11, 5), hasTime: false, remindMinutes: null }],
  ['Studiare copione alle 18', { title: 'Studiare copione', dueAt: at(2026, 10, 27, 18), hasTime: true }],
  ['Chiamare mamma alle 9', { title: 'Chiamare mamma', dueAt: at(2026, 10, 28, 9), hasTime: true }],
  ['domani', { title: 'domani', dueAt: null, hasTime: false }],
  ['Riunione 27/11 alle 14.30', { title: 'Riunione', dueAt: at(2026, 11, 27, 14, 30), hasTime: true }],
  ['Spesa dopodomani', { title: 'Spesa', dueAt: at(2026, 10, 29), hasTime: false }],
  ['Provino #dopp', { title: 'Provino', project: 'p2', dueAt: null }],
  ['Rinnovare passaporto !', { title: 'Rinnovare passaporto', important: true }],
  ['Cena venerdì alle 8 di sera', { title: 'Cena', dueAt: at(2026, 10, 30, 20), hasTime: true }],
  ['Pranzo domani pomeriggio', { title: 'Pranzo', dueAt: at(2026, 10, 28, 15), hasTime: true }],
  ['Chiamare tra 3 giorni', { title: 'Chiamare', dueAt: at(2026, 10, 30), hasTime: false }],
  ['Leggere capitolo 15', { title: 'Leggere capitolo 15', dueAt: null }],
  ['Tasse #inesistente', { title: 'Tasse #inesistente', project: null }],
  ['Pagare bolletta il 3', { title: 'Pagare bolletta', dueAt: at(2026, 11, 3) }],
  ['Compleanno Anna 15 gennaio', { title: 'Compleanno Anna', dueAt: at(2027, 1, 15) }],
];

let failed = 0;
for (const [input, want] of cases) {
  const got = run(input);
  const flat = { ...got, project: got.project ? got.project.id : null };
  try {
    for (const key of Object.keys(want)) assert.equal(flat[key], want[key], `${key}`);
    console.log('ok  ', input);
  } catch (e) {
    failed++;
    console.log('FAIL', input, '\n     ', e.message, '\n      ottenuto:', JSON.stringify(flat));
  }
}
console.log(failed ? `\n${failed} test falliti` : '\nTutti i test passati');
process.exit(failed ? 1 : 0);
