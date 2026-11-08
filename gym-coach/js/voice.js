// Dettatura vocale.
//  • "live": il telefono trascrive mentre parli (Web Speech API) — il testo compare in diretta.
//  • "rec" : registro l'audio e, quando tocchi Fine, lo trascrive Gemini (riserva se la trascrizione live non c'è).
// Continua ad ascoltare finché non chiami stop(): se il telefono si ferma da solo (pausa lunga) riparte.
import { gemini } from './ai.js';

const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
const iosApp = /iPhone|iPad|iPod/.test(navigator.userAgent) && (navigator.standalone || matchMedia('(display-mode: standalone)').matches);
const MAX_REC_S = 120;                                   // registrazione: massimo 2 minuti (l'audio va in un'unica richiesta)

export function voiceMode() {
  if (SR && !iosApp) return 'live';                      // sull'app installata su iPhone la trascrizione live non è affidabile
  if (navigator.mediaDevices?.getUserMedia && window.MediaRecorder) return 'rec';
  return null;
}
const clean = t => t.replace(/\s+/g, ' ').trim();

/* ---------- registrazione + trascrizione Gemini ---------- */
async function startRec() {
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  const mime = ['audio/webm;codecs=opus', 'audio/mp4', 'audio/webm', 'audio/ogg'].find(m => MediaRecorder.isTypeSupported?.(m)) || '';
  const mr = new MediaRecorder(stream, { ...(mime ? { mimeType: mime } : {}), audioBitsPerSecond: 24000 });
  const chunks = [];
  mr.ondataavailable = e => e.data?.size && chunks.push(e.data);
  mr.start(1000);
  const free = () => stream.getTracks().forEach(t => t.stop());
  return {
    cancel() { try { mr.state !== 'inactive' && mr.stop(); } catch {} free(); },
    async stop() {
      await new Promise(res => { mr.onstop = res; try { mr.stop(); } catch { res(); } });
      free();
      const blob = new Blob(chunks, { type: (mr.mimeType || mime || 'audio/mp4') });
      if (blob.size < 1500) return '';                    // praticamente niente audio
      const data = await new Promise(res => { const r = new FileReader(); r.onload = () => res(String(r.result).split(',')[1]); r.readAsDataURL(blob); });
      const out = await gemini({
        temperature: 0, ms: 40000,
        contents: [{ role: 'user', parts: [
          { text: 'Trascrivi fedelmente in italiano ciò che viene detto in questo audio. Rispondi SOLO con il testo trascritto, con la punteggiatura corretta, senza commenti né virgolette. Se non si sente parlare, rispondi con una stringa vuota.' },
          { inlineData: { mimeType: blob.type.split(';')[0] || 'audio/mp4', data } }] }],
      });
      return clean(String(out || ''));
    },
  };
}

/* ---------- trascrizione in diretta ---------- */
function startLive(cb) {
  let base = '', cur = '', interim = '', stopped = false, rec, waiter = null;
  const emit = () => cb.onText(clean(base + ' ' + cur), clean(interim));
  const make = () => {
    rec = new SR(); rec.lang = 'it-IT'; rec.continuous = true; rec.interimResults = true;
    rec.onresult = (e) => {
      // ricostruisco tutto da zero a ogni evento (su Android i risultati si ripetono se li sommo)
      let fin = '', tmp = '';
      for (let i = 0; i < e.results.length; i++) (e.results[i].isFinal ? (fin += ' ' + e.results[i][0].transcript) : (tmp += ' ' + e.results[i][0].transcript));
      cur = clean(fin); interim = clean(tmp); emit();
    };
    rec.onerror = (e) => {
      if (e.error === 'no-speech' || e.error === 'aborted') return;      // normale: silenzio, riparte da sola
      stopped = true;
      cb.onFail(e.error, clean(base + ' ' + cur + ' ' + interim));        // permesso negato, rete assente, lingua non supportata…
    };
    rec.onend = () => {
      base = clean(base + ' ' + cur + ' ' + interim); cur = ''; interim = '';
      if (stopped) { waiter?.(base); return; }
      try { make(); } catch { stopped = true; cb.onFail('restart', base); }   // il telefono si è fermato da solo: riparto
    };
    rec.start();
  };
  make();
  return {
    cancel() { stopped = true; try { rec.abort(); } catch {} },
    stop() {                                                                // aspetto l'ultima parola (max ~1,2 s)
      return new Promise(res => {
        stopped = true;
        const t = setTimeout(() => res(clean(base + ' ' + cur + ' ' + interim)), 1200);
        waiter = (v) => { clearTimeout(t); res(v); };
        try { rec.stop(); } catch { clearTimeout(t); res(clean(base + ' ' + cur + ' ' + interim)); }
      });
    },
  };
}

/* ---------- interfaccia unica ----------
   start({ onText(finale, provvisorio), onMode(m), onFail(messaggio) }) → { mode, stop():Promise<testo>, cancel() } */
export async function startVoice(cb) {
  let impl, mode = voiceMode(), saved = '';
  if (!mode) throw new Error('Questo telefono non permette la dettatura.');
  const ctl = {
    get mode() { return mode; },
    cancel() { impl?.cancel(); },
    async stop() { const t = await impl.stop(); return clean((saved + ' ' + t)); },
  };
  const toRec = async (soFar) => {                       // riserva: registro e faccio trascrivere a Gemini
    saved = soFar || ''; mode = 'rec';
    try { impl = await startRec(); cb.onMode('rec'); }
    catch (e) { cb.onFail(denied(e)); }
  };
  if (mode === 'live') {
    impl = startLive({
      onText: cb.onText,
      onFail: (err, soFar) => {
        if (err === 'not-allowed' || err === 'service-not-allowed') return cb.onFail('Per parlare serve il permesso del microfono: abilitalo dalle impostazioni del browser.');
        if (navigator.mediaDevices?.getUserMedia && window.MediaRecorder) return toRec(soFar);
        cb.onFail('La trascrizione non funziona su questo telefono (' + err + ').');
      },
    });
  } else {
    try { impl = await startRec(); } catch (e) { throw new Error(denied(e)); }
  }
  return ctl;
}
const denied = (e) => /denied|NotAllowed|Permission/i.test(e?.name + ' ' + e?.message)
  ? 'Per parlare serve il permesso del microfono: abilitalo dalle impostazioni del browser.' : 'Non riesco ad usare il microfono: ' + (e?.message || e);
