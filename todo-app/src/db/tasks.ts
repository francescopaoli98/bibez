import type { SQLiteDatabase } from 'expo-sqlite';
import { randomUUID } from 'expo-crypto';
import { startOfDay, startOfNextDay } from '../lib/dates';
import type { ProjectRef, QuickAddResult } from '../lib/quickAdd';

export interface Task {
  id: string;
  title: string;
  projectName: string | null;
  projectColor: string | null;
  dueAt: number | null;
  hasTime: boolean;
  important: boolean;
  doneAt: number | null;
}

interface TaskRow {
  id: string;
  title: string;
  project_name: string | null;
  project_color: string | null;
  due_at: number | null;
  has_time: number;
  important: number;
  done_at: number | null;
}

const toTask = (r: TaskRow): Task => ({
  id: r.id,
  title: r.title,
  projectName: r.project_name,
  projectColor: r.project_color,
  dueAt: r.due_at,
  hasTime: r.has_time === 1,
  important: r.important === 1,
  doneAt: r.done_at,
});

export async function listProjects(db: SQLiteDatabase): Promise<ProjectRef[]> {
  return db.getAllAsync<ProjectRef>(
    'SELECT id, name, color FROM projects WHERE deleted_at IS NULL ORDER BY sort_order ASC, created_at ASC',
  );
}

// Vista "Oggi": da fare per oggi (o in ritardo) + completate oggi
export async function listToday(db: SQLiteDatabase): Promise<Task[]> {
  const rows = await db.getAllAsync<TaskRow>(
    `SELECT t.id, t.title, t.due_at, t.has_time, t.important, t.done_at,
            p.name AS project_name, p.color AS project_color
       FROM tasks t
       LEFT JOIN projects p ON p.id = t.project_id
      WHERE t.deleted_at IS NULL
        AND ( (t.done_at IS NULL AND t.due_at IS NOT NULL AND t.due_at < ?)
           OR (t.done_at >= ?) )
      ORDER BY t.has_time DESC, t.due_at ASC, t.created_at ASC`,
    startOfNextDay(), startOfDay(),
  );
  return rows.map(toTask);
}

// Salva il risultato del quick add. Se non è stata scritta nessuna data,
// l'attività è per oggi (si aggiunge dalla vista Oggi).
export async function addTask(db: SQLiteDatabase, r: QuickAddResult) {
  const now = Date.now();
  await db.runAsync(
    `INSERT INTO tasks (id, title, project_id, due_at, has_time, important, remind_minutes, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    randomUUID(),
    r.title.trim(),
    r.project?.id ?? null,
    r.dueAt ?? startOfDay(),
    r.hasTime ? 1 : 0,
    r.important ? 1 : 0,
    r.remindMinutes,
    now,
    now,
  );
}

// Punti e serie di giorni, usati dal tema Arcade (20 XP per attività completata, 400 XP a livello)
export interface GameStats {
  level: number;
  xp: number; // XP dentro il livello attuale
  xpMax: number;
  streak: number; // giorni consecutivi con almeno un'attività completata
}
const XP_PER_TASK = 20;
const XP_PER_LEVEL = 400;

export async function getStats(db: SQLiteDatabase): Promise<GameStats> {
  const rows = await db.getAllAsync<{ done_at: number }>(
    'SELECT done_at FROM tasks WHERE done_at IS NOT NULL AND deleted_at IS NULL',
  );
  const totalXp = rows.length * XP_PER_TASK;

  const days = new Set(rows.map((r) => startOfDay(new Date(r.done_at))));
  const cursor = new Date();
  // se oggi non hai ancora completato nulla la serie non si spezza: si parte da ieri
  if (!days.has(startOfDay(cursor))) cursor.setDate(cursor.getDate() - 1);
  let streak = 0;
  while (days.has(startOfDay(cursor))) {
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }

  return {
    level: Math.floor(totalXp / XP_PER_LEVEL) + 1,
    xp: totalXp % XP_PER_LEVEL,
    xpMax: XP_PER_LEVEL,
    streak,
  };
}

export async function setDone(db: SQLiteDatabase, id: string, done: boolean) {
  const now = Date.now();
  await db.runAsync(
    'UPDATE tasks SET done_at = ?, updated_at = ? WHERE id = ?',
    done ? now : null, now, id,
  );
}

export async function setImportant(db: SQLiteDatabase, id: string, important: boolean) {
  await db.runAsync(
    'UPDATE tasks SET important = ?, updated_at = ? WHERE id = ?',
    important ? 1 : 0, Date.now(), id,
  );
}
