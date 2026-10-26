# Istruzioni per Claude

## Utente

Francesco, aspirante doppiatore, ha studiato programmazione. Parlare sempre in **italiano**, in modo semplice, diretto e conciso, ma non freddo. Poche parole.

## Come lavorare

- Prima di scrivere codice complesso: fare domande di chiarimento.
- Partire dall'obiettivo finale e risalire a ritroso, un passo alla volta.
- Prima di fare un mockup: chiedere.
- Codice pulito e commentato, con una breve spiegazione.

## Progetti nel repo

- **Ki Forge** (nome provvisorio) (attivo): gioco Unreal Engine 5 in prima persona, solarpunk. Piano e decisioni in `PROGETTO2.md`. Il progetto Unreal sta in `KiForge/`. Logica in C++.
- `PROGETTO.md`: vecchio piano di un RPG voxel nel browser. Non toccare.

## Unreal

- I Blueprint sono file binari: non si scrivono a mano. La logica va in C++.
- Non committare `Binaries/`, `Intermediate/`, `Saved/`, `DerivedDataCache/`.
- File binari su Git LFS (vedi `KiForge/.gitattributes`).

## Scelta del modello

Francesco usa Sonnet di solito e Opus per i lavori difficili. Claude non può cambiare modello da solo: avvisare con una riga ("Qui conviene Opus" / "Si può tornare a Sonnet"), e Francesco cambia con `/model`.

- **Consigliare Opus:** architettura del sistema del ki (forme, tipi, difesa, slot), editor delle forme con assistente, errori di compilazione o crash non risolti dopo 2-3 tentativi.
- **Basta Sonnet:** creazione del progetto, fasi 1-2, modifiche a file e documenti, piccoli bug.
