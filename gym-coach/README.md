# Gym Coach 💪

App per la palestra con coach IA (Gemini). PWA: si installa sul telefono, funziona offline, tutto gratis.

## Cosa fa
- Onboarding: obiettivo, livello, giorni a settimana, limiti/infortuni
- Scheda creata da Gemini (o scheda pronta se non hai la chiave)
- 68 esercizi (22 pensati per casa) con immagini animate (inizio/fine movimento), istruzioni in italiano e link al video
- Allenamento guidato un esercizio alla volta: valori già compilati, un tocco per serie, timer di recupero, schermo sempre acceso
- Suggerimento automatico "prova +2,5 kg" quando completi tutte le ripetizioni
- Sostituisci un esercizio (macchina occupata / dolore)
- Chat col coach, che conosce scheda e ultimi allenamenti. Se chiedi un cambiamento (dolore, poco tempo, esercizio da cambiare) ti dice **cosa sta per modificare** e lo applica solo se premi "Sì, applica" (con "Annulla modifica" dopo)
- **Interruttore Palestra / Casa** (schermata Oggi e Scheda): a casa gli esercizi da palestra vengono sostituiti in automatico con equivalenti dello stesso gruppo muscolare, a corpo libero o con manubri (impostabile)
- **Stima di tempo e calorie** per ogni giorno di scheda e per ogni allenamento fatto (formula MET, indicativa; usa il tuo peso, altrimenti 75 kg)
- **Calorie e proteine giornaliere** (formula Mifflin-St Jeor + obiettivo), calcolate da peso, altezza, età e sesso; il coach le conosce
- **Progressi**: peso corporeo (grafico), forza per esercizio, record personali e storico degli allenamenti
- **Promemoria**: scegli giorni e ora e scarichi un file calendario (.ics) con eventi settimanali e avviso 15 minuti prima (niente notifiche push: richiederebbero un server)
- Dati salvati solo sul telefono (localStorage), backup esportabile

## Provarla in locale
```bash
cd gym-coach
python3 -m http.server 8000   # poi apri http://localhost:8000
```

## Usarla sul telefono
Serve un indirizzo https. Con GitHub Pages è gratis: il workflow `.github/workflows/pages.yml`
pubblica la cartella `gym-coach/` a ogni push sul branch `claude/ai-gym-coach-app-gvnftg`.
1. GitHub → Settings → Pages → Source: **GitHub Actions**
   poi Settings → Environments → github-pages → Deployment branches → aggiungi `claude/ai-gym-coach-app-gvnftg`
2. Apri l'URL dal telefono → menu del browser → **Aggiungi a schermata Home**

Indirizzo dell'app: https://francescopaoli98.github.io/bibez/

## Sicurezza e Cloudflare
- **Blocco con password** (Impostazioni → Sicurezza): all'apertura e dopo un po' in background; i dati sul telefono sono cifrati (AES-GCM, chiave dalla password con PBKDF2). La password non si può recuperare.
- **Cloudflare Pages + Access + proxy Gemini**: vedi `CLOUDFLARE.md` nella radice del repository.

## Chiave Gemini
Crea una chiave gratuita su https://aistudio.google.com/apikey e incollala nell'app (Profilo).
Resta solo sul telefono e viene inviata solo a Google.
Il modello di default è `gemini-flash-latest` (modificabile in Profilo).

## Crediti
Immagini ed esercizi base: [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (pubblico dominio).

## Prossimi passi
Video diretti nell'app (servono video scelti e verificati), controllo della postura con la fotocamera, elastici/sbarra per la modalità casa.
