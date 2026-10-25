# Ki Forge (nome provvisorio)

Gioco per PC, costi il più possibile a zero. Questo file è il piano del progetto.
Il vecchio piano (RPG voxel nel browser) resta in `PROGETTO.md`, non toccato.
Il progetto Unreal sta nella cartella `KiForge/` (nome provvisorio, senza spazio per Unreal).

## 1. Come lavorare insieme

- Sempre in italiano, semplice e diretto, poche parole.
- Codice pulito e commentato, con una breve spiegazione.
- Prima di scrivere codice complesso: domande di chiarimento.
- Si parte dall'obiettivo finale e si risale a ritroso, un passo alla volta.
- Prima di fare un mockup: chiedere.

## 2. Tecnica

| Voce | Scelta |
|---|---|
| Motore | **Unreal Engine 5** (stabile). Godot valutato, scartato per il realismo |
| Linguaggio | **C++** (scritto da Claude, file di testo). Gli asset binari (mappe, materiali, Niagara) li crea Claude con script Python dell'editor o li fai tu |
| Renderer | Lumen, Nanite (default di UE5) |
| PC di sviluppo | RTX 3060, 16 GB RAM |
| Pubblicazione | prima itch.io (gratis), poi eventualmente Steam |
| Grafica | realistica, prima persona, si vedono solo le mani |
| Piattaforma | PC (non Android) |

Nota: il container cloud dove lavora Claude non ha GPU né Unreal. Compilazione e prova si fanno sul PC di Francesco.

**Metodo di lavoro con Unreal:**
- Claude scrive C++ e script Python dell'editor, e li pusha nel repo.
- Francesco compila, apre il progetto e prova. Manda screenshot ed errori.
- Gli asset realistici (mani, ambiente) si prendono gratis da Fab e Quixel.
- Git: serve Git LFS per i file binari di Unreal.

## 3. Idea di gioco

Prima persona, si vedono solo mani e avambracci. Ambientazione **solarpunk**:
città verde, piante sospese, turbine eoliche, architettura bianca e curva, luce dorata.

### Mani

- **Mano destra:** palmo aperto verso l'alto. Sopra il palmo galleggia il **ki**, fatto di pura luce. La forma di partenza è uno shuriken, ma può cambiare.
- **Mano sinistra:** un piccolo **pannello solare** agganciato sul **dorso** della mano (lato nocche, non palmo), come un bracciale.
  - **Funzione:** **ricarica il ki**, stando alla luce del **sole** e vicino a **fonti di energia** sparse nel mondo.
  - **Materiali:** misto (ottone, legno intagliato, vetro, muschio e fiori vivi).
  - **Design:** deve essere un oggetto ancora **più solarpunk** del concept v3 (da rifare: più organico, con piante, legno, vetro, fiori).

### Il ki (sistema centrale)

Il ki è energia che il giocatore plasma, quindi **qualsiasi forma si può modificare**. Lo shuriken è solo la forma di partenza (default), non un oggetto fisso.

