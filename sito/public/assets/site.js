/* Da Bimbo a Bimbo – logica del sito (nessuna dipendenza, nessun cookie) */
(() => {
  "use strict";
  const GIORNI = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"];
  const NEGOZI = JSON.parse(document.getElementById("dati").textContent);

  const toMin = (h) => { const [a, b] = h.split(":").map(Number); return a * 60 + b; };
  const fmt = (h) => h.replace(/^0/, "");

  // Ora attuale in Italia (indipendente dal fuso del telefono)
  function roma() {
    const parti = new Intl.DateTimeFormat("en-GB", {
      timeZone: "Europe/Rome", weekday: "short", hour: "2-digit", minute: "2-digit", hourCycle: "h23",
    }).formatToParts(new Date());
    const g = (t) => parti.find((p) => p.type === t).value;
    const day = { Mon: 0, Tue: 1, Wed: 2, Thu: 3, Fri: 4, Sat: 5, Sun: 6 }[g("weekday")];
    return { day, min: Number(g("hour")) * 60 + Number(g("minute")) };
  }
  function oggiISO() {
    return new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/Rome" }).format(new Date());
  }

  // Stato "aperto/chiuso" con prossima apertura
  function stato(n) {
    const { day, min } = roma();
    const oggi = n.orari[day];
    for (const [a, b] of oggi) {
      if (min >= toMin(a) && min < toMin(b)) return { aperto: true, testo: `Aperto ora · chiude alle ${fmt(b)}` };
    }
    for (const [a] of oggi) {
      if (min < toMin(a)) return { aperto: false, testo: `Chiuso ora · riapre oggi alle ${fmt(a)}` };
    }
    for (let i = 1; i <= 7; i++) {
      const d = (day + i) % 7;
      if (n.orari[d].length) {
        const quando = i === 1 ? "domani" : GIORNI[d].toLowerCase();
        return { aperto: false, testo: `Chiuso ora · riapre ${quando} alle ${fmt(n.orari[d][0][0])}` };
      }
    }
    return { aperto: false, testo: "Chiuso" };
  }

  // Badge aperto/chiuso
  document.querySelectorAll(".badge[data-store]").forEach((el) => {
    const s = stato(NEGOZI[el.dataset.store]);
    el.textContent = s.testo;
    el.classList.add(s.aperto ? "is-open" : "is-closed");
  });

  // Evidenzia il giorno di oggi nella tabella orari
  const r = document.querySelector(`.orari tr[data-day="${roma().day}"]`);
  if (r) r.classList.add("oggi");

  // Mappa: si carica solo al click (niente richieste a Google finché non serve)
  document.querySelectorAll(".mappa").forEach((box) => {
    const btn = box.querySelector(".mappa-carica");
    btn.addEventListener("click", () => {
      const f = document.createElement("iframe");
      f.src = box.dataset.src;
      f.loading = "lazy";
      f.title = "Mappa";
      f.referrerPolicy = "no-referrer-when-downgrade";
      box.replaceChildren(f);
      box.classList.add("caricata");
    });
  });

  // Prenotazione -> WhatsApp con messaggio precompilato
  const form = document.getElementById("prenota");
  if (!form) return;
  const n = NEGOZI[form.dataset.store];
  const inData = form.elements.data;
  const inOra = form.elements.ora;
  const avviso = form.querySelector(".avviso");
  inData.min = oggiISO();

  const giornoIdx = (iso) => { const [y, m, d] = iso.split("-").map(Number); return (new Date(y, m - 1, d).getDay() + 6) % 7; };
  const hhmm = (m) => String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");

  function slots(iso) {
    const out = [];
    const ora = roma();
    const isOggi = iso === oggiISO();
    for (const [a, b] of n.orari[giornoIdx(iso)]) {
      for (let m = toMin(a); m + 30 <= toMin(b); m += 30) {
        if (isOggi && m <= ora.min) continue; // niente orari già passati
        out.push(hhmm(m));
      }
    }
    return out;
  }

  inData.addEventListener("change", () => {
    avviso.textContent = "";
    inOra.innerHTML = "";
    if (!inData.value) { inOra.disabled = true; inOra.innerHTML = '<option value="">Scegli prima il giorno</option>'; return; }
    const s = slots(inData.value);
    if (!s.length) {
      inOra.disabled = true;
      inOra.innerHTML = '<option value="">Nessun orario disponibile</option>';
      avviso.textContent = n.orari[giornoIdx(inData.value)].length
        ? "Per oggi gli orari sono finiti: prova un altro giorno."
        : "Quel giorno il negozio è chiuso: scegli un altro giorno.";
      return;
    }
    inOra.disabled = false;
    inOra.innerHTML = '<option value="">Scegli l\'ora</option>' + s.map((x) => `<option>${x}</option>`).join("");
  });

  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const nome = form.elements.nome.value.trim();
    if (!nome || !inData.value || !inOra.value) {
      avviso.textContent = "Compila nome, giorno e ora per continuare.";
      return;
    }
    const [y, m, d] = inData.value.split("-").map(Number);
    const giorno = new Intl.DateTimeFormat("it-IT", { weekday: "long", day: "numeric", month: "long" }).format(new Date(y, m - 1, d));
    const msg = `Ciao! Sono ${nome}. Vorrei prendere un appuntamento da ${n.nome} ${giorno} alle ${inOra.value}. Grazie!`;
    window.open(`https://wa.me/${n.wa}?text=${encodeURIComponent(msg)}`, "_blank", "noopener");
  });
})();
