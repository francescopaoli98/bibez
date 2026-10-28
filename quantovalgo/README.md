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
- [ ] 6–12. Vedi il brief

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

## Costi legati a un tipo di lavoro

- Ogni **categoria** può essere legata a un tipo di lavoro (Doppiaggio, Codice, Claude, Altro):
  "Si recupera con i progetti…". Senza legame (**Tutti**) vale per tutti i progetti.
- Un costo di una categoria legata (es. Claude) **si divide solo tra i progetti di quel tipo**
  attivi nel mese, e **si recupera solo con l'utile dei progetti incassati di quel tipo**.
  I lavori "A giornata" non portano mai costi.
- Se in un mese non ci sono progetti di quel tipo, il costo non pesa su nessuno ("Da assegnare")
  ma **resta nel da recuperare** del tipo: i costi legati contano tutti i mesi pagati.
- Il riquadro **Da recuperare** ha una riga per tipo, più "Altri costi" (solo acquisti una tantum
  senza tipo): gli altri costi si coprono con l'utile che avanza dai tipi che hanno già
  coperto i propri costi, più l'utile dei tipi senza costi. L'utile non si usa due volte.
- Le categorie create **prima** di questa regola non hanno il legame: vale "Tutti" finché
  non lo scegli (Costi → Gestisci categorie → tocca la categoria).
- Le categorie di partenza (Doppiaggio, Codice, Claude) nascono già legate al loro tipo.
- Calcoli in `logica/costi.dart` (`gruppiDaRecuperare`, `costoSostenutoFinoA`).
