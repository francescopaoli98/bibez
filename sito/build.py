#!/usr/bin/env python3
"""
Genera il sito "Da Bimbo a Bimbo" (hub + Pistoia + Montemurlo).

Come si usa:
    python3 sito/build.py

Cosa modificare per aggiornare il sito: SOLO la sezione CONFIG qui sotto
(orari, telefoni, indirizzi, social, testi). Poi rilancia lo script:
le pagine vengono rigenerate in sito/public/.
"""
import json
import os
from datetime import date
from urllib.parse import quote

# ---------------------------------------------------------------------------
# CONFIG  (tutto quello che puoi voler cambiare sta qui)
# ---------------------------------------------------------------------------
DOMINIO = "https://dabimboabimbo.it"      # TODO: da confermare quando scegliamo il dominio
PIVA = "[P.IVA da inserire]"             # TODO: obbligatoria per legge sui siti commerciali
GIORNI = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]


def orari(mat, pom):
    """Orari standard: Lun-Mar e Gio-Ven mattina+pomeriggio, Mer e Sab solo mattina, Dom chiuso."""
    due = [mat, pom]
    una = [mat]
    return [due, due, una, due, due, una, []]


NEGOZI = {
    "pistoia": {
        "slug": "pistoia",
        "citta": "Pistoia",
        "nome": "Da Bimbo a Bimbo Pistoia",
        "via": "Via Monteverdi 41/43",
        "cap": "51100",
        "prov": "PT",
        "tel": "388 460 9872",
        "whatsapp": "393884609872",        # solo cifre, con prefisso 39
        "email": "dabimboabimbo-pt@libero.it",
        "facebook": "",                     # TODO: link pagina Facebook (se vuoto il bottone sparisce)
        "instagram": "",                    # TODO: link Instagram (se vuoto sparisce)
        "orari": orari(("09:00", "12:30"), ("15:00", "19:00")),
    },
    "montemurlo": {
        "slug": "montemurlo",
        "citta": "Montemurlo",
        "nome": "Da Bimbo a Bimbo Montemurlo",
        "via": "Via Oste 171/173",
        "cap": "59013",
        "prov": "PO",
        "tel": "392 576 0929",
        "whatsapp": "393925760929",
        "email": "dabimboabimbo@libero.it",
        "facebook": "",
        "instagram": "",
        "orari": orari(("09:30", "12:30"), ("15:30", "19:00")),
    },
}

# Testi "Come funziona" (DA CONFERMARE con voi: sono segnaposto sensati)
PASSI = [
    ("Prenota", "Scegli giorno e ora qui sotto: ti aspettiamo con calma, senza code."),
    ("Porta i tuoi capi", "Puliti, in buono stato e di stagione."),
    ("Li valutiamo insieme", "Ti diciamo subito cosa possiamo ritirare e come."),
]

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public")


# ---------------------------------------------------------------------------
# Utilità
# ---------------------------------------------------------------------------
def fmt(h):
    """'09:00' -> '9:00'"""
    return h.lstrip("0") if h.startswith("0") else h


def righe_orari(s):
    out = []
    for i, nome in enumerate(GIORNI):
        iv = s["orari"][i]
        testo = " · ".join(f"{fmt(a)}–{fmt(b)}" for a, b in iv) if iv else "Chiuso"
        cls = "" if iv else ' class="chiuso"'
        out.append(f'<tr data-day="{i}"{cls}><th scope="row">{nome}</th><td>{testo}</td></tr>')
    return "\n".join(out)


def jsonld(s):
    spec = []
    nomi_en = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    for i, iv in enumerate(s["orari"]):
        for a, b in iv:
            spec.append({"@type": "OpeningHoursSpecification", "dayOfWeek": nomi_en[i], "opens": a, "closes": b})
    data = {
        "@context": "https://schema.org",
        "@type": "Store",
        "name": s["nome"],
        "description": f"Mercatino dell'usato per bambini a {s['citta']}.",
        "url": f"{DOMINIO}/{s['slug']}",
        "telephone": "+" + s["whatsapp"],
        "email": s["email"],
        "address": {
            "@type": "PostalAddress",
            "streetAddress": s["via"],
            "postalCode": s["cap"],
            "addressLocality": s["citta"],
            "addressRegion": s["prov"],
            "addressCountry": "IT",
        },
        "openingHoursSpecification": spec,
    }
    sameas = [u for u in (s["facebook"], s["instagram"]) if u]
    if sameas:
        data["sameAs"] = sameas
    return json.dumps(data, ensure_ascii=False)


