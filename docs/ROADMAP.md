# Roadmap: Pulizia Privacy

Obiettivo: ridurre la profilazione. Vedere chi ha i tuoi dati, revocare i consensi, far cancellare ciò che è già stato raccolto. Prima per uso personale, poi come prodotto in abbonamento.

| Fase | Contenuto | Stato |
|---|---|---|
| 1 | MVP estensione: scansione cookie/cronologia, cancellazione locale, bozza GDPR | Prima versione in `extension/` |
| 2 | Revoca consensi: regole per i banner (OneTrust, Cookiebot, iubenda, Didomi), Global Privacy Control, rifiuto automatico | Da fare |
| 3 | Database aziende (dominio → azienda → contatto privacy → modello per paese), invio dall'email dell'utente, scadenze | Da fare |
| 4 | Sito con account, abbonamento, privacy policy, DPIA, revisione legale | Da fare |
| 5 | Pubblicazione su Chrome Web Store / Edge Add-ons, richieste ricorrenti, controllo leak | Da fare |

## Regole di cautela (valgono dal primo giorno)
- Dati in locale per impostazione: cronologia e cookie non lasciano il browser.
- Permessi minimi, spiegati all'utente.
- Nessun tracker nell'estensione e nel sito.
- Nessuna richiesta parte senza lettura e conferma dell'utente.
- Nessuna vendita di dati: ricavi solo dall'abbonamento.
- Promesse oneste: "riduci", mai "azzeri" la profilazione.
- Cancellazione dell'account con un clic.
- Parere legale (GDPR, deleghe per conto terzi, consumatori) prima di vendere.

## Limiti
- Non ferma i truffatori al telefono.
- Le aziende hanno un mese per rispondere (art. 12.3 GDPR).
- I dati già passati a terzi richiedono richieste separate.
