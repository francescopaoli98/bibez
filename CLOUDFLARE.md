# Gym Coach su Cloudflare, con due account (tu e Irene)

Come funziona:
- L'app sta su `https://<nome>.pages.dev`. Per usarla serve un **account** (nome utente + password). Gli account li crei **solo tu**: non esiste la registrazione.
- Gli account stanno in un piccolo archivio di Cloudflare (**KV**). Le password sono salvate solo come "impronta" (PBKDF2): nemmeno tu le puoi rileggere.
- **I dati (scheda, storico, pesi, chat) restano sul telefono, cifrati con la password.** Su Cloudflare non c'è niente di tuo oltre all'account. Quindi tu **non puoi leggere i dati di Irene**, e lei non può leggere i tuoi.
- **Il coach (Gemini) funziona solo con un account valido.** La chiave di Google sta su Cloudflare come segreto e non arriva mai sul telefono. Ci sono un limite giornaliero per persona e un freno ai tentativi di accesso (10 errori ogni 15 minuti per indirizzo).
- Non serve Cloudflare Access: l'accesso lo gestisce l'app.

Limite onesto: i file dell'app sono pubblici (chiunque può aprire l'indirizzo e vedere la schermata di accesso), ma senza account non entra e non può usare il coach.

> I passaggi sul sito di Cloudflare li ho ricavati dalla documentazione ufficiale ma **non ho accesso al tuo account, quindi non li ho potuti provare**. Il codice del server invece l'ho provato con un archivio finto (accessi, gettoni falsi, limiti, cambio password). Se una voce del menu ha un nome diverso, mandami uno screenshot.

## 1. Crea il progetto Pages
1. dash.cloudflare.com → **Workers & Pages** → **Create application** → scheda **Pages** → **Import an existing Git repository**.
2. Collega GitHub, scegli il repository **bibez** → **Begin setup**.
3. **Project name**: un nome poco indovinabile (diventa l'indirizzo `nome.pages.dev`).
4. **Production branch**: `claude/ai-gym-coach-app-gvnftg`.
5. **Framework preset**: None · **Build command**: `exit 0` · **Build output directory**: `gym-coach` · **Root directory**: vuoto.
6. **Save and Deploy**.

## 2. Crea l'archivio degli account (KV)
1. Workers & Pages → **KV** → **Create a namespace** → nome `gym-coach-app`.
2. Pages → il progetto → **Settings** → **Bindings** → **Add** → **KV namespace** → **Variable name**: `APP` (esattamente così, maiuscolo) → scegli `gym-coach-app` → Save.

## 3. Segreti
Pages → il progetto → **Settings** → **Variables and Secrets** → **Add**, scegliendo **Encrypt** (segreto):
- `GEMINI_API_KEY` = la chiave di https://aistudio.google.com/apikey
- `SESSION_SECRET` = una stringa casuale lunga. La genera la pagina `https://nome.pages.dev/crea-account.html` (punto 2 della pagina → **Genera SESSION_SECRET** → Copia). **Non cambiarla dopo**, o tutti dovranno rifare il login.

Facoltativo (variabile normale): `DAILY_LIMIT` = richieste al giorno per persona (se manca: 300).

Poi **Deployments** → sull'ultimo deploy **Retry deployment**, perché binding e variabili valgono dal deploy successivo.

## 4. Crea i due account
1. Apri `https://nome.pages.dev/crea-account.html` (strumento tuo: la password non esce dalla pagina, che non ha nemmeno accesso a internet).
2. Primo account: nome utente `francesco`, nome da mostrare `Francesco`, la tua password (8+ caratteri) → **Crea le righe**.
3. Compaiono **Key** e **Value**. In Cloudflare: Workers & Pages → **KV** → `gym-coach-app` → **Add entry** → incolla Key e Value → Save.
4. Ripeti con `irene` / `Irene` e la password che le dai.

Cose da sapere:
- **Togliere un account:** cancella la sua riga nel KV: smette di funzionare subito.
- **Rifare la password di un account:** ricrealo con lo strumento mettendo una **Versione più alta** (es. 2) e sostituisci la riga: i vecchi accessi cadono.
- **Cambio password** (lo può fare ognuno dall'app: Impostazioni → Account e sicurezza). Cambia la password dell'account e quella con cui sono cifrati i dati sul telefono.
- Se Irene dimentica la password: tu rifai la riga (versione più alta) per l'accesso, ma i **dati cifrati sul suo telefono non si recuperano** (è proprio il motivo per cui nemmeno tu li puoi leggere). Dovrà cancellarli e ricominciare.

## 5. Prova
1. Apri `https://nome.pages.dev`: deve comparire solo la schermata di **accesso**, non l'app.
2. Entra con `francesco`. Fai la schermata iniziale (non devi mettere nessuna chiave): il coach deve rispondere.
3. In Impostazioni → **Account e sicurezza** controlla che compaia il tuo nome.
4. Prova a entrare con una password sbagliata: deve dare errore, e dopo 10 errori dallo stesso indirizzo deve fermarsi per 15 minuti.
5. Sul telefono di Irene: stesso indirizzo, `irene` + la sua password.

## 6. Spegni la copia pubblica su GitHub
Finché GitHub Pages è attivo, un'altra copia dell'app (senza account) resta su `francescopaoli98.github.io/bibez`.
GitHub → repository `bibez` → **Settings** → **Pages** → **Unpublish site**.

## Se qualcosa non va
- **"Server non configurato"** al login: manca il binding `APP` o il segreto `SESSION_SECRET`, oppure non hai rifatto il deploy.
- **"Proxy non configurato: manca GEMINI_API_KEY"**: manca il segreto della chiave di Gemini.
- **"Nome utente o password sbagliati"** con dati giusti: la riga nel KV non è corretta (Key deve essere `user:` + nome utente minuscolo, es. `user:irene`).
- **"Accesso scaduto"** nella chat: chiudi e riapri l'app e inserisci la password (rinnova da sola l'accesso).
- **429**: troppi tentativi (aspetta 15 minuti) oppure limite giornaliero del coach raggiunto.
