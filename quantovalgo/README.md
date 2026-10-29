# QuantoValgo

App Android personale (Flutter) per registrare i lavori, suggerire quanto
farsi pagare e capire se sei in positivo o in negativo. Costi: zero.

## Come si avvia

```bash
flutter pub get
flutter run          # con un telefono Android collegato (o emulatore)
flutter test         # test automatici
flutter build apk    # APK per installarlo sul telefono
```

## Struttura (`lib/`)

| Cartella | Contenuto |
| --- | --- |
| `tema/` | Colori e tema "Laguna" |
| `widget/` | Pezzi grafici riusabili: sfondo, pulsanti lucidi, carte, barra in basso |
| `schermate/` | Le schermate dell'app |
| `modelli/` | Lavoro, Sottoprogetto, Cliente, PrezzoMercato (puro Dart) |
| `logica/` | Calcoli (prezzo suggerito, utile, ore) e formati (€, ore) |
| `servizi/` | Accesso, archivio Firestore e `StatoDati` (dati in memoria per le schermate) |

## Stato dei passi

- [x] 1. Progetto, tema Laguna, navigazione, schermate vuote
- [x] 2. Login Google e database cloud (vedi sotto: serve l'SHA-1 su Firebase)
- [x] 3. Lavori, sottoprogetti e clienti, con la forbice di prezzo a mano
- [x] 4. Costi: abbonamenti, una tantum, fissi, categorie colorate
- [x] 4b. Lavori "A giornata" (es. negozio con mamma: 30 € netti al giorno)
- [x] 5. Ore: cronometro e inserimento a mano
- [x] 7. Pagamenti: da incassare, incassato, in ritardo, promemoria con notifiche
- [x] 6. Home: saldo del mese, guadagno all'ora, sconti regalati
- [x] 8. Obiettivo, pareggio, tariffa minima e Impostazioni
- [x] 9. Ricerca prezzi con Tavily e autoapprendimento
- [ ] 10–12. Vedi il brief

## Richieste aggiunte dopo il brief

- **Costi una tantum**: costi presi in un certo mese, compresi nei costi totali
  da recuperare (passo 4, con il saldo nel passo 6). Per ogni costo si sceglie:
  tutto nel mese dell'acquisto, oppure spalmato su N mesi (ammortamento).
  "Da recuperare" = costi una tantum non ancora coperti dagli incassi.
- **Categorie dei costi** (es. "Microfono", "Doppiaggio"): create da te, ognuna
  con il suo colore (passo 4).
- **Effetto morbido al tocco**: pulsanti che si schiacciano e rimbalzano piano,
  con un tick di vibrazione (fatto, `widget/effetto_morbido.dart`).
- **Fluidità**: dissolvenza tra schede e tra pagine; app leggera, niente
  librerie pesanti (fatto).

Il font Nunito è incluso in `assets/fonts` (licenza OFL).

## Cloud (passo 2)

- Firebase, piano **Spark** (gratuito, nessuna carta): Authentication (Google) + Firestore.
- File **personali, non nel repo** (è pubblico): `android/app/google-services.json`,
  `android/key.properties` e `android/app/quantovalgo.jks` (chiave di firma).
  Senza `google-services.json` l'app si apre e mostra "Il cloud non è configurato".
- Dati sotto `utenti/{uid}`; regole di sicurezza in `firestore.rules` (da incollare
  in Firebase → Firestore → Regole → Pubblica).
- Cache offline di Firestore attiva (max 50 MB): l'app si apre già connessa e legge
  i dati anche senza internet. In Impostazioni si vede se i dati sono sincronizzati.
- Accesso: `servizi/accesso.dart` (interfaccia) e `accesso_firebase.dart` (vero).
  Nei test si usano versioni finte (`test/finti.dart`).

## Dati (passo 3)

- Sotto `utenti/{uid}`: `lavori`, `sottoprogetti`, `clienti`, `prezziMercato`.
- `StatoDati` ascolta il cloud **una volta sola** per tutta l'app e le schermate
  leggono da lì (meno letture, nessun caricamento aprendo una pagina).
- Le scritture non aspettano il cloud: offline restano in coda e l'app mostra subito
  la modifica.
- Un lavoro nuovo con un prezzo parte con un sottoprogetto "Lavoro intero" che
  incassa tutto il prezzo; si divide poi in parti più piccole.
- Sconti e fattori di competenza sono in `logica/calcoli.dart` (`ParametriPrezzo`):
  dal passo 8 si cambieranno da Impostazioni.

## Costi (passo 4)

- Tre tipi: **abbonamento** (mensile, diviso tra i progetti), **una tantum** (si sceglie
  per ogni costo: tutto nel mese, oppure spalmato su N mesi, es. 90 € ÷ 6 = 15 €/mese),
  **fisso** (mensile, non diviso).
- La **divisione tra i progetti è automatica**: si dividono il costo i progetti attivi
  nel mese, in proporzione alle ore lavorate (parti uguali se nessuno ha ore).
  Es.: Claude 20 € con ore 11 / 7 / 2 → 11 + 7 + 2 €.
  Dal passo 5 contano le ore registrate nel mese.
- **Categorie** create da te, ognuna con un colore della tavolozza di 10 (`tema/palette_categorie.dart`).
  Dalla scheda Costi → "Gestisci categorie" si può aggiungere un set di partenza.
- **Da recuperare** = costi una tantum meno l'utile dei progetti incassati
  (resta pieno finché i pagamenti non si segnano come incassati: passo 7).
- Un abbonamento disdetto (interruttore "Ancora attivo") smette dal mese dopo.
- Calcoli in `logica/costi.dart`, provati con i numeri del brief e del mockup.

## Lavori "A giornata" (passo 4b)

- Nuovo tipo di lavoro: guadagno **netto fisso per giornata** (es. 30 €), senza ore,
  senza sottoprogetti e senza quote dei costi condivisi.
- Ogni giornata ha una data e un importo (di partenza la tariffa, ma si cambia giorno per giorno).
  Si incassa **nel giorno stesso**: contano nel guadagno le giornate fino a oggi,
  quelle future sono "in programma".
- **Aggiungere più giorni** (pagina "Aggiungi giornate"): schema della settimana
  (L M M G V S D, con scorciatoie) + "dal…" + "per N giorni" oppure "fino al…";
  il calendario si riempie e si toccano i singoli giorni per toglierne o aggiungerne.
  I giorni già registrati si saltano e non contano nel numero.
- Dalla pagina del progetto un tocco su un giorno del calendario aggiunge, modifica o toglie quella giornata.
- Dati in `utenti/{uid}/giornate`; la logica dei giorni è in `logica/giornate.dart`.
- **Mezza giornata**: ogni giornata può essere intera o mezza. La mezza vale **metà**
  dell'importo intero di partenza (15 € su 30 €), ritoccabile; conta 0,5 nel numero
  di giornate. Nel calendario è segnata con ½. Nello schema si sceglie "Giorni interi" o
  "Mezze giornate" per tutto il gruppo, poi ogni giorno si cambia con tocchi
  successivi: intero → mezza → tolto.

## Ore (passo 5)

- **Cronometro** su ogni sottoprogetto: tasto avvio/stop nella riga del progetto, oppure
  dalla pagina del sottoprogetto (tocco sulla riga). Uno solo acceso alla volta: se ne avvii
  un altro, il primo si ferma e si salva.
- Il cronometro è un **orario di inizio salvato nel cloud** (sessione senza `fine`),
  non un contatore che gira nell'app: continua anche se chiudi l'app o spegni il telefono,
  e riaprendo la banda in basso mostra subito il tempo trascorso. Sotto il minuto non si salva.
- **Ore a mano**: giorno + ore + minuti (anche "1,5" ore); le sessioni si correggono e si tolgono.
- **Ore di un sottoprogetto** = ore iniziali (scritte a mano nel sottoprogetto) + ore registrate.
  Il cronometro acceso conta solo da quando lo fermi.
- **Costi condivisi**: la divisione tra i progetti segue le ore registrate **nel mese**;
  se nel mese non ce ne sono, le ore totali del progetto; se non ce ne sono, parti uguali.
- Dati in `utenti/{uid}/sessioni`; calcoli in `logica/ore.dart`.

## Costi e progetti per categoria

La regola vale per **tutte** le categorie (Claude, Doppiaggio, Podcast, Negozio…, anche quelle
inventate da te):

- Ogni **progetto** ha una categoria, la stessa lista dei costi (si sceglie in Nuovo lavoro,
  "Categoria dei costi"). "Nessuna" vuol dire proprio nessuna.
- I **costi di una categoria** si dividono e si recuperano **solo con i progetti della stessa
  categoria**. Un costo **senza categoria** è generale: lo dividono tutti i progetti, tranne i
  lavori "A giornata" (a meno che il costo abbia la categoria del loro lavoro).
- Se in un mese una categoria non ha progetti attivi, il costo non pesa su nessuno ("Da
  assegnare") ma **resta nel da recuperare** di quella categoria: contano tutti i mesi pagati.
- **Da recuperare**: una riga per categoria (con il suo colore) e "Altri costi" (acquisti una
  tantum senza categoria). Ogni riga si copre con l'utile dei progetti incassati **della stessa
  categoria**; gli altri costi con l'utile che avanza (quello in più delle categorie che hanno già
  coperto i propri costi, più quello dei progetti senza costi di categoria). L'utile non si usa
  due volte.
- Collegamento comodo: nel foglio di una categoria "Progetti che ne fanno parte da soli" (es.
  Claude → tipo Claude). I progetti di quel tipo che non hanno una categoria scelta la prendono
  da lì, anche i vecchi. Se scegli un'altra categoria (o "Nessuna") vince la tua scelta.
- Calcoli in `logica/costi.dart` (`gruppiDaRecuperare`, `costoSostenutoFinoA`); la categoria di
  un progetto in `StatoDati.categoriaDelLavoro`.

## Pagamenti (passo 7)

- Ogni progetto (tranne "A giornata", che si incassa giorno per giorno) ha una scheda
  **Pagamento**: *Da incassare*, *In ritardo di N giorni* o *Incassato*, con importo,
  scadenza (7 / 15 / 30 giorni da oggi, data a scelta, nessuna) e "Richiesto il…".
  "Segna incassato" ha l'**Annulla**; "Riporta a da incassare" corregge un errore.
- **In ritardo** = scadenza superata e non incassato (il giorno della scadenza non conta).
- **Giorni per pagare** = dalla data "Richiesto il…" (se vuota, dalla creazione del progetto)
  al giorno dell'incasso. La media dei clienti sta in Clienti.
- **Importo di un progetto** = somma dei ricavi dei sottoprogetti; se non ce ne sono, il
  prezzo finale.
- **Da incassare** (riquadro in Clienti, poi in Home) porta alla lista: prima i più in ritardo.
- **Clienti**: giorni medi di pagamento, *I migliori* (chi ha pagato di più), *Ritardatari*
  con "Copia promemoria": copia un messaggio pronto da incollare in WhatsApp o dove vuoi.
- **Promemoria**: notifiche locali del telefono (niente server, niente costi), alle 9:00
  ora di Roma: il giorno prima della scadenza, il giorno stesso e ogni 3 giorni di
  ritardo (5 volte). Solo per i progetti con scadenza. Si ricalcolano a ogni modifica e si
  spengono da Impostazioni → *Promemoria pagamenti*. Il permesso notifiche si chiede una
  volta, quando c'è almeno un promemoria. Arrivano con una tolleranza di qualche minuto
  (sveglie "inesatte": non serve un permesso speciale).
- Dati: i campi `statoPagamento`, `scadenza`, `dataIncasso`, `richiestoIl` stanno nel
  progetto; l'interruttore in `utenti/{uid}/impostazioni/generali`.
- Codice: `logica/pagamenti.dart`, `logica/promemoria.dart`, `servizi/promemoria_*.dart`,
  `servizi/pianificatore_promemoria.dart`, `schermate/carta_pagamento.dart`,
  `schermate/pagamenti.dart`.

## Home (passo 6)

- **Saldo del mese** = incassato nel mese − costi del mese, con le frecce per i mesi
  passati (non si va nel futuro). Pillola *In positivo / In negativo / In pari*.
- **Incassato** = progetti segnati incassati in quel mese (per data di incasso) + giornate
  del negozio già fatte in quel mese (quelle future non contano ancora).
- **Costi** = costi condivisi del mese (come nella scheda Costi) + costi diretti dei
  progetti incassati nel mese.
- **All'ora** = utile dei progetti incassati nel mese ÷ le loro ore. Le giornate non hanno
  ore e i costi condivisi non entrano qui (come nel guadagno all'ora del singolo progetto).
  Senza ore registrate mostra "—".
- **Sconti regalati** = prezzo pieno − prezzo applicato, dei progetti creati in quel mese.
  Il riquadro compare solo se c'è qualcosa.
- **Da incassare** (tutti i mesi insieme) e l'elenco dei progetti stanno sotto.
- Codice: `logica/saldo.dart`, `StatoDati.saldoDelMese`, `schermate/home.dart`.

## Obiettivo e Impostazioni (passo 8)

- **Obiettivo mensile NETTO** (dopo le tasse) e **tasse in %** (22 di partenza), da
  Impostazioni o dalla pagina Obiettivo. Tutto in `utenti/{uid}/impostazioni/generali`.
- **Netto dopo tasse** = saldo × (1 − tasse%); con saldo negativo non ci sono tasse.
  **Avanzamento** = netto ÷ obiettivo (barra e percentuale; oltre il 100% = raggiunto).
- **Punto di pareggio** = costi del mese (condivisi + diretti dei progetti incassati),
  con quanto manca per coprirli.
- **Tariffa minima oraria** = (obiettivo ÷ (1 − tasse%) + costi del mese) ÷ ore registrate
  nel mese. Senza ore registrate (o senza obiettivo) mostra "—". Le ore iniziali scritte a
  mano nei sottoprogetti non hanno data e non contano.
- Pagina Obiettivo con le frecce dei mesi, come la Home.
- **Sconti per relazione** e **correzione del prezzo per livello** si cambiano da
  Impostazioni e valgono per i nuovi prezzi (i progetti già salvati restano com'erano).
  Nei campi percentuale con valori negativi si può scrivere il segno meno.
- Codice: `modelli/impostazioni.dart`, `logica/obiettivo.dart`, `schermate/obiettivo.dart`,
  `schermate/impostazioni.dart`, `schermate/foglio_numero.dart`.
- Ancora da fare in Impostazioni: stato della ricerca prezzi (passo 9) e backup.

## Ricerca prezzi e autoapprendimento (passo 9)

**Ricerca sul web (Tavily)**
- La **chiave** si crea gratis su tavily.com (1.000 crediti al mese, senza carta) e si
  incolla in Impostazioni → Ricerca prezzi. Sta nel cloud privato dell'utente
  (`impostazioni/generali`), **mai nel codice né su GitHub**.
- Parte **solo** dal pulsante "Cerca prezzi" (Nuovo lavoro) oppure, se acceso in
  Impostazioni, **una volta a settimana quando apri l'app** (non gira in background).
  L'aggiornamento tocca solo le forbici trovate dal web e più vecchie di 7 giorni, o
  mancanti: **quelle scritte a mano non si toccano mai**.
- Ricerca "basic" = **1 credito**. Freno di sicurezza: **50 ricerche al mese** (contatore
  visibile in Impostazioni, riparte da solo a ogni mese). Tre tipi cercabili:
  Doppiaggio, Codice, Claude (query in italiano in `logica/prezzi_web.dart`).
  "Altro" e "A giornata" non hanno ricerca: forbice a mano.
- Dai risultati si prendono gli **importi in euro** ("80 €", "€80", "EUR 500",
  "da 80 a 120 euro", "1.200 €", "15,000 €"); si scartano quelli **all'ora, al mese,
  all'anno o al minuto** (la forbice è un prezzo a lavoro), quelli fuori scala per il
  tipo (es. doppiaggio 20–3.000 €) e
  serve almeno **5 importi da 2 siti diversi**; la forbice è dal **25° al 75°
  percentile**, arrotondata a 5 €, e se è più larga di 8 volte non è affidabile.
- Se non è affidabile l'app lo dice e propone di scrivere la forbice a mano.
  Se è affidabile **non salva da sola**: mostra forbice e siti, e si salva con
  "Usa questa forbice" (data e fonti incluse).
- Errori spiegati in italiano: chiave non valida, niente internet, troppe richieste,
  crediti Tavily finiti. Gli errori non contano come ricerca.
- La risposta si legge come UTF-8 di proposito: senza charset il pacchetto `http` usa
  Latin-1 e il simbolo € si romperebbe.

**Autoapprendimento (gratis, senza AI)**
- Per ogni lavoro **incassato** di un tipo si confronta quanto hai incassato con il centro
  del prezzo suggerito (forbice di mercato × livello × sconto di quella relazione).
  Lo scarto medio degli **ultimi 5** (ne servono almeno 3) sposta la forbice di quel
  tipo, **al massimo ±15%**. Lo scarto si misura sulla forbice di partenza, così la
  correzione non si "mangia da sola".
- La correzione si vede in Nuovo lavoro ("Corretta del +8% sui tuoi ultimi 4 lavori
  incassati") e vale per il prezzo suggerito; la forbice salvata resta quella vera.
- Se lo scarto medio supera il **20%** compare un avviso in Home: toccandolo si rivede
  la forbice di quel tipo.
- Codice: `logica/prezzi_web.dart`, `logica/apprendimento.dart`,
  `servizi/ricerca_tavily.dart`, `servizi/aggiornamento_prezzi.dart`,
  `schermate/foglio_ricerca.dart`, `schermate/foglio_chiave.dart`.
- Prova dal vivo (ottobre 2026): Doppiaggio ≈ 30–200 €, Codice ≈ 510–2.625 € (sito
  vetrina). **Claude**: «quanto costa un chatbot per il sito di una piccola azienda» →
  170–700 € (4 siti). Domande sull'AI "in generale" (automazione, miglioramento vendite,
  consulenza) **non trovano prezzi pubblici**: sul web ci sono solo grandi aziende senza
  cifre e, peggio, i prezzi delle criptovalute "AI" (per questo coinmarketcap e simili sono
  esclusi). In quei casi l'app lo dice e la forbice si scrive a mano.
- Quando la ricerca non è affidabile l'app dice **perché**: nessun prezzo, pochi prezzi
  (ne servono 5), un solo sito (ne servono 2), prezzi troppo diversi o tutti uguali.

**Ricerca personalizzata**
- In Nuovo lavoro, sopra il riquadro blu, il campo **"Cosa vuoi cercare?"**: parte dalla
  domanda del tipo (modificabile), ci sono **idee da toccare** e l'anteprima di quello che
  verrà cercato davvero. L'app aggiunge da sola "Italia", "prezzo" ed "euro" se mancano
  (`costruisciQuery`). Funziona anche per **Altro** (lì la domanda la scrivi tu).
- La domanda si salva nel lavoro (solo se diversa da quella di partenza) e nella forbice
  trovata: così l'aggiornamento settimanale rifà **la stessa ricerca**, anche per Altro.
- Conviene cercare il **prezzo del servizio intero**, non tariffe orarie né prodotti.
  Provate dal vivo: «assistenza informatica privati costo intervento a domicilio» →
  40–50 € (5 siti); «servizio installazione e configurazione tablet costo» → 20–35 €.
  Domande sui prodotti ("smartphone") danno prezzi dei prodotti (215–900 €): non servono.
- Corretto un bug del passo 7: modificando un progetto si perdeva la data "Richiesto il".

**Prezzi di riferimento con fonte e link**
- Dopo ogni ricerca si vede l'elenco dei **prezzi trovati**, una riga per pagina: **sito**,
  titolo, prezzi scritti lì e icona link. Toccando la riga si apre la pagina nel browser
  (solo link http/https; se il telefono non riesce, il link viene copiato).
- L'elenco c'è **sia quando la forbice è affidabile sia quando non lo è** (meno di 5 prezzi,
  un solo sito, prezzi troppo diversi...): così si controlla di persona e si riconoscono i
  prezzi sbagliati (es. un "100 €" preso da un articolo di giornale). Dal più economico.
  Si vedono 8 pagine, poi "Mostra tutte".
- Con "Usa questa forbice" i prezzi di riferimento si **salvano con la forbice**: in Nuovo
  lavoro compare "Vedi i prezzi di riferimento (N)" con data e domanda della ricerca.
- I risultati di Tavily **cambiano da una volta all'altra** per la stessa domanda: lo stesso
  testo può dare una forbice oggi e "non affidabile" domani.
- Codice: `widget/lista_prezzi.dart`, `PrezzoTrovato` in `logica/prezzi_web.dart`.
