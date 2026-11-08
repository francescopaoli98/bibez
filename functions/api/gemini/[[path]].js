// Versione per Cloudflare Pages Functions (la logica sta in _lib/gemini.js).
import { handleGemini } from '../../_lib/gemini.js';
export const onRequest = ({ request, env, params }) => handleGemini({ request, env, path: [].concat(params.path || []).join('/') });
