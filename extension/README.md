# Pulizia Privacy (MVP)

Estensione Chrome/Edge (Manifest V3). Fase 1 della roadmap in `docs/ROADMAP.md`.

## Cosa fa
- Legge **cookie** e **cronologia** in locale e li raggruppa per dominio/azienda.
- Segna i tracker noti (elenco iniziale in `lib/trackers.js`).
- Cancella i cookie di un sito o di tutti i tracker.
- Prepara una bozza di richiesta GDPR (revoca consenso, opposizione, cancellazione, accesso) in italiano e inglese.

## Privacy
- Nessuna chiamata di rete: il manifest blocca `connect-src` (`'none'`).
- Nome ed email per le bozze stanno solo in `chrome.storage.local`, sul tuo dispositivo.
- Nelle bozze vanno i **nomi** dei cookie, mai i valori.

## Provarla
1. Apri `chrome://extensions` (o `edge://extensions`).
2. Attiva **Modalità sviluppatore**.
3. **Carica estensione non pacchettizzata** e scegli questa cartella (`extension/`).
4. Clicca l'icona dell'estensione e poi **Scansiona**.

## Test
Dalla radice del repository: `npm test` (funzioni pure: domini, raggruppamento, bozze).

## Limiti noti
- `registrableDomain` usa un elenco ridotto di suffissi. Per la produzione serve la Public Suffix List.
- Il destinatario della richiesta (email privacy/DPO) va incollato a mano: l'archivio dei contatti arriva nella fase 3.
- I cookie "partizionati" non sono ancora coperti dalla scansione.
