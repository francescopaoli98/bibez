// Fabbisogno giornaliero indicativo: Mifflin-St Jeor + livello di attività + obiettivo.
const ATTIVITA = { 2: 1.4, 3: 1.45, 4: 1.5, 5: 1.55 };        // in base ai giorni di allenamento
const DELTA = { misto: -250, massa: 250, dimagrire: -400, tonificare: -200 };   // kcal rispetto al mantenimento
const PROT = { misto: 2.0, massa: 2.0, dimagrire: 2.0, tonificare: 1.8 };      // g per kg di peso

export function targets(p) {
  if (!p || !(p.peso > 0) || !(p.altezza > 0) || !(p.eta > 0) || !p.sesso) return null;
  const bmr = 10 * p.peso + 6.25 * p.altezza - 5 * p.eta + (p.sesso === 'uomo' ? 5 : -161);
  const tdee = bmr * (ATTIVITA[p.giorni] || 1.45);
  const min = p.sesso === 'uomo' ? 1500 : 1200;
  const kcal = Math.round(Math.max(min, bmr, tdee + (DELTA[p.obiettivo] ?? -250)) / 10) * 10;
  const prot = Math.round(p.peso * (PROT[p.obiettivo] || 2));
  const fat = Math.round(p.peso * 0.8);
  const carb = Math.max(0, Math.round((kcal - prot * 4 - fat * 9) / 4));
  return { kcal, prot, carb, fat, mantenimento: Math.round(tdee / 10) * 10 };
}
