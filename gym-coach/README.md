# Gym Coach 💪

App per la palestra con coach IA (Gemini). PWA: si installa sul telefono, funziona offline, tutto gratis.

## Cosa fa (Fase 1 + coach base)
- Onboarding: obiettivo, livello, giorni a settimana, limiti/infortuni
- Scheda creata da Gemini (o scheda pronta se non hai la chiave)
- 47 esercizi con immagini animate (inizio/fine movimento), istruzioni in italiano e link al video
- Allenamento guidato: serie, kg, ripetizioni, timer di recupero, schermo sempre acceso
- Suggerimento automatico "prova +2,5 kg" quando completi tutte le ripetizioni
- Sostituisci un esercizio (macchina occupata / dolore)
- Chat col coach, che conosce scheda e ultimi allenamenti
- Dati salvati solo sul telefono (localStorage), backup esportabile

## Provarla in locale
```bash
cd gym-coach
python3 -m http.server 8000   # poi apri http://localhost:8000
```

## Usarla sul telefono
Serve un indirizzo https. Con GitHub Pages è gratis: il workflow `.github/workflows/pages.yml`
pubblica la cartella `gym-coach/` a ogni push su `main`.
1. GitHub → Settings → Pages → Source: **GitHub Actions**
2. Apri l'URL dal telefono → menu del browser → **Aggiungi a schermata Home**

## Chiave Gemini
Crea una chiave gratuita su https://aistudio.google.com/apikey e incollala nell'app (Profilo).
Resta solo sul telefono e viene inviata solo a Google.
Il modello di default è `gemini-flash-latest` (modificabile in Profilo).

## Crediti
Immagini ed esercizi base: [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (pubblico dominio).

## Prossimi passi
Grafici dei progressi, record personali, video diretti nell'app, notifiche, alimentazione.
