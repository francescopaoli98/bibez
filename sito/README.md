# Sito Da Bimbo a Bimbo

Pagine: `/` (scelta negozio), `/pistoia`, `/montemurlo`.

## Modificare orari, telefoni, testi
1. Apri `sito/build.py` e cambia la sezione CONFIG.
2. Lancia `python3 sito/build.py`.
3. Commit + push: Cloudflare Pages ripubblica da solo.

## Logo
Metti il logo vero (PNG con sfondo trasparente) in `sito/public/assets/logo.png` e rilancia `build.py`:
sostituisce in automatico il logo segnaposto.

## Cloudflare Pages
- Build command: *(vuoto)*
- Build output directory: `sito/public`
- Poi: Custom domains -> aggiungi il dominio (registrabile direttamente da Cloudflare).
