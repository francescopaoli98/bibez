import type { SQLiteDatabase } from 'expo-sqlite';
import { randomUUID } from 'expo-crypto';

export const DB_NAME = 'todo.db';
const DB_VERSION = 1;

// Liste create al primo avvio, l'utente potrà rinominarle o eliminarle
const DEFAULT_PROJECTS = [
  { name: 'Lavoro', color: '#0F7FA8', icon: 'list' },
  { name: 'Doppiaggio', color: '#C2410C', icon: 'mic' },
  { name: 'Casa', color: '#15803D', icon: 'home' },
];

// Eseguita all'avvio da SQLiteProvider: porta il database all'ultima versione.
// Gli id sono UUID e ogni riga ha updated_at / deleted_at, così il sync cloud
// (step 7) non richiederà di rifare le tabelle.
export async function migrate(db: SQLiteDatabase) {
  const row = await db.getFirstAsync<{ user_version: number }>('PRAGMA user_version');
  let version = row?.user_version ?? 0;
  if (version >= DB_VERSION) return;

  if (version === 0) {
    await db.execAsync(`
      PRAGMA journal_mode = WAL;
      PRAGMA foreign_keys = ON;

      CREATE TABLE projects (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );

      CREATE TABLE tasks (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        notes TEXT,
        project_id TEXT REFERENCES projects(id),
        due_at INTEGER,
        has_time INTEGER NOT NULL DEFAULT 0,
        important INTEGER NOT NULL DEFAULT 0,
        done_at INTEGER,
        remind_minutes INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
      CREATE INDEX idx_tasks_due ON tasks(due_at);

      CREATE TABLE settings (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      );
    `);

    const now = Date.now();
    let order = 0;
    for (const p of DEFAULT_PROJECTS) {
      await db.runAsync(
        'INSERT INTO projects (id, name, color, icon, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        randomUUID(), p.name, p.color, p.icon, order++, now, now,
      );
    }
    version = 1;
  }

  await db.execAsync(`PRAGMA user_version = ${DB_VERSION}`);
}
