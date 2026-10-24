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
- **Mano sinistra:** un piccolo **pannello solare** agganciato sul **dorso** della mano (lato nocche, non palmo), legato con cinghie in cuoio e cornice in ottone, come un bracciale.

### Il ki (sistema centrale)

Il ki è energia che il giocatore plasma. Lo shuriken è solo l'aspetto di partenza.

| Regola | Decisione |
|---|---|
| Scelta | In un **menu prima della partita** |
| Quantità | Massimo **3-4 ki diversi** salvati |
| Forma | **Libera** (non solo forme predefinite) |
| Colori | **Scelti dal giocatore** (verde e arancione sono solo il default) |
| Dimensione | Scelta dal giocatore |
| Effetto all'impatto | **Cambia con la forma** |
| Usi | **Lancio** (proiettile) e **melee** (corpo a corpo) |
| Costo | Più è grande, più consuma. C'è un **limite massimo** |
| Carica | Vedi sotto |

**Carica (da confermare):**
- Se il ki è già grande: caricare aumenta solo l'**intensità**.
- Se il ki è piccolo: caricare aumenta solo l'**intensità e gli effetti particellari**, non la dimensione.
- Esiste un tetto massimo.

### Idea di implementazione in Godot (da validare)

- Un oggetto dati per ogni ki: `forma`, `dimensione`, `colori`, `intensità`.
- Una sola energia con due comportamenti: lancio (proiettile con scia e impatto) e melee (lama/aura attorno alla mano).
- Danno, raggio e consumo derivano dai parametri.
- Forma libera: da decidere come si disegna nel menu (vedi domande aperte).

## 4. Immagini di riferimento

Concept generati con Canva (IA), non render di Unreal. Servono come riferimento di stile.

- v1, fucina buia con sfera di ki: https://www.canva.com/M/MAHY70-gLuU
- v2, solarpunk, pannello e shuriken: https://www.canva.com/M/MAHY8EQEfQ8
- **v3, attuale:** palmo destro aperto con shuriken verde e arancione, pannello sul dorso della sinistra: https://www.canva.com/M/MAHY8LNnk7g

## 5. Decisioni prese

- Motore Godot 4, GDScript, Forward+.
- Prima persona, solo le mani visibili.
- Stile solarpunk, atmosfera luminosa.
- Destra: shuriken di luce sul palmo aperto. Sinistra: pannello solare sul dorso.
- Ki personalizzabile dal menu, 3-4 profili, forma libera, colori scelti dal giocatore.
- Effetto del ki legato alla forma, sia in lancio sia in melee.

## 6. Decisioni aperte

- Genere e loop base del gioco (cosa si fa nei primi 5 minuti).
- Nome definitivo.
- Cosa fa il pannello solare nel gameplay (ricarica il ki? scudo? luce?).
- Come si disegna la forma libera nel menu (disegno a mano, punti e curve, forme combinabili).
- Mondo: livello chiuso, stanze o mondo aperto.
- Animazioni delle mani necessarie.
- Fonte degli asset (gratis: Quixel, Poly Haven, Kenney; oppure creati a mano).
- Conferma delle regole di carica (sezione 3).

## 7. Prossimi passi

1. Rispondere alle decisioni aperte.
2. Piano a fasi con criteri di completamento, come in `PROGETTO.md`.
3. Prototipo minimo in Godot sul PC: muoversi, mani visibili, shuriken sul palmo.
4. Confronto del prototipo con il concept v3.

## 8. Come riprendere

Alla prossima sessione: "riprendiamo da PROGETTO2.md".
