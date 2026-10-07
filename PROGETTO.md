# Progetto: RPG voxel in stile Cube World

Prototipo giocabile nel browser. Questo documento è il piano: il codice si scrive dopo.

## 1. Fattibilità

**Fattibile come prototipo**, non come gioco completo.

| Parte | Fattibile? | Note |
|---|---|---|
| Mondo voxel procedurale infinito | Sì | Chunk + rumore Simplex |
| Personaggio, camera, collisioni | Sì | Fisica AABB semplice, niente motore esterno |
| Combattimento base e nemici | Sì | IA elementare (insegui e attacca) |
| Loot, inventario, classi | Sì | Dati in JSON |
| Salvataggio | Sì | localStorage |
| Grafica | Sì, stile semplice | Cubi a colori piatti, niente texture |
| Multiplayer | No (per ora) | Troppo costoso e fuori scope |
| Audio curato, arte rifinita | Limitato | Suoni semplici sintetizzati |

## 2. Obiettivo del prototipo

Camminare in un mondo infinito di cubi colorati, saltare, combattere nemici, raccogliere loot. Il "senso di esplorazione" di Cube World, in piccolo.

## 3. Scelte tecniche

- **Linguaggio:** JavaScript (moduli ES), nessun framework pesante.
- **Rendering:** Three.js.
- **Build:** Vite, per avviare e pubblicare facilmente.
- **Dati:** JSON per nemici, oggetti e classi.
- **Test:** Playwright con Chromium per controlli automatici e screenshot.

Perché il browser: si apre con un link, non richiede installazioni ed è testabile in questo ambiente.

## 4. Architettura

```
src/
  main.js            avvio, loop di gioco
  world/
    noise.js         rumore Simplex (seed fisso)
    chunk.js         dati di un chunk (es. 16x64x16)
    mesher.js        da voxel a mesh (solo facce visibili)
    worldManager.js  carica/scarica chunk attorno al giocatore
    biomes.js        prato, deserto, neve
  entities/
    player.js        movimento, salto, statistiche
    enemy.js         IA semplice
    physics.js       collisioni AABB con i voxel
  rpg/
    combat.js        danni, vita, cooldown
    items.js         loot e inventario
    classes.js       guerriero (poi ranger, mago)
  render/
    camera.js        terza persona
    lighting.js      sole, ombre, giorno/notte
  ui/
    hud.js           vita, inventario, messaggi
  save/
    save.js          localStorage
data/                JSON di nemici, oggetti, classi
tests/               test Playwright
```

### Punti critici

1. **Mesh dei chunk:** disegnare solo le facce a contatto con l'aria. Senza questo il gioco è lento.
2. **Caricamento chunk:** distanza di vista limitata (es. 6-8 chunk), costruzione a pezzi per non bloccare il frame.
3. **Collisioni:** controllo a scatola contro i voxel vicini, movimento separato per asse.
4. **Stile:** colore per vertice, niente texture. Palette piccola e fissa.

## 5. Fasi e criteri di completamento

| Fase | Contenuto | Fatto quando |
|---|---|---|
| 1 | Mondo a chunk, biomi, camera libera | Si vola sopra un mondo infinito senza scatti |
| 2 | Personaggio, salto, collisioni, camera 3ª persona | Si cammina e si salta senza attraversare i blocchi |
| 3 | Nemici, attacco, vita, morte, respawn | Si combatte e si muore/rinasce |
| 4 | Loot, inventario, 2-3 classi, livelli | Le statistiche cambiano con l'equipaggiamento |
| 5 | Giorno/notte, villaggi, un boss | C'è almeno un obiettivo da raggiungere |
| 6 | Salvataggio e rifiniture | La partita si riprende dopo la chiusura |

**Traguardo consigliato:** fasi 1-3. Sono il nucleo giocabile.

## 6. Stima dei crediti

Stima relativa, non esatta. Dipende da quante iterazioni servono.

| Fase | Peso |
|---|---|
| 1 | Medio-alto (mesher e chunk sono la parte difficile) |
| 2 | Medio |
| 3 | Medio |
| 4 | Medio |
| 5 | Medio-alto |
| 6 | Basso |

Le fasi 1-3 sono circa metà del lavoro totale. Conviene consumarle in sessioni separate, una fase alla volta, verificando ciascuna.

## 7. Rischi

| Rischio | Mitigazione |
|---|---|
| Prestazioni basse | Mesh ottimizzate, distanza di vista regolabile |
| Scope che cresce | Lavorare per fasi con criteri chiari |
| Aspetto poco curato | Palette fissa, luci ben fatte, poche forme ma coerenti |
| Perdita di contesto tra sessioni | Tenere questo file aggiornato |

## 8. Decisioni prese

- Cartella: radice di `bibez`.
- Vista: 3D, terza persona.
- Stile: voxel a colori vivaci e piatti.
- Personaggio: proporzioni Cube World (testa grande).
- Classi: solo guerriero nella prima versione.
- Comandi: tastiera + mouse (WASD, salto, mouse per camera e attacco).
- Mondo: seed casuale a ogni partita, salvato nel file di salvataggio.
- Nome: provvisorio, da decidere più avanti.
- Multiplayer: escluso.

## 9. Decisioni aperte

- Nome definitivo del gioco e del personaggio.
- Aggiunta di ranger e mago dopo la fase 4.
- Supporto touch/gamepad in una fase successiva.

## 10. Come riprendere

Alla prossima sessione basta dire: "riprendiamo da PROGETTO.md, fase N". Il piano contiene tutto il contesto necessario.
