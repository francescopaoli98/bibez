# Gym Coach su Cloudflare (con login e Gemini nascosto)

Obiettivo: l'app sta su `https://<nome>.pages.dev`, **solo chi è autorizzato può aprirla** (login con email + codice)
e **la chiave di Gemini resta sul server**, mai sul telefono.

Come è fatta:
- `gym-coach/` = l'app (file statici).
- `functions/api/gemini/[[path]].js` = il proxy verso Gemini. Controlla il login di Cloudflare Access, poi inoltra la richiesta a Google con la chiave segreta. Non salva nessun testo.
- `gym-coach/_routes.json` = fa girare il proxy solo per gli indirizzi `/api/*`.

> I passaggi sul sito di Cloudflare li ho ricavati dalla documentazione ufficiale (letta il 08/11/2026) ma **non ho accesso al tuo account, quindi non li ho potuti provare**. Se una voce del menu ha un nome diverso, mandami uno screenshot.

## 1. Crea il progetto Pages
1. dash.cloudflare.com → **Workers & Pages** → **Create application** → scheda **Pages** → **Import an existing Git repository**.
2. Collega GitHub e scegli il repository **bibez** → **Begin setup**.
3. **Project name**: scegli un nome poco indovinabile (diventa l'indirizzo: `nome.pages.dev`).
4. **Production branch**: `claude/ai-gym-coach-app-gvnftg` (quando unirai il lavoro a un branch principale, cambialo).
5. **Framework preset**: None · **Build command**: `exit 0` · **Build output directory**: `gym-coach` · **Root directory**: lascialo vuoto.
6. **Save and Deploy**. Alla fine hai l'indirizzo `https://nome.pages.dev` (ancora aperto a tutti: lo proteggiamo al punto 3).

## 2. Metti la chiave di Gemini come segreto
1. Crea la chiave su https://aistudio.google.com/apikey (se non ce l'hai già).
2. Pages → il tuo progetto → **Settings** → **Variables and Secrets** → **Add**.
3. Nome `GEMINI_API_KEY`, valore = la chiave, scegli **Encrypt** (segreto) → **Save**.

## 3. Proteggi il sito con Cloudflare Access
1. dash.cloudflare.com → **Zero Trust**. La prima volta ti chiede un "team name" (es. `francesco-gym`): il tuo indirizzo di accesso diventa `francesco-gym.cloudflareaccess.com` (**annotalo**: è `ACCESS_TEAM_DOMAIN`). Scegli il piano **Free** (fino a 50 persone).
2. Pages → il progetto → **Settings** → **General** → attiva **Enable access policy**.
   Questo protegge solo le versioni di anteprima. Per proteggere anche `nome.pages.dev` (dalla documentazione di Cloudflare, "Known issues"):
   - Zero Trust → **Access controls** → **Applications** → apri l'applicazione del tuo progetto → **Configure**.
   - Alla voce **Public hostname**, nel campo **Subdomain** cancella l'asterisco `*` → **Save**.
   - Torna in Pages → Settings → General e riattiva **Enable access policy**.
   - Controlla che in Applications ce ne siano due: una per `nome.pages.dev`, una per le anteprime.
3. Nell'applicazione di `nome.pages.dev` → **Policies** → crea una policy **Allow** con **Include → Emails** e inserisci le email autorizzate: la tua (`f.paolidub@gmail.com`) e quella di Irene.
   - Il login usa **One-time PIN**: arriva un codice **via email** (non esiste l'SMS). Irene quindi ha bisogno di un'email.
   - In **Session duration** metti 1 mese, così non devi rifare il login ogni giorno.
4. Nella stessa applicazione → **Overview** → copia l'**Application Audience (AUD) Tag** (è `ACCESS_AUD`).

## 4. Collega il proxy al login
Pages → il progetto → **Settings** → **Variables and Secrets** → **Add** (tipo normale, non segreto):

| Nome | Valore |
|---|---|
| `ACCESS_TEAM_DOMAIN` | es. `francesco-gym.cloudflareaccess.com` |
| `ACCESS_AUD` | l'AUD Tag del punto 3.4 |
| `ALLOWED_EMAILS` | `f.paolidub@gmail.com,email-di-irene@…` (separate da virgola) |

Il proxy rifiuta tutto se questi valori mancano o se il login non è valido: non resta mai aperto per errore.

**Facoltativo, limite giornaliero per persona** (per non esaurire la tua quota Gemini):
1. Workers & Pages → **KV** → **Create a namespace** → nome `RATE`.
2. Pages → il progetto → **Settings** → **Bindings** → **Add** → **KV namespace** → Variable name `RATE`, scegli il namespace.
3. Aggiungi la variabile `DAILY_LIMIT` (es. `150`). Senza, il limite è 300 richieste al giorno per persona.

## 5. Rifai il deploy e prova
1. Pages → **Deployments** → sull'ultimo deploy **Retry deployment** (le variabili valgono dal deploy successivo).
2. Apri `https://nome.pages.dev` in una finestra privata: deve comparire la pagina di Cloudflare che chiede l'email → arriva il codice → entri nell'app.
3. Nell'app: **Impostazioni** → "Coach IA" → **Coach condiviso** → **Prova collegamento**. Deve dire "Collegamento riuscito".
4. Prova con un'email NON autorizzata: non deve ricevere il codice.

## 6. Spegni la copia pubblica su GitHub
Finché GitHub Pages è attivo, l'app resta aperta anche su `francescopaoli98.github.io/bibez`.
GitHub → repository `bibez` → **Settings** → **Pages** → **Unpublish site**.
(Non contiene i tuoi dati né chiavi, ma non c'è motivo di lasciarla in giro. Sulla copia GitHub il coach non funziona senza chiave propria.)

## Se qualcosa non va
- **"Accesso non autorizzato" (401)** nell'app: `ACCESS_TEAM_DOMAIN` o `ACCESS_AUD` sbagliati, oppure l'indirizzo non è coperto dall'applicazione Access (ripeti il punto 3.2). Ricarica l'app per rifare il login.
- **"Proxy non configurato"**: manca `GEMINI_API_KEY` (punto 2) o non hai rifatto il deploy.
- **403 "Questa email non è autorizzata"**: l'email non è in `ALLOWED_EMAILS`.
- **429**: limite giornaliero raggiunto.
- Se il manifest o l'icona non si caricano dopo il login, svuota la cache del browser e riapri.
