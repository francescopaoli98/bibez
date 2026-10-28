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
- [ ] 4–12. Vedi il brief

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
