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

## Stato dei passi

- [x] 1. Progetto, tema Laguna, navigazione, schermate vuote
- [ ] 2. Login Google e database cloud
- [ ] 3–12. Vedi il brief

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