def dati_js(negozi):
    """Dati minimi per lo script (orari + whatsapp + nome)."""
    return json.dumps(
        {
            n["slug"]: {"nome": n["nome"], "citta": n["citta"], "wa": n["whatsapp"], "orari": n["orari"]}
            for n in negozi
        },
        ensure_ascii=False,
    )


def logo(piccolo=False):
    """Usa assets/logo.png se esiste, altrimenti un logo SEGNAPOSTO in SVG."""
    if os.path.exists(os.path.join(OUT, "assets", "logo.png")):
        return '<img src="/assets/logo.png" alt="Da Bimbo a Bimbo" class="logo-img">'
    # Nuvola: cerchi navy (bordo) sotto, cerchi bianchi sopra
    xs = list(range(44, 340, 38))
    def cerchi(r, fill):
        c = [f'<circle cx="{x}" cy="34" r="{r}" fill="{fill}"/><circle cx="{x}" cy="86" r="{r}" fill="{fill}"/>' for x in xs]
        c.append(f'<circle cx="34" cy="60" r="{r+8}" fill="{fill}"/><circle cx="346" cy="60" r="{r+8}" fill="{fill}"/>')
        c.append(f'<rect x="34" y="34" width="312" height="52" fill="{fill}"/>')
        return "".join(c)
    return f"""<svg class="logo-svg" viewBox="0 0 380 120" role="img" aria-label="Da Bimbo a Bimbo">
  <defs><linearGradient id="lg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1d9bd9"/><stop offset="1" stop-color="#8fd8f6"/></linearGradient></defs>
  {cerchi(29, "#1b2a7b")}{cerchi(23, "#ffffff")}
  <text x="190" y="75" text-anchor="middle" font-family="'Fira Sans Condensed',sans-serif" font-weight="700" font-size="46"
        fill="url(#lg)" stroke="#1b2a7b" stroke-width="2.2" paint-order="stroke">Da bimbo a bimbo</text>
</svg>"""


def head(titolo, descr, url, extra=""):
    return f"""<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{titolo}</title>
<meta name="description" content="{descr}">
<meta name="theme-color" content="#1b2a7b">
<link rel="canonical" href="{url}">
<meta property="og:type" content="website">
<meta property="og:title" content="{titolo}">
<meta property="og:description" content="{descr}">
<meta property="og:url" content="{url}">
<meta property="og:locale" content="it_IT">
<link rel="preload" href="/assets/fonts/fira-cond-700.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="/assets/style.css">
{extra}
</head>"""


def footer(negozi):
    link = " · ".join(f'<a href="/{n["slug"]}">{n["citta"]}</a>' for n in negozi.values())
    return f"""<footer class="footer">
  <div class="wrap">
    <div class="footer-logo">{logo()}</div>
    <p>Mercatino dell'usato · {link}</p>
    <p class="piccolo">© {date.today().year} Da Bimbo a Bimbo · {PIVA}<br>
    Questo sito non usa cookie e non salva i tuoi dati: le richieste di appuntamento partono direttamente da WhatsApp.</p>
  </div>
</footer>
<script src="/assets/site.js" defer></script>"""


