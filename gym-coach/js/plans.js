// Generazione scheda: IA (Gemini) con fallback su schede pronte.
import { gemini } from './ai.js';
import { summary, hasAny } from './salute.js';

const REPS = {
  massa:    { reps: '8-12',  rest: 90, sets: 3 },
  dimagrire:{ reps: '12-15', rest: 60, sets: 3 },
  tonificare:{ reps: '10-15', rest: 60, sets: 3 },
  misto:    { reps: '10-12', rest: 75, sets: 3 },
};

// giorni = lista di esercizi (id). Sostituzione principiante/avanzato fatta in tpl()
const DAYS = {
  fbA: ['LEG', 'Dumbbell_Bench_Press', 'Wide-Grip_Lat_Pulldown', 'Dumbbell_Shoulder_Press', 'Triceps_Pushdown', 'Plank'],
  fbB: ['Romanian_Deadlift', 'Incline_Dumbbell_Press', 'Seated_Cable_Rows', 'Side_Lateral_Raise', 'Dumbbell_Bicep_Curl', 'Crunches'],
  fbC: ['Hack_Squat', 'Butterfly', 'One-Arm_Dumbbell_Row', 'Face_Pull', 'Hammer_Curls', 'Seated_Leg_Curl'],
  upA: ['Dumbbell_Bench_Press', 'Wide-Grip_Lat_Pulldown', 'Dumbbell_Shoulder_Press', 'Seated_Cable_Rows', 'Triceps_Pushdown', 'Dumbbell_Bicep_Curl'],
  loA: ['LEG', 'Romanian_Deadlift', 'Leg_Extensions', 'Lying_Leg_Curls', 'Standing_Calf_Raises', 'Plank'],
  upB: ['Incline_Dumbbell_Press', 'One-Arm_Dumbbell_Row', 'Side_Lateral_Raise', 'Close-Grip_Front_Lat_Pulldown', 'Face_Pull', 'Hammer_Curls'],
  loB: ['Hack_Squat', 'Barbell_Hip_Thrust', 'Seated_Leg_Curl', 'Dumbbell_Lunges', 'Seated_Calf_Raise', 'Cable_Crunch'],
  push: ['Dumbbell_Bench_Press', 'Incline_Dumbbell_Press', 'Dumbbell_Shoulder_Press', 'Side_Lateral_Raise', 'Triceps_Pushdown', 'Triceps_Pushdown_-_Rope_Attachment'],
  pull: ['Wide-Grip_Lat_Pulldown', 'Seated_Cable_Rows', 'One-Arm_Dumbbell_Row', 'Face_Pull', 'Dumbbell_Bicep_Curl', 'Hammer_Curls'],
  legs: ['LEG', 'Romanian_Deadlift', 'Leg_Extensions', 'Lying_Leg_Curls', 'Standing_Calf_Raises', 'Cable_Crunch'],
};
const PLANS = {
  2: [['Full body A', 'fbA'], ['Full body B', 'fbB']],
  3: [['Full body A', 'fbA'], ['Full body B', 'fbB'], ['Full body C', 'fbC']],
  4: [['Parte alta A', 'upA'], ['Gambe A', 'loA'], ['Parte alta B', 'upB'], ['Gambe B', 'loB']],
  5: [['Push', 'push'], ['Pull', 'pull'], ['Gambe', 'legs'], ['Parte alta', 'upB'], ['Gambe B', 'loB']],
};

const SPECIAL = { Plank: ['30-45 sec', 3], Elliptical_Trainer: ['10-15 min', 1], Hanging_Leg_Raise: ['8-12', 3] };

export function templatePlan(profile) {
  const g = REPS[profile.obiettivo] || REPS.misto;
  const days = PLANS[profile.giorni] || PLANS[3];
  const adv = profile.livello === 'intermedio';
  return {
    nome: `Scheda ${days.length} giorni`,
    fonte: 'template',
    giorni: days.map(([nome, key]) => {
      const ex = DAYS[key].map((id, i) => {
        if (id === 'LEG') id = adv ? 'Barbell_Squat' : 'Leg_Press';
        const sp = SPECIAL[id];
        return { id, serie: sp ? sp[1] : (adv && i === 0 ? g.sets + 1 : g.sets),
                 ripetizioni: sp ? sp[0] : g.reps, recupero: sp ? 45 : g.rest };
      });
      if (profile.obiettivo === 'dimagrire') ex.push({ id: 'Elliptical_Trainer', serie: 1, ripetizioni: '10-15 min', recupero: 0 });
      return { nome, esercizi: ex };
    }),
  };
}

export async function aiPlan(profile, library) {
  const lib = library.filter(e => !e.soloCasa).map(e => `${e.id} | ${e.nome} | ${e.gruppo} | ${e.attrezzo}`).join('\n');
  const system = `Sei un personal trainer esperto. Crei schede di palestra semplici, sicure ed efficaci, in italiano.
Rispondi SOLO con JSON valido, senza altro testo.`;
  const prompt = `Crea una scheda di allenamento per questa persona:
- Obiettivo: ${profile.obiettivo}
- Livello: ${profile.livello}
- Giorni a settimana: ${profile.giorni}
- Attrezzatura: palestra completa
- Note / limitazioni: ${profile.note || 'nessuna'}
- Salute dichiarata: ${hasAny(profile.salute) ? summary(profile.salute) + ' (scegli esercizi prudenti, niente carichi massimali)' : 'nessun problema'}

Regole:
- Esattamente ${profile.giorni} giorni di allenamento, ognuno con 5-7 esercizi.
- Usa SOLO esercizi dall'elenco qui sotto, copiando l'id esatto.
- Esercizi semplici da eseguire, niente movimenti troppo tecnici se il livello è principiante.
- Bilancia i gruppi muscolari nella settimana, con progressione sensata.
- "ripetizioni" è una stringa (es. "8-12", "30-45 sec"), "recupero" in secondi.

Formato JSON:
{"nome":"...","giorni":[{"nome":"...","esercizi":[{"id":"...","serie":3,"ripetizioni":"8-12","recupero":90}]}]}

ELENCO ESERCIZI (id | nome | gruppo | attrezzo):
${lib}`;
  const raw = await gemini({ system, json: true, temperature: 0.4, contents: [{ role: 'user', parts: [{ text: prompt }] }] });
  let data;
  try { data = JSON.parse(raw.replace(/^```json\s*|```$/g, '').trim()); } catch { throw new Error('La risposta dell\'IA non era leggibile.'); }
  const ids = new Set(library.filter(e => !e.soloCasa).map(e => e.id));
  const giorni = (data.giorni || []).map((d, i) => ({
    nome: String(d.nome || `Giorno ${i + 1}`),
    esercizi: (d.esercizi || []).filter(e => ids.has(e.id)).map(e => ({
      id: e.id,
      serie: Math.min(6, Math.max(1, parseInt(e.serie) || 3)),
      ripetizioni: String(e.ripetizioni || '10-12'),
      recupero: Math.min(240, Math.max(0, parseInt(e.recupero) || 75)),
    })),
  })).filter(d => d.esercizi.length >= 3);
  if (giorni.length < 2) throw new Error('Scheda dell\'IA incompleta.');
  return { nome: String(data.nome || 'Scheda personalizzata'), fonte: 'ia', giorni };
}
