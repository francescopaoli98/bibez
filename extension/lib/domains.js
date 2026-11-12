// Utility sui domini. Funzioni pure: niente chiamate al browser, testabili con Node.

// Suffissi "a due livelli" più comuni (co.uk, com.au...).
// NOTA: versione semplificata. In produzione va usata la Public Suffix List.
const MULTI_SUFFIX = new Set([
  "co.uk", "org.uk", "ac.uk", "gov.uk",
  "com.au", "net.au", "org.au",
  "co.jp", "co.nz", "co.in", "co.za", "co.kr",
  "com.br", "com.mx", "com.tr", "com.ar", "com.cn", "com.hk",
]);

/** "sub.example.co.uk" -> "example.co.uk"; ".google.com" -> "google.com" */
export function registrableDomain(host) {
  const h = String(host || "").trim().toLowerCase().replace(/^\./, "");
  if (!h) return "";
  // IP o host speciali: restano così come sono
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(h) || h.includes(":") || !h.includes(".")) return h;

  const parts = h.split(".");
  if (parts.length <= 2) return h;
  const last2 = parts.slice(-2).join(".");
  return MULTI_SUFFIX.has(last2) ? parts.slice(-3).join(".") : last2;
}

/** Dominio dall'URL della cronologia. Ritorna "" se l'URL non è valido o non è http(s). */
export function domainFromUrl(url) {
  try {
    const u = new URL(url);
    if (u.protocol !== "http:" && u.protocol !== "https:") return "";
    return registrableDomain(u.hostname);
  } catch {
    return "";
  }
}
