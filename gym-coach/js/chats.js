// Più chat con il coach: storico, titoli scritti dal coach, memoria degli argomenti già discussi.
import { S, save } from './store.js';
import { gemini } from './ai.js';

const MAX_CHATS = 40, MAX_MSGS = 60;
const newId = () => 'c' + Date.now().toString(36) + Math.random().toString(36).slice(2, 5);

export const current = () => S.chats.find(c => c.id === S.activeChat) || null;
export const messages = () => current()?.messages || [];
export const allMessages = () => S.chats.flatMap(c => c.messages);
export const sorted = () => [...S.chats].sort((a, b) => b.updated - a.updated);

// La chat si crea solo quando scrivi il primo messaggio (niente chat vuote nello storico)
export function ensureCurrent() {
  let c = current();
  if (!c) {
    c = { id: newId(), title: '', created: Date.now(), updated: Date.now(), messages: [] };
    S.chats.unshift(c); S.activeChat = c.id;
    if (S.chats.length > MAX_CHATS) S.chats.length = MAX_CHATS;
  }
  return c;
}
export function push(msg) {
  const c = ensureCurrent();
  c.messages.push(msg); if (c.messages.length > MAX_MSGS) c.messages.splice(0, c.messages.length - MAX_MSGS);
  c.updated = Date.now();
  if (!c.title && msg.role === 'user') c.title = msg.text.length > 30 ? msg.text.slice(0, 28).trim() + '…' : msg.text;   // titolo provvisorio
  save(); return c;
}
export function popLast() { const c = current(); if (c) { c.messages.pop(); if (!c.messages.length) { S.chats = S.chats.filter(x => x !== c); S.activeChat = null; } save(); } }
export function startNew() { S.activeChat = null; save(); }
export function open(id) { S.activeChat = id; save(); }
export function remove(id) { S.chats = S.chats.filter(c => c.id !== id); if (S.activeChat === id) S.activeChat = null; save(); }
export const topics = (n = 8) => sorted().filter(c => c.id !== S.activeChat && c.title).slice(0, n).map(c => c.title);

// Titolo scritto dal coach (2-5 parole). In caso di errore resta quello provvisorio.
export async function aiTitle(chat) {
  const first = chat.messages.find(m => m.role === 'user')?.text || '';
  const reply = chat.messages.find(m => m.role === 'model')?.text || '';
  const t = await gemini({ temperature: 0.3, ms: 20000, contents: [{ role: 'user', parts: [{ text:
    `Dai un titolo brevissimo (2-5 parole, in italiano, senza virgolette né punto finale) a questa conversazione tra una persona e il suo coach di palestra.\n\nPersona: ${first.slice(0, 300)}\nCoach: ${reply.slice(0, 300)}\n\nRispondi solo con il titolo.` }] }] });
  const title = t.replace(/["“”«»*#\n.]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 40);
  if (title) { chat.title = title; chat.aiTitled = true; save(); }
  return chat.title;
}
