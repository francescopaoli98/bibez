// Scansione locale: cookie + cronologia -> lista di domini/aziende.
// Nessun dato lascia il browser: l'estensione non fa chiamate di rete (vedi CSP nel manifest).

import { registrableDomain, domainFromUrl } from "./domains.js";
import { trackerInfo } from "./trackers.js";

/**
 * Parte pura (testabile con Node): raggruppa cookie e visite per dominio.
 * @param {Array<{domain:string,name:string}>} cookies
 * @param {Array<{url?:string,visitCount?:number}>} historyItems
 */
export function buildModel(cookies, historyItems) {
  const byDomain = new Map();
  const get = (domain) => {
    if (!byDomain.has(domain)) {
      const info = trackerInfo(domain);
      byDomain.set(domain, {
        domain,
        cookies: [],
        visits: 0,
        tracker: !!info,
        company: info ? info.company : null,
        category: info ? info.category : null,
      });
    }
    return byDomain.get(domain);
  };

  for (const c of cookies) {
    const d = registrableDomain(c.domain);
    if (d) get(d).cookies.push(c);
  }
  for (const h of historyItems) {
    const d = domainFromUrl(h.url);
    if (d) get(d).visits += h.visitCount || 1;
  }

  // Prima i tracker noti, poi chi ha più cookie.
  return [...byDomain.values()]
    .filter((e) => e.cookies.length > 0 || e.visits > 0)
    .sort((a, b) => Number(b.tracker) - Number(a.tracker) || b.cookies.length - a.cookies.length);
}

/** Legge cookie e cronologia dal browser (richiede i permessi nel manifest). */
export async function scan() {
  const cookies = await chrome.cookies.getAll({});
  const history = await chrome.history.search({ text: "", startTime: 0, maxResults: 10000 });
  return buildModel(cookies, history);
}

/** Cancella i cookie indicati. Ritorna quanti ne ha rimossi. */
export async function removeCookies(cookies) {
  let removed = 0;
  for (const c of cookies) {
    const url = (c.secure ? "https://" : "http://") + c.domain.replace(/^\./, "") + c.path;
    const details = { url, name: c.name, storeId: c.storeId };
    if (c.partitionKey) details.partitionKey = c.partitionKey;
    try {
      const res = await chrome.cookies.remove(details);
      if (res) removed++;
    } catch {
      // cookie già sparito o non rimovibile: si va avanti
    }
  }
  return removed;
}
