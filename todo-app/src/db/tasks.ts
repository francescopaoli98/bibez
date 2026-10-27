import type { SQLiteDatabase } from 'expo-sqlite';
import { randomUUID } from 'expo-crypto';
import { startOfDay, startOfNextDay } from '../lib/dates';

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

export async function addTaskForToday(db: SQLiteDatabase, title: string) {
  const now = Date.now();
  await db.runAsync(
    'INSERT INTO tasks (id, title, due_at, has_time, created_at, updated_at) VALUES (?, ?, ?, 0, ?, ?)',
    randomUUID(), title.trim(), startOfDay(), now, now,
  );
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
