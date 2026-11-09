// Coach IA: risposta + modifiche proposte alla scheda (mai applicate senza il tuo OK).
import { S, save } from './store.js';
import { syncSession } from './training.js';
import { targets } from './nutrition.js';
import { topics } from './chats.js';
import { coachLine } from './salute.js';

export function coachSystem(lib) {
  const p = S.profile;
  const exName = (id) => lib.find(e => e.id === id)?.nome || id;
  const plan = S.plan.giorni.map((d, i) =>
    `Giorno ${i} "${d.nome}": ` + d.esercizi.map(e => `${e.id} (${exName(e.id)}, ${e.serie}x${e.ripetizioni}, rec ${e.recupero}s)`).join('; ')).join('\n');
  const rec = S.history.slice(-5).map(w => `${w.date.slice(0, 10)} ${w.dayName}: ` +
    w.exercises.map(e => `${exName(e.id)} ${e.sets.map(s => s.kg + 'kg×' + s.reps).join('/')}`).join('; ')).join('\n') || 'nessuno ancora';
  const nt = targets(p);
  const catalog = lib.map(e => `${e.id}|${e.nome}|${e.gruppo}|${e.attrezzo}${e.casa ? '|ok a casa' : ''}`).join('\n');

  return `Sei il coach personale di palestra di ${S.account?.name || 'questa persona'}. Parli SEMPRE in italiano, tono amichevole e diretto, risposte brevi (max 6 righe), semplici.
Profilo: obiettivo ${p.obiettivo}, livello ${p.livello}, ${p.giorni} giorni/settimana, peso ${p.peso || 'non indicato'} kg. Note: ${p.note || 'nessuna'}.
Altezza ${p.altezza || 'n.d.'} cm, età ${p.eta || 'n.d.'}. Obiettivo calorico indicativo: ${nt ? nt.kcal + ' kcal/giorno, ' + nt.prot + ' g proteine (mantenimento ~' + nt.mantenimento + ')' : 'non calcolato'}. Per l'alimentazione dai consigli generali e prudenti, mai diete estreme.\nLa scheda è pensata per la palestra. Oggi l'utente si allena: ${S.luogo === 'casa' ? 'A CASA (attrezzatura: ' + (p.casa === 'manubri' ? 'manubri' : 'solo corpo libero') + ')' : 'in palestra'}. L'app ha un interruttore Palestra/Casa nella schermata Oggi che adatta da solo gli esercizi: se l'utente dice che si allena a casa, suggeriscigli di usarlo invece di modificare la scheda base.

SCHEDA ATTUALE (giorno = numero a partire da 0):
${plan}

${coachLine(p.salute)}

ULTIMI ALLENAMENTI:
${rec}

COSE CHE RICORDI DI QUESTA PERSONA (memoria): ${(S.memoria || []).join('; ') || 'ancora niente'}

ARGOMENTI GIÀ DISCUSSI IN ALTRE CHAT (titoli, per continuità; richiamali solo se utile): ${topics().join('; ') || 'nessuno'}

CATALOGO ESERCIZI USABILI (id|nome|gruppo|attrezzo[|ok a casa]):
${catalog}

FORMATO DI RISPOSTA: solo JSON valido così:
{"risposta":"testo per l'utente","modifiche":[],"memoria":[]}

REGOLE SULLE MODIFICHE:
- Proponi modifiche alla scheda SOLO se l'utente lo chiede o descrive un problema (dolore, macchina occupata, troppo lungo, troppo facile/difficile). Altrimenti "modifiche":[] e rispondi e basta.
- Non modificare mai niente di tua iniziativa: nella "risposta" dì chiaramente cosa stai per cambiare e perché (es. "Sto per sostituire X con Y perché…") e chiedi se va bene. L'app mostrerà i pulsanti Applica / No.
- Tipi di modifica ammessi (usa solo id del catalogo e giorni esistenti):
  {"tipo":"sostituisci","giorno":0,"da":"id_attuale","a":"id_nuovo"}
  {"tipo":"parametri","giorno":0,"id":"id","serie":4,"ripetizioni":"6-8","recupero":120}
  {"tipo":"aggiungi","giorno":0,"id":"id","serie":3,"ripetizioni":"10-12","recupero":60}
  {"tipo":"rimuovi","giorno":0,"id":"id"}
- Per cambiare lo stesso esercizio in più giorni, una modifica per giorno. Massimo 6 modifiche.
- Consigli su tecnica, carichi e alimentazione: pratici e prudenti. Se c'è dolore acuto o problema medico, consiglia di fermarsi e sentire un medico.
- "memoria": SOLO se l'utente ti dice qualcosa di durevole su di sé (dolori o infortuni, preferenze, orari, attrezzatura, vincoli) e non è già nella memoria, scrivi 1-2 frasi brevissime (max 8 parole, in terza persona, es. "Spalla destra delicata"). Altrimenti "memoria":[]. Non ripetere ciò che è già ricordato.
- Non inventare dati che non hai.`;
}

