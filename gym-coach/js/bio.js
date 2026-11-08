// Impronta / volto del telefono (WebAuthn, autenticatore del dispositivo). Serve come "chiave" per aprire l'app.
const b64 = (u8) => btoa(String.fromCharCode(...u8));
const unb64 = (s) => Uint8Array.from(atob(s), c => c.charCodeAt(0));

export async function bioAvailable() {
  try { return !!(window.PublicKeyCredential && await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()); } catch { return false; }
}
export async function bioRegister(name) {
  const c = await navigator.credentials.create({ publicKey: {
    rp: { name: 'Gym Coach' },
    user: { id: crypto.getRandomValues(new Uint8Array(16)), name: name || 'utente', displayName: name || 'Utente' },
    challenge: crypto.getRandomValues(new Uint8Array(32)),
    pubKeyCredParams: [{ type: 'public-key', alg: -7 }, { type: 'public-key', alg: -257 }],
    authenticatorSelection: { authenticatorAttachment: 'platform', userVerification: 'required', residentKey: 'discouraged' },
    timeout: 60000, attestation: 'none',
  } });
  return b64(new Uint8Array(c.rawId));
}
export async function bioVerify(credId) {
  await navigator.credentials.get({ publicKey: {
    challenge: crypto.getRandomValues(new Uint8Array(32)),
    allowCredentials: [{ type: 'public-key', id: unb64(credId) }],
    userVerification: 'required', timeout: 60000,
  } });
  return true;                                           // se non c'è stata un'eccezione, l'impronta è stata riconosciuta
}