# ---------------------------------------------------------------------------
# Pagina negozio
# ---------------------------------------------------------------------------
def pagina_negozio(s):
    indirizzo = f'{s["via"]}, {s["cap"]} {s["citta"]} ({s["prov"]})'
    maps_q = quote(f'{s["via"]}, {s["cap"]} {s["citta"]}')
    maps_dir = f"https://www.google.com/maps/dir/?api=1&destination={maps_q}"
    maps_embed = f"https://www.google.com/maps?q={maps_q}&output=embed"
    tel_href = "tel:+" + s["whatsapp"]
    wa_href = f'https://wa.me/{s["whatsapp"]}?text=' + quote(f'Ciao! Vorrei informazioni su {s["nome"]}.')
    altro = next(n for n in NEGOZI.values() if n["slug"] != s["slug"])

    social = ""
    if s["facebook"]:
        social += f'<a class="btn btn-ghost" href="{s["facebook"]}" target="_blank" rel="noopener">Facebook</a>'
    if s["instagram"]:
        social += f'<a class="btn btn-ghost" href="{s["instagram"]}" target="_blank" rel="noopener">Instagram</a>'

    passi = "".join(
        f'<li><span class="num">{i}</span><div><h3>{t}</h3><p>{d}</p></div></li>' for i, (t, d) in enumerate(PASSI, 1)
    )

    h = head(
        f'{s["nome"]} · Mercatino dell\'usato per bambini',
        f'Mercatino dell\'usato per bambini a {s["citta"]}: orari, indirizzo, contatti e prenotazione appuntamento. {s["via"]}.',
        f'{DOMINIO}/{s["slug"]}',
        f'<script type="application/ld+json">{jsonld(s)}</script>',
    )
    return f"""{h}
<body class="store store-{s["slug"]}">
<header class="top">
  <div class="wrap top-in">
    <a class="top-logo" href="/" aria-label="Da Bimbo a Bimbo – home">{logo(True)}</a>
    <a class="top-link" href="/">Cambia negozio</a>
  </div>
</header>

<main>
<section class="hero">
  <div class="wrap hero-in">
    <p class="eyebrow">Mercatino dell'usato per bambini</p>
    <h1>Da Bimbo a Bimbo <span>{s["citta"]}</span></h1>
    <p class="badge" data-store="{s["slug"]}" aria-live="polite">Controllo gli orari…</p>
    <div class="cta">
      <a class="btn btn-primary" href="{tel_href}">📞 Chiama</a>
      <a class="btn btn-wa" href="{wa_href}" target="_blank" rel="noopener">💬 WhatsApp</a>
      <a class="btn btn-light" href="{maps_dir}" target="_blank" rel="noopener">📍 Indicazioni</a>
    </div>
  </div>
</section>

<div class="wrap stack">
<div class="col">
  <section class="card" id="orari">
    <h2>Orari del negozio</h2>
    <table class="orari"><tbody>
{righe_orari(s)}
    </tbody></table>
  </section>

  <section class="card" id="come-funziona">
    <h2>Come funziona</h2>
    <ol class="passi">{passi}</ol>
  </section>

  <section class="card" id="contatti">
    <h2>Contatti</h2>
    <ul class="contatti">
      <li><span>Telefono / WhatsApp</span><a href="{tel_href}">{s["tel"]}</a></li>
      <li><span>Email</span><a href="mailto:{s["email"]}">{s["email"]}</a></li>
    </ul>
    <div class="cta-row">{social}</div>
  </section>
</div>
<div class="col">
  <section class="card card-accent" id="appuntamento">
    <h2>Prenota un appuntamento</h2>
    <p class="sub">Scegli giorno e ora: ti si apre WhatsApp con il messaggio già pronto, devi solo premere invio.</p>
    <form id="prenota" data-store="{s["slug"]}" novalidate>
      <label>Il tuo nome
        <input type="text" name="nome" autocomplete="given-name" placeholder="Es. Giulia" required>
      </label>
      <div class="riga">
        <label>Giorno
          <input type="date" name="data" required>
        </label>
        <label>Ora
          <select name="ora" required disabled><option value="">Scegli prima il giorno</option></select>
        </label>
      </div>
      <p class="avviso" role="status" aria-live="polite"></p>
      <button class="btn btn-wa btn-big" type="submit">💬 Richiedi su WhatsApp</button>
    </form>
  </section>

  <section class="card" id="dove">
    <h2>Dove siamo</h2>
    <p class="indirizzo"><strong>{s["via"]}</strong><br>{s["cap"]} {s["citta"]} ({s["prov"]})</p>
    <div class="mappa" data-src="{maps_embed}">
      <button type="button" class="btn btn-ghost mappa-carica">🗺️ Mostra la mappa</button>
      <small>La mappa è di Google e si carica solo se premi il pulsante.</small>
    </div>
    <p><a class="btn btn-primary" href="{maps_dir}" target="_blank" rel="noopener">📍 Portami lì</a></p>
  </section>


</div>

  <section class="altro">
    <p>Cerchi l'altro negozio?</p>
    <a class="btn btn-light-navy" href="/{altro["slug"]}">Da Bimbo a Bimbo {altro["citta"]} →</a>
  </section>

</div>
</main>

<nav class="sticky" aria-label="Azioni rapide">
  <a href="{tel_href}">📞<span>Chiama</span></a>
  <a href="{wa_href}" target="_blank" rel="noopener">💬<span>WhatsApp</span></a>
  <a href="{maps_dir}" target="_blank" rel="noopener">📍<span>Indicazioni</span></a>
</nav>

{footer(NEGOZI)}
<script type="application/json" id="dati">{dati_js([s])}</script>
</body>
</html>
"""


