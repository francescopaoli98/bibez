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
npx expo-doctor
```

## Struttura

- `src/app/` schermate (expo-router): `(tabs)` con Oggi / In arrivo / Calendario / Liste, `temi.tsx`
- `src/theme/` temi, modalità chiaro/scuro e transizione "a onda" tra un tema e l'altro
- `src/db/` database SQLite locale (liste, attività, impostazioni)
- `src/components/` componenti riusabili

## Stato

Step 1 completato: base, navigazione, temi, database locale, vista Oggi.
Prossimi: quick add testuale, liste/calendario, promemoria, voce, login e sync con Supabase.

Da decidere prima della pubblicazione: nome definitivo, package id Android, icona.
