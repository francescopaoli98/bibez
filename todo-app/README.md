# Bibez Todo (nome provvisorio)

App todo per Android, fatta con Expo + React Native.

## Avvio

```bash
npm install
npx expo start
```

Poi inquadra il QR code con **Expo Go** sul telefono Android (stessa rete Wi-Fi del PC).

## Controlli

```bash
npm run typecheck
npm test            # prova del parser del quick add
npx expo-doctor
```

## Struttura

- `src/app/` schermate (expo-router): `(tabs)` con Oggi / In arrivo / Calendario / Liste, `temi.tsx`
- `src/theme/` temi, modalità chiaro/scuro e transizione "a onda" tra un tema e l'altro
- `src/db/` database SQLite locale (liste, attività, impostazioni)
- `src/components/` componenti riusabili

## Stato

Fatto: base, navigazione, temi con transizione a onda, database locale, vista Oggi, quick add testuale.
Prossimi: liste/calendario, promemoria, voce, temi speciali, login e sync con Supabase.

## Quick add

Nella barra in basso si scrive una frase e l'app ricava da sola data, ora, lista e importanza:

```
Chiama Marco domani alle 15 #lavoro !importante
```

- data: oggi, domani, dopodomani, stasera, lunedì..domenica, 27 ottobre, 27/10, il 5, tra 2 ore, tra 3 giorni
- ora: alle 15, alle 9:30, 15:30, mezzogiorno, di sera / pomeriggio / mattina
- lista: `#lavoro` (basta l'inizio del nome)
- importante: `!` oppure `!importante`

Non ancora: ripetizioni ("ogni martedì"), promemoria reali (step 5).

Da decidere prima della pubblicazione: nome definitivo, package id Android, icona.
