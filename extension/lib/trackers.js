// Elenco iniziale (seed) di aziende note per tracking/pubblicità.
// È solo un punto di partenza: nella fase 3 diventa un database vero
// (dominio -> azienda -> contatto privacy -> modello di richiesta).
//
// privacyEmail è volutamente null: non inventiamo indirizzi.
// Va compilato solo dopo averlo verificato sull'informativa privacy dell'azienda.

const T = (company, category) => ({ company, category, privacyEmail: null });

export const TRACKERS = {
  "google-analytics.com": T("Google", "analytics"),
  "googletagmanager.com": T("Google", "analytics"),
  "doubleclick.net": T("Google", "pubblicità"),
  "googlesyndication.com": T("Google", "pubblicità"),
  "googleadservices.com": T("Google", "pubblicità"),
  "facebook.net": T("Meta", "social/pubblicità"),
  "facebook.com": T("Meta", "social/pubblicità"),
  "instagram.com": T("Meta", "social/pubblicità"),
  "tiktok.com": T("TikTok", "social/pubblicità"),
  "linkedin.com": T("LinkedIn (Microsoft)", "social/pubblicità"),
  "clarity.ms": T("Microsoft", "analytics"),
  "bing.com": T("Microsoft", "pubblicità"),
  "adnxs.com": T("Xandr (Microsoft)", "pubblicità"),
  "criteo.com": T("Criteo", "pubblicità"),
  "criteo.net": T("Criteo", "pubblicità"),
  "taboola.com": T("Taboola", "pubblicità"),
  "outbrain.com": T("Outbrain", "pubblicità"),
  "scorecardresearch.com": T("Comscore", "analytics"),
  "quantserve.com": T("Quantcast", "pubblicità"),
  "hotjar.com": T("Hotjar", "analytics"),
  "rubiconproject.com": T("Magnite", "pubblicità"),
  "pubmatic.com": T("PubMatic", "pubblicità"),
  "openx.net": T("OpenX", "pubblicità"),
  "casalemedia.com": T("Index Exchange", "pubblicità"),
  "demdex.net": T("Adobe", "pubblicità"),
  "omtrdc.net": T("Adobe", "analytics"),
  "bluekai.com": T("Oracle", "pubblicità"),
  "krxd.net": T("Salesforce", "pubblicità"),
  "adsrvr.org": T("The Trade Desk", "pubblicità"),
  "amazon-adsystem.com": T("Amazon", "pubblicità"),
  "twitter.com": T("X Corp", "social/pubblicità"),
  "ads-twitter.com": T("X Corp", "pubblicità"),
  "snapchat.com": T("Snap", "social/pubblicità"),
  "pinterest.com": T("Pinterest", "social/pubblicità"),
};

/** Info sul tracker se il dominio è nell'elenco, altrimenti null. */
export function trackerInfo(domain) {
  return TRACKERS[domain] || null;
}
