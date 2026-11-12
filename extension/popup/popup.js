// Logica del popup. Nessuna chiamata di rete: tutto gira nel browser.
// I testi arrivano dal web (nomi di domini/cookie), quindi si usa textContent, mai innerHTML.

import { scan, removeCookies } from "../lib/scan.js";
import { buildRequest } from "../lib/gdpr.js";

const $ = (id) => document.getElementById(id);
let model = []; // risultato dell'ultima scansione
let current = null; // dominio per cui stiamo preparando la richiesta

// ---------- lista ----------

function render() {
  const list = $("list");
  list.replaceChildren();

  const trackers = model.filter((e) => e.tracker);
  const totalCookies = model.reduce((n, e) => n + e.cookies.length, 0);
  $("summary").hidden = false;
  $("summary").textContent = `${model.length} domini · ${totalCookies} cookie · ${trackers.length} tracker noti`;
  $("btn-clean-trackers").disabled = trackers.every((e) => e.cookies.length === 0);

  for (const e of model.slice(0, 200)) {
    const li = document.createElement("li");
    li.className = "row";

    const name = document.createElement("div");
    name.className = "name";
    name.textContent = e.domain;
    if (e.tracker) {
      const b = document.createElement("span");
      b.className = "badge";
      b.textContent = e.company;
      name.append(b);
    }

    const meta = document.createElement("div");
    meta.className = "meta";
    meta.textContent = `${e.cookies.length} cookie · ${e.visits} visite${e.category ? " · " + e.category : ""}`;

    const btns = document.createElement("div");
    btns.className = "btns";
    btns.append(
      button("Cancella", async () => {
        const n = await removeCookies(e.cookies);
        setStatus(`${n} cookie rimossi da ${e.domain}.`);
        await runScan();
      }),
      button("GDPR", () => openRequest(e))
    );

    li.append(name, meta, btns);
    list.append(li);
  }
}

function button(label, onClick) {
  const b = document.createElement("button");
  b.textContent = label;
  b.addEventListener("click", onClick);
  return b;
}

function setStatus(msg) {
  $("status").textContent = msg;
}

async function runScan() {
  setStatus("Scansione in corso…");
  try {
    model = await scan();
    setStatus("");
    render();
  } catch (err) {
    setStatus("Errore nella scansione: " + err.message);
  }
}

// ---------- richiesta GDPR ----------

async function openRequest(entry) {
  current = entry;
  $("view-list").hidden = true;
  $("view-request").hidden = false;
  $("req-title").textContent = `Richiesta a ${entry.company || entry.domain}`;

  // Il profilo (nome/email) resta solo in chrome.storage.local, sul tuo dispositivo.
  const saved = await chrome.storage.local.get(["name", "email", "lang"]);
  $("in-name").value = saved.name || "";
  $("in-email").value = saved.email || "";
  $("in-lang").value = saved.lang || "it";
  updateDraft();
}

function selectedKinds() {
  return [...document.querySelectorAll("fieldset input:checked")].map((i) => i.value);
}

function updateDraft() {
  if (!current) return;
  const { subject, body } = buildRequest({
    domain: current.domain,
    company: current.company,
    cookieNames: current.cookies.map((c) => c.name),
    name: $("in-name").value.trim(),
    email: $("in-email").value.trim(),
    lang: $("in-lang").value,
    kinds: selectedKinds(),
  });
  $("req-body").value = body;
  $("btn-mail").href = `mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;

  chrome.storage.local.set({
    name: $("in-name").value.trim(),
    email: $("in-email").value.trim(),
    lang: $("in-lang").value,
  });
}

// ---------- eventi ----------

$("btn-scan").addEventListener("click", runScan);

$("btn-clean-trackers").addEventListener("click", async () => {
  let n = 0;
  for (const e of model.filter((x) => x.tracker)) n += await removeCookies(e.cookies);
  setStatus(`${n} cookie di tracker rimossi.`);
  await runScan();
});

$("btn-back").addEventListener("click", () => {
  $("view-request").hidden = true;
  $("view-list").hidden = false;
});

for (const id of ["in-name", "in-email", "in-lang"]) $(id).addEventListener("input", updateDraft);
document.querySelectorAll("fieldset input").forEach((i) => i.addEventListener("change", updateDraft));

$("btn-copy").addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText($("req-body").value);
    $("btn-copy").textContent = "Copiato";
  } catch {
    $("req-body").select(); // se la clipboard è bloccata, almeno è già selezionato
  }
});