| Regola | Decisione |
|---|---|
| Scelta | Solo nel **menu prima della partita**. La forma **non si cambia durante il gioco**, ma si può **passare da un ki all'altro** |
| Quantità | **3 ki** di base. Si sale fino a **5** con certi **powerup**, che sono **fiori di cristallo nascosti nel mondo** da trovare |
| Forma | **Libera**: si disegna a mano oppure si uniscono forme base. Un **assistente** aiuta a ottenere una forma vicina a quello che il giocatore ha fatto, senza stravolgerla |
| Colori | **Scelti dal giocatore** (verde e arancione sono solo il default) |
| Dimensione | Scelta dal giocatore |
| Effetto all'impatto | **Cambia con la forma** |
| Melee | Il ki melee deve essere **impugnabile** (come un'arma). Se la forma non si può impugnare (es. uno shuriken), funziona **a corto raggio con un'animazione tipo yo-yo**: parte vicino e torna alla mano |
| Scia | Dipende dalla forma del ki: la forma shuriken non ha scia. La scia o il raggio compaiono solo se la forma è un raggio. Ogni forma ha il suo comportamento |
| Usi | Ogni ki ha un **tipo di utilizzo**: **lancio** (proiettile) oppure **melee** (pugno di ki). Il tipo si sceglie **nel menu**, per ogni ki. Decide cosa fa il clic sinistro, **non la distanza dal bersaglio** |
| Costo | Più è grande, più consuma. C'è un **limite massimo** |
| Carica | Vedi sotto |

**Carica (confermato):**
- Caricare aumenta **intensità ed effetti particellari**, sia per ki grande sia per ki piccolo.
- La dimensione la decide il menu, non la carica.
- Esiste un tetto massimo.

### Idea di implementazione in Unreal (da validare)

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

### Comandi per cambiare ki

| Tasto | Azione |
|---|---|
| **1 2 3 4 5** | Scelta diretta dello slot (4 e 5 solo se sbloccati con i fiori di cristallo) |
| **Q / E** | Ki precedente / successivo |
| **Rotella del mouse** | Ki precedente / successivo (alternativa a Q/E) |

### Comandi di combattimento

| Tasto | Azione |
|---|---|
| **Clic sinistro** | Usa il ki. Se il ki è di tipo **lancio**, lo lancia anche da vicino. Se è di tipo **melee**, tira il pugno anche da lontano |
| **Tieni premuto il clic sinistro** | Carica il ki |
| **Clic destro** | Difesa (vedi sezione Difesa) |

Gamepad: rimandato a dopo.

### Difesa (clic destro)

Due modi di difendersi:

| Modo | Effetto |
|---|---|
| **Difesa con ki** | Protezione migliore, con **bonus** (parry e simili) |
| **Difesa senza ki** | Protegge il giocatore al minimo, ma con **malus** |

**Perché:** i malus senza ki servono a spingere il giocatore a usare il ki anche per difendersi. Altrimenti si attacca soltanto e si para sempre senza ki.

**Ki di difesa:**
- Sono un tipo di ki a parte, diverso da quello d'attacco.
- All'inizio c'è **un solo tipo di difesa**. Altri si sbloccano più avanti.
- La difesa può avere **forme e comportamenti diversi**: attaccata al corpo, spostabile, ancorata al terreno e così via.
- Deve essere progettata in modo **molto intelligente** (bilanciamento e varietà).

**Slot (da chiarire):** 3 ki d'attacco. Per la difesa, 3-4 utilizzi al massimo con gli sblocchi successivi.

Gli slot non sbloccati vengono saltati. Tasti da rivedere quando si decidono gli altri comandi (WASD, salto, lancio, melee).

## 5. Decisioni prese

- Motore Unreal Engine 5, gameplay in C++. Claude gestisce il progetto.
- Prima persona, solo le mani visibili.
- Stile solarpunk, atmosfera luminosa.
- Destra: ki sul palmo aperto (forma di partenza: shuriken). Sinistra: pannello solare sul dorso.
- Ki personalizzabile solo dal menu prima della partita, 3 profili (fino a 5 con powerup), forma libera, colori scelti dal giocatore.
- Effetto del ki legato alla forma, sia in lancio sia in melee.
- Pannello solare: ricarica il ki, design più solarpunk.
- Tipo di utilizzo del ki (lancio o melee) scelto nel menu per ogni ki, non dipende dalla distanza.
- Ki melee: impugnabile, oppure yo-yo a corto raggio se la forma non si impugna.
- Comandi: clic sinistro per usare il ki (lancio o melee secondo il tipo) (tenuto premuto carica), clic destro per la difesa base.
- Cambio ki in gioco: tasti 1-5, Q/E e rotella del mouse.
- Ordine delle fasi: menu del ki (5) prima del mondo (7).
- Gioco narrativo: storia + scoperta dei poteri solarpunk.
- Editor della forma: disegno libero **e** forme base unibili, con assistente che guida verso una forma coerente.
- Carica: aumenta intensità e particelle (grande e piccolo), con tetto massimo.

## 6. Decisioni aperte

- Struttura esatta degli slot: i 5 slot (3 + 2 fiori di cristallo) sono solo d'attacco o includono la difesa? I ki di difesa hanno slot separati?
- Come si sbloccano i ki di difesa successivi.
- Come si seleziona il ki di difesa in gioco (tasti diversi da 1-5?).
- Bonus e malus precisi della difesa con e senza ki.
- Come il gioco rende impugnabile una forma melee: aggiunge un manico, sceglie lui tra impugnatura e yo-yo, o lo decide il giocatore?
- Come funziona la difesa base (scudo di ki, pannello solare, parata) e se consuma ki.
- Dove sono nascosti i fiori di cristallo degli slot 4 e 5 e quanto sono difficili da trovare.
- Struttura della storia e del gameplay tra un momento narrativo e l'altro (combattimento, esplorazione, puzzle?).
- Nome definitivo.
- Dettagli della ricarica: velocità col sole, velocità vicino alle fonti, cosa succede al buio.
- Come funziona l'assistente di forma (aggancia ai bordi, suggerisce forme simili, correzione automatica?).
- Mondo: livello chiuso, stanze o mondo aperto.
- Animazioni delle mani necessarie.
- Fonte degli asset (gratis: Quixel, Poly Haven, Kenney; oppure creati a mano).

## 7. Piano a fasi (bozza)

Una fase alla volta, verificando ciascuna prima di passare alla successiva.

| Fase | Contenuto | Fatto quando |
|---|---|---|
| 1 | Progetto Unreal, prima persona, camera, movimento, mani visibili | Ti muovi e vedi le mani in una scena di prova |
| 2 | Ki sul palmo destro: forma di partenza shuriken, luce e particelle | Il ki galleggia e brilla in verde e arancione |
| 3 | Lancio e melee, effetto che cambia con la forma | Lanci e colpisci, e forme diverse si comportano in modo diverso |
| 4 | Pannello solare, carica del ki, HUD (foglia sul bracciale, misuratore) | Il ki si ricarica col sole e l'HUD mostra la carica |
| 5 | Menu del ki: 3 slot, forme libere o unite, assistente, colori | Crei 3 ki, li salvi e li ritrovi in gioco |
| 6 | Cambio ki in gioco e slot 4-5 con i fiori di cristallo | Trovi un fiore e sblocchi uno slot |
| 7 | Mondo solarpunk, fonti di energia, storia | C'è un percorso narrato con poteri da scoprire |
| 8 | Salvataggio e rifiniture | La partita si riprende dopo la chiusura |

**Traguardo consigliato:** fasi 1-3, il nucleo giocabile.
Prototipo da confrontare con il concept v5.

## 8. Come riprendere

Alla prossima sessione: "riprendiamo da PROGETTO2.md".
