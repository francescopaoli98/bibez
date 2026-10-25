# Preparare il PC (una volta sola)

Tutto gratis. Spazio libero consigliato: almeno **100 GB**.

## 1. Programmi da installare

1. **Git** con **Git LFS**: https://git-scm.com (LFS è incluso nell'installer).
2. **Epic Games Launcher**: https://www.unrealengine.com, poi installa **Unreal Engine 5.x** (ultima stabile) dalla scheda "Unreal Engine". Pesa oltre 50 GB.
3. **Visual Studio 2022 Community**: https://visualstudio.microsoft.com. Nel installer spunta:
   - **Sviluppo di giochi con C++**
   - nei dettagli: **Unreal Engine installer** e **Windows 10/11 SDK**
4. **Claude Code** (app Desktop o terminale) per lavorare in locale.

## 2. Scaricare il repo

Apri un terminale in una cartella a tua scelta:

```
git lfs install
git clone https://github.com/francescopaoli98/bibez.git
cd bibez
git checkout ccr-964231ef-5pl7lu
```

## 3. Aprire Claude in locale

Dentro la cartella `bibez`:
- **App Desktop:** apri la cartella `bibez`.
- **Terminale:** lancia `claude`.

Poi scrivi: "riprendiamo da PROGETTO2.md, fase 1".

## 4. Creare il progetto Unreal (lo facciamo insieme)

Nella fase 1 creiamo il progetto C++ **dentro `Keyforge/`**: modello **Prima persona**, linguaggio **C++**, qualità Massima, senza contenuti iniziali non necessari.

## Controlli finali

- [ ] `git lfs version` risponde
- [ ] Unreal Engine 5 si apre dal Launcher
- [ ] Visual Studio ha il carico di lavoro C++ per i giochi
- [ ] Claude Code si apre nella cartella `bibez`
