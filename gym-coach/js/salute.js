// Dati sulla salute (restano sul telefono, cifrati): servono al coach per essere prudente. Non sono consigli medici.
export const CONDIZIONI = [
  ['pressione', 'Pressione alta'], ['cuore', 'Problemi al cuore'], ['diabete', 'Diabete'], ['schiena', 'Mal di schiena / ernia'],
  ['articolazioni', 'Dolori a ginocchia o spalle'], ['asma', 'Asma o problemi respiratori'], ['gravidanza', 'Gravidanza o allattamento'], ['altro', 'Altro'],
];
export const label = (k) => CONDIZIONI.find(c => c[0] === k)?.[1] || k;

// C'è qualcosa da segnalare? (condizioni, altro, farmaci)
export const hasAny = (s) => !!(s && ((s.condizioni || []).length || s.farmaci || (s.altro || '').trim()));

export function summary(s) {
  if (!hasAny(s)) return 'Nessun problema indicato';
  const parts = (s.condizioni || []).filter(k => k !== 'altro').map(k => label(k).toLowerCase());
  if ((s.condizioni || []).includes('altro') || (s.altro || '').trim()) parts.push((s.altro || '').trim() || 'altro');
  if (s.farmaci) parts.push('assume farmaci' + (s.farmaciNote ? ` (${s.farmaciNote})` : ''));
  return parts.join(', ');
}

// Rimpiazzi più dolci per chi ha schiena o articolazioni delicate (la scheda base, anche senza IA)
const RISK = {
  schiena: { Romanian_Deadlift: 'Butt_Lift_Bridge', Barbell_Deadlift: 'Butt_Lift_Bridge', Bent_Over_Barbell_Row: 'Seated_Cable_Rows', Barbell_Squat: 'Leg_Press', Hyperextensions_Back_Extensions: 'Plank', Stiff_Legged_Dumbbell_Deadlift: 'Butt_Lift_Bridge' },
  articolazioni: { Dumbbell_Lunges: 'Leg_Press', Dumbbell_Rear_Lunge: 'Leg_Press', Barbell_Squat: 'Leg_Press', Hack_Squat: 'Leg_Press', Dumbbell_Shoulder_Press: 'Side_Lateral_Raise', Barbell_Shoulder_Press: 'Side_Lateral_Raise', Machine_Shoulder_Military_Press: 'Side_Lateral_Raise', Pullups: 'Wide-Grip_Lat_Pulldown', 'Chin-Up': 'Close-Grip_Front_Lat_Pulldown' },
};
export function adjustPlan(plan, s) {
  const conds = (s?.condizioni || []).filter(k => RISK[k]);
  if (!conds.length) return plan;
  const out = JSON.parse(JSON.stringify(plan));
  for (const day of out.giorni) {
    for (let i = 0; i < day.esercizi.length; i++) {
      for (const k of conds) {
        const to = RISK[k][day.esercizi[i].id];
        if (!to) continue;
        if (day.esercizi.some(e => e.id === to)) { if (day.esercizi.length > 4) { day.esercizi.splice(i, 1); i--; } }
        else day.esercizi[i] = { ...day.esercizi[i], id: to };
        break;
      }
    }
  }
  out.adattata = true;
  return out;
}

// Frasi per il coach (prompt)
export function coachLine(s) {
  if (!hasAny(s)) return 'SALUTE DICHIARATA: nessun problema indicato.';
  return `SALUTE DICHIARATA (riservata): ${summary(s)}. ${s.medico ? 'Ha detto che ne parlerà con il medico.' : ''}
Regole di prudenza: non sei un medico, non fare diagnosi e non dare consigli su farmaci o cure (rimanda al medico). Scegli esercizi dolci, niente carichi massimali né apnea a fine sforzo se ci sono pressione alta o problemi al cuore. In gravidanza evita esercizi sdraiati sulla schiena e addominali intensi. Se compaiono dolore al petto, vertigini, fiato corto insolito o dolore acuto, di' di fermarsi subito e sentire il medico.`;
}
