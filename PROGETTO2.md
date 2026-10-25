# Ki Forge (nome provvisorio)

Gioco per PC, costi il più possibile a zero. Questo file è il piano del progetto.
Il vecchio piano (RPG voxel nel browser) resta in `PROGETTO.md`, non toccato.

## 1. Come lavorare insieme

- Sempre in italiano, semplice e diretto, poche parole.
- Codice pulito e commentato, con una breve spiegazione.
- Prima di scrivere codice complesso: domande di chiarimento.
- Si parte dall'obiettivo finale e si risale a ritroso, un passo alla volta.
- Prima di fare un mockup: chiedere.

## 2. Tecnica

| Voce | Scelta |
|---|---|
| Motore | Godot 4.x stabile (Unreal valutato, non scelto per ora) |
| Linguaggio | GDScript |
| Renderer | Forward+ |
| PC di sviluppo | RTX 3060, 16 GB RAM |
| Pubblicazione | prima itch.io (gratis), poi eventualmente Steam |
| Grafica | realistica, prima persona, si vedono solo le mani |
| Piattaforma | PC (non Android) |

Nota: il container cloud dove lavora Claude non ha GPU. I render veri si fanno sul PC di Francesco.

## 3. Idea di gioco

Prima persona, si vedono solo mani e avambracci. Ambientazione **solarpunk**:
città verde, piante sospese, turbine eoliche, architettura bianca e curva, luce dorata.

### Mani

- **Mano destra:** palmo aperto verso l'alto. Sopra il palmo galleggia lo **shuriken di ki**, fatto di pura luce.
- **Mano sinistra:** un piccolo **pannello solare** agganciato sul **dorso** della mano (lato nocche, non palmo), come un bracciale.
  - **Funzione:** **ricarica il ki**, stando alla luce del **sole** e vicino a **fonti di energia** sparse nel mondo.
  - **Materiali:** misto (ottone, legno intagliato, vetro, muschio e fiori vivi).
  - **Design:** deve essere un oggetto ancora **più solarpunk** del concept v3 (da rifare: più organico, con piante, legno, vetro, fiori).

### Il ki (sistema centrale)

Il ki è energia che il giocatore plasma. Lo shuriken è solo l'aspetto di partenza.

| Regola | Decisione |
|---|---|
| Scelta | In un **menu prima della partita** |
| Quantità | Massimo **3-4 ki diversi** salvati |
| Forma | **Libera**: si disegna a mano oppure si uniscono forme base. Un **assistente** aiuta a ottenere una forma vicina a quello che il giocatore ha fatto, senza stravolgerla |
| Colori | **Scelti dal giocatore** (verde e arancione sono solo il default) |
| Dimensione | Scelta dal giocatore |
| Effetto all'impatto | **Cambia con la forma** |
| Scia | Dipende dalla forma: uno **shuriken non ha scia**. La scia o il raggio compaiono solo se la forma è un raggio |
| Usi | **Lancio** (proiettile) e **melee** (corpo a corpo) |
| Costo | Più è grande, più consuma. C'è un **limite massimo** |
| Carica | Vedi sotto |

**Carica (confermato):**
- Caricare aumenta **intensità ed effetti particellari**, sia per ki grande sia per ki piccolo.
- La dimensione la decide il menu, non la carica.
- Esiste un tetto massimo.

### Idea di implementazione in Godot (da validare)

- Un oggetto dati per ogni ki: `forma`, `dimensione`, `colori`, `intensità`.
- Una sola energia con due comportamenti: lancio (proiettile con scia e impatto) e melee (lama/aura attorno alla mano).
- Danno, raggio e consumo derivano dai parametri.
- Forma libera: da decidere come si disegna nel menu (vedi domande aperte).

### Storia e struttura

- Il gioco **narra una storia**.
- Durante la storia il giocatore **scopre i poteri solarpunk**.
- Il ki e il pannello solare si sbloccano e crescono con la trama.

### HUD

- **Indicatore di carica** del ki, sul bracciale (a forma di foglia) e/o sullo schermo (misuratore circolare minimale).
- Il bracciale è più **pianta** (viticci, muschio, foglie, fiori) che metallo.

## 4. Immagini di riferimento

Concept generati con Canva (IA), non render di Unreal. Servono come riferimento di stile.

- v1, fucina buia con sfera di ki: https://www.canva.com/M/MAHY70-gLuU
- v2, solarpunk, pannello e shuriken: https://www.canva.com/M/MAHY8EQEfQ8
- v3, palmo destro aperto con shuriken verde e arancione, pannello sul dorso della sinistra: https://www.canva.com/M/MAHY8LNnk7g
- v4, come v3, con il bracciale solare più solarpunk (ottone, legno, vetro, muschio): https://www.canva.com/M/MAHY9suEnhQ
- **v5, attuale:** bracciale quasi tutto pianta, indicatore di carica sul bracciale (foglia) e sullo schermo: https://www.canva.com/M/MAHY9r8p7N0
- Menu di creazione del ki (4 slot, forma, colori): https://www.canva.com/M/MAHY9rHvIsY
- Momento del lancio, v1 (scia da togliere): https://www.canva.com/M/MAHY9o6H6I4
- Momento del lancio, v2 (shuriken senza scia): https://www.canva.com/M/MAHY9rfp-ZU

## 5. Decisioni prese

- Motore Godot 4, GDScript, Forward+.
- Prima persona, solo le mani visibili.
- Stile solarpunk, atmosfera luminosa.
- Destra: shuriken di luce sul palmo aperto. Sinistra: pannello solare sul dorso.
- Ki personalizzabile dal menu, 3-4 profili, forma libera, colori scelti dal giocatore.
- Effetto del ki legato alla forma, sia in lancio sia in melee.
- Pannello solare: ricarica il ki, design più solarpunk.
- Gioco narrativo: storia + scoperta dei poteri solarpunk.
- Editor della forma: disegno libero **e** forme base unibili, con assistente che guida verso una forma coerente.
- Carica: aumenta intensità e particelle (grande e piccolo), con tetto massimo.

## 6. Decisioni aperte

- Struttura della storia e del gameplay tra un momento narrativo e l'altro (combattimento, esplorazione, puzzle?).
- Nome definitivo.
- Dettagli della ricarica: velocità col sole, velocità vicino alle fonti, cosa succede al buio.
- Come funziona l'assistente di forma (aggancia ai bordi, suggerisce forme simili, correzione automatica?).
- Mondo: livello chiuso, stanze o mondo aperto.
- Animazioni delle mani necessarie.
- Fonte degli asset (gratis: Quixel, Poly Haven, Kenney; oppure creati a mano).

## 7. Prossimi passi

1. Rispondere alle decisioni aperte e rifare il concept del pannello.
2. Piano a fasi con criteri di completamento, come in `PROGETTO.md`.
3. Prototipo minimo in Godot sul PC: muoversi, mani visibili, shuriken sul palmo.
4. Confronto del prototipo con il concept v3.

## 8. Come riprendere

Alla prossima sessione: "riprendiamo da PROGETTO2.md".
