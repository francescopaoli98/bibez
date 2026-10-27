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

- `src/app/` schermate (expo-router): `(tabs)` con Oggi / In arrivo / Calendario / Liste, `lista/[id]` (una lista), `attivita/[id]` (dettaglio), `temi.tsx`
- `src/theme/` temi, modalità chiaro/scuro e transizione "a onda" tra un tema e l'altro (`waves.ts` = forme delle onde)
- `src/lib/` parser del quick add, date, suoni
- `assets/sounds/` suoni dei temi, generati da `scripts/make-sounds.mjs`
- `src/db/` database SQLite locale (liste, attività, impostazioni)
- `src/components/` componenti riusabili

## Stato

Fatto: base, navigazione, temi con transizione a onda, database locale, vista Oggi, quick add testuale, temi speciali con suoni, In arrivo / Calendario / Liste, dettaglio attività con passi (checklist).
Prossimi: modelli (es. "Turno in sala"), promemoria, celebrazioni, condividi verso l'app, voce, login e sync con Supabase.

## Temi

6 temi normali (Indaco, Oceano, Bosco, Tramonto, Lavanda, Grafite) con Chiaro/Scuro/Auto, più 3 **temi speciali** con aspetto fisso:

| Tema | Aspetto | Onda quando ci si entra |
|---|---|---|
| Arcade | neon, font pixel, barra XP, serie di giorni, +20 XP | pixel che crescono e mangiano tutto |
| Atelier | carta, acquerello, pennellata, scrittura a mano | macchie di colore che si fondono |
| Studio | studio di registrazione, VU-meter, "take" | barre da equalizzatore |

L'onda dipende dal tema di arrivo; la direzione (sinistra→destra o destra→sinistra) dalla posizione nella lista. Le onde disegnate usano `@shopify/react-native-skia`. I suoni si accendono/spengono dalla schermata Temi e si rigenerano con `node scripts/make-sounds.mjs`.

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