# ---------------------------------------------------------------------------
# Pagina hub (scelta negozio)
# ---------------------------------------------------------------------------
def pagina_hub():
    cards = ""
    for s in NEGOZI.values():
        cards += f"""
    <article class="negozio negozio-{s["slug"]}">
      <div class="negozio-top"><h2>{s["citta"]}</h2></div>
      <div class="negozio-body">
        <p class="badge" data-store="{s["slug"]}" aria-live="polite">Controllo gli orari…</p>
        <p class="indirizzo">{s["via"]}<br>{s["cap"]} {s["citta"]} ({s["prov"]})</p>
        <a class="btn btn-primary btn-big" href="/{s["slug"]}">Vai al negozio →</a>
        <a class="link-tel" href="tel:+{s["whatsapp"]}">📞 {s["tel"]}</a>
      </div>
    </article>"""

    h = head(
        "Da Bimbo a Bimbo · Mercatino dell'usato per bambini · Pistoia e Montemurlo",
        "Mercatino dell'usato per bambini a Pistoia e Montemurlo (Prato). Scegli il tuo negozio: orari, contatti e appuntamenti.",
        DOMINIO + "/",
    )
    return f"""{h}
<body class="hub">
<main>
<section class="hero hero-hub">
  <div class="wrap hero-in">
    <div class="hub-logo">{logo()}</div>
    <h1>Mercatino dell'usato<br><span>per bambini</span></h1>
    <p class="lead">Scegli il tuo negozio</p>
  </div>
</section>

<div class="wrap">
  <div class="negozi">{cards}
  </div>
</div>
</main>
{footer(NEGOZI)}
<script type="application/json" id="dati">{dati_js(list(NEGOZI.values()))}</script>
</body>
</html>
"""


# ---------------------------------------------------------------------------
def scrivi(percorso, contenuto):
    p = os.path.join(OUT, percorso)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(contenuto)
    print("ok ", os.path.relpath(p))


if __name__ == "__main__":
    scrivi("index.html", pagina_hub())
    for s in NEGOZI.values():
        scrivi(f"{s['slug']}/index.html", pagina_negozio(s))
    scrivi("robots.txt", f"User-agent: *\nAllow: /\nSitemap: {DOMINIO}/sitemap.xml\n")
    urls = ["/"] + [f"/{s}" for s in NEGOZI]
    scrivi(
        "sitemap.xml",
        '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "".join(f"  <url><loc>{DOMINIO}{u}</loc></url>\n" for u in urls)
        + "</urlset>\n",
    )
    scrivi(
        "_headers",
        "/*\n  X-Content-Type-Options: nosniff\n  Referrer-Policy: strict-origin-when-cross-origin\n"
        "  X-Frame-Options: DENY\n/assets/*\n  Cache-Control: public, max-age=31536000, immutable\n",
    )
