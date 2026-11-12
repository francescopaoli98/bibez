// Bozze di richiesta GDPR. Funzione pura: genera solo testo, non invia nulla.
// L'utente rilegge, completa e invia dalla propria email.
//
// Basi giuridiche usate:
//  - art. 7.3  revoca del consenso
//  - art. 17   cancellazione ("diritto all'oblio")
//  - art. 21   opposizione al trattamento / profilazione
//  - art. 15   accesso (cosa sapete di me)
//  - art. 12.3 risposta entro un mese

const TEXT = {
  it: {
    subject: (company) => `Richiesta GDPR: revoca consenso e cancellazione dati (${company})`,
    greeting: "Spett.le Titolare del trattamento / DPO,",
    intro: (company, domain) =>
      `ai sensi del Regolamento (UE) 2016/679 (GDPR), con la presente mi rivolgo a ${company} in relazione al sito/servizio ${domain}.`,
    ids: (names) =>
      `Per aiutarvi a individuare il mio profilo, indico i nomi dei cookie/identificatori presenti sul mio dispositivo: ${names}.`,
    account: (email) => `Email di riferimento per l'identificazione: ${email}.`,
    asks: {
      withdraw: "Revoco ogni consenso al trattamento dei miei dati personali (art. 7, par. 3 GDPR), compresi cookie e tecnologie analoghe per profilazione e pubblicità.",
      object: "Mi oppongo al trattamento per finalità di profilazione e marketing diretto (art. 21 GDPR).",
      erase: "Chiedo la cancellazione di tutti i dati personali che mi riguardano (art. 17 GDPR), inclusi quelli comunicati a terzi, che vi chiedo di informare (art. 19 GDPR).",
      access: "Chiedo copia dei dati che mi riguardano e le informazioni di cui all'art. 15 GDPR (finalità, categorie di dati, destinatari, fonte).",
    },
    closing:
      "Vi chiedo di rispondere entro un mese dal ricevimento (art. 12, par. 3 GDPR) confermando per iscritto le azioni svolte. In caso di mancata risposta mi riservo di rivolgermi al Garante per la protezione dei dati personali.",
    regards: "Cordiali saluti,",
    namePlaceholder: "[NOME E COGNOME]",
    emailPlaceholder: "[LA TUA EMAIL]",
  },
  en: {
    subject: (company) => `GDPR request: withdrawal of consent and erasure (${company})`,
    greeting: "Dear Data Controller / DPO,",
    intro: (company, domain) =>
      `Under Regulation (EU) 2016/679 (GDPR), I am writing to ${company} regarding the site/service ${domain}.`,
    ids: (names) =>
      `To help you locate my profile, these are the names of the cookies/identifiers on my device: ${names}.`,
    account: (email) => `Contact email for identification: ${email}.`,
    asks: {
      withdraw: "I withdraw all consent to the processing of my personal data (Art. 7(3) GDPR), including cookies and similar technologies used for profiling and advertising.",
      object: "I object to processing for profiling and direct marketing purposes (Art. 21 GDPR).",
      erase: "I request the erasure of all personal data concerning me (Art. 17 GDPR), and that you notify any third parties who received it (Art. 19 GDPR).",
      access: "I request a copy of my data and the information listed in Art. 15 GDPR (purposes, categories, recipients, source).",
    },
    closing:
      "Please reply within one month of receipt (Art. 12(3) GDPR) confirming in writing the actions taken. If I receive no reply I reserve the right to lodge a complaint with the competent supervisory authority.",
    regards: "Kind regards,",
    namePlaceholder: "[FULL NAME]",
    emailPlaceholder: "[YOUR EMAIL]",
  },
};

export const ALL_KINDS = ["withdraw", "object", "erase", "access"];

/**
 * @param {object} p
 * @param {string} p.domain       es. "criteo.com"
 * @param {string} [p.company]    es. "Criteo" (se manca si usa il dominio)
 * @param {string[]} [p.cookieNames]  nomi dei cookie (MAI i valori)
 * @param {string} [p.name]
 * @param {string} [p.email]
 * @param {"it"|"en"} [p.lang]
 * @param {string[]} [p.kinds]    quali richieste includere
 * @returns {{subject: string, body: string}}
 */
export function buildRequest({
  domain,
  company,
  cookieNames = [],
  name,
  email,
  lang = "it",
  kinds = ["withdraw", "object", "erase"],
}) {
  const t = TEXT[lang] || TEXT.it;
  const who = company || domain;
  const names = [...new Set(cookieNames)].slice(0, 20).join(", ");

  const lines = [t.greeting, "", t.intro(who, domain), ""];
  if (names) lines.push(t.ids(names), "");
  lines.push(t.account(email || t.emailPlaceholder), "");
  kinds.filter((k) => t.asks[k]).forEach((k, i) => lines.push(`${i + 1}. ${t.asks[k]}`));
  lines.push("", t.closing, "", t.regards, name || t.namePlaceholder);

  return { subject: t.subject(who), body: lines.join("\n") };
}