// Memoria del coach: poche righe durevoli (max 12), senza doppioni
export function addMemory(items) {
  S.memoria = S.memoria || [];
  for (const t of items || []) {
    const v = String(t || '').trim().slice(0, 90);
    if (v.length < 4 || S.memoria.some(x => x.toLowerCase() === v.toLowerCase())) continue;
    S.memoria.push(v);
  }
  if (S.memoria.length > 12) S.memoria = S.memoria.slice(-12);
  save();
}

export function parseReply(raw) {
  try {
    const o = JSON.parse(String(raw).replace(/^\s*```(?:json)?\s*|\s*```\s*$/g, ''));
    return { text: String(o.risposta ?? o.text ?? '').trim() || '…', changes: Array.isArray(o.modifiche) ? o.modifiche : [], memoria: Array.isArray(o.memoria) ? o.memoria : [] };
  } catch { return { text: String(raw).trim(), changes: [], memoria: [] }; }
}

const clamp = (v, min, max, def) => Math.min(max, Math.max(min, parseInt(v) || def));

// Controlla le modifiche (id esistenti, giorni validi) e crea il testo leggibile
export function normChanges(raw, lib) {
  const nm = (id) => lib.find(e => e.id === id)?.nome;
  const out = [];
  for (const c of (raw || []).slice(0, 6)) {
    const g = parseInt(c.giorno), day = S.plan.giorni[g];
    if (!day) continue;
    const cur = (id) => day.esercizi.find(e => e.id === id);
    if (c.tipo === 'sostituisci' && cur(c.da) && nm(c.a) && !cur(c.a))
      out.push({ tipo: c.tipo, giorno: g, da: c.da, a: c.a, desc: `${day.nome}: ${nm(c.da)} → ${nm(c.a)}` });
    else if (c.tipo === 'parametri' && cur(c.id)) {
      const e = cur(c.id);
      const serie = clamp(c.serie, 1, 8, e.serie), rip = c.ripetizioni ? String(c.ripetizioni) : e.ripetizioni;
      const rec = c.recupero != null ? clamp(c.recupero, 0, 300, e.recupero) : e.recupero;
      out.push({ tipo: c.tipo, giorno: g, id: c.id, serie, ripetizioni: rip, recupero: rec, desc: `${day.nome}: ${nm(c.id)} → ${serie} × ${rip}, recupero ${rec}s` });
    } else if (c.tipo === 'aggiungi' && nm(c.id) && !cur(c.id)) {
      const serie = clamp(c.serie, 1, 8, 3), rip = String(c.ripetizioni || '10-12'), rec = clamp(c.recupero, 0, 300, 60);
      out.push({ tipo: c.tipo, giorno: g, id: c.id, serie, ripetizioni: rip, recupero: rec, desc: `${day.nome}: aggiungo ${nm(c.id)} (${serie} × ${rip})` });
    } else if (c.tipo === 'rimuovi' && cur(c.id) && day.esercizi.length > 3)
      out.push({ tipo: c.tipo, giorno: g, id: c.id, desc: `${day.nome}: tolgo ${nm(c.id)}` });
  }
  return out;
}

export function applyChanges(changes) {
  S.planBackup = JSON.parse(JSON.stringify(S.plan));
  let touchedSession = false;
  for (const c of changes) {
    const day = S.plan.giorni[c.giorno]; if (!day) continue;
    const i = day.esercizi.findIndex(e => e.id === (c.da || c.id));
    if (c.tipo === 'sostituisci' && i >= 0) day.esercizi[i] = { ...day.esercizi[i], id: c.a };
    else if (c.tipo === 'parametri' && i >= 0) Object.assign(day.esercizi[i], { serie: c.serie, ripetizioni: c.ripetizioni, recupero: c.recupero });
    else if (c.tipo === 'aggiungi' && i < 0) day.esercizi.push({ id: c.id, serie: c.serie, ripetizioni: c.ripetizioni, recupero: c.recupero });
    else if (c.tipo === 'rimuovi' && i >= 0 && day.esercizi.length > 3) day.esercizi.splice(i, 1);
    if (S.session && S.session.dayIndex === c.giorno) touchedSession = true;
  }
  S.plan.fonte = 'ia';
  save();
  if (touchedSession) syncSession();
}

export function undoChanges() {
  if (!S.planBackup) return false;
  S.plan = S.planBackup; S.planBackup = null; save();
  syncSession();
  return true;
}
