// Punto d'ingresso del Worker (Cloudflare Workers + file statici).
// Le richieste /api/* arrivano qui (vedi "run_worker_first" in wrangler.jsonc); tutto il resto lo serve Cloudflare dai file di gym-coach/.
import * as login from '../functions/api/login.js';
import * as password from '../functions/api/password.js';
import { handleGemini } from '../functions/_lib/gemini.js';
import { err } from '../functions/_lib/auth.js';

const POST_ONLY = (request) => request.method === 'POST' ? null : err(405, 'Metodo non consentito.');

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (pathname === '/api/login') return POST_ONLY(request) || login.onRequestPost({ request, env });
    if (pathname === '/api/password') return POST_ONLY(request) || password.onRequestPost({ request, env });
    if (pathname.startsWith('/api/gemini/')) return handleGemini({ request, env, path: pathname.slice('/api/gemini/'.length) });
    if (pathname.startsWith('/api/')) return err(404, 'Non trovato.');
    return env.ASSETS ? env.ASSETS.fetch(request) : err(404, 'Non trovato.');
  },
};
