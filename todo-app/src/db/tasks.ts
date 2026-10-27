import type { SQLiteDatabase } from 'expo-sqlite';
import { randomUUID } from 'expo-crypto';
import { startOfDay, startOfNextDay } from '../lib/dates';
import type { ProjectRef, QuickAddResult } from '../lib/quickAdd';

export interface Task {
  id: string;
  title: string;
  projectId: string | null;
  projectName: string | null;
  projectColor: string | null;
  dueAt: number | null;
  hasTime: boolean;
  important: boolean;
  doneAt: number | null;
  subTotal: number;
  subDone: number;
}

interface TaskRow {
  id: string;
  title: string;
  project_id: string | null;
  project_name: string | null;
  project_color: string | null;
  due_at: number | null;
  has_time: number;
  important: number;
  done_at: number | null;
  sub_total: number;
  sub_done: number;
}

const toTask = (r: TaskRow): Task => ({
  id: r.id,
  title: r.title,
  projectId: r.project_id,
  projectName: r.project_name,
  projectColor: r.project_color,
  dueAt: r.due_at,
  hasTime: r.has_time === 1,
  important: r.important === 1,
  doneAt: r.done_at,
  subTotal: r.sub_total,
  subDone: r.sub_done,
});

// Base di tutte le query sulle attività: aggiunge lista e conteggio dei passi
const SELECT = `
  SELECT t.id, t.title, t.project_id, t.due_at, t.has_time, t.important, t.done_at,
         p.name AS project_name, p.color AS project_color,
         (SELECT COUNT(*) FROM subtasks s WHERE s.task_id = t.id AND s.deleted_at IS NULL) AS sub_total,
         (SELECT COUNT(*) FROM subtasks s WHERE s.task_id = t.id AND s.deleted_at IS NULL AND s.done_at IS NOT NULL) AS sub_done
    FROM tasks t
    LEFT JOIN projects p ON p.id = t.project_id
   WHERE t.deleted_at IS NULL`;

async function query(db: SQLiteDatabase, tail: string, ...params: (string | number)[]): Promise<Task[]> {
  const rows = await db.getAllAsync<TaskRow>(`${SELECT} ${tail}`, ...params);
  return rows.map(toTask);
}

// ---------- viste ----------

// Oggi: da fare per oggi (o in ritardo) + completate oggi
export function listToday(db: SQLiteDatabase) {
  return query(
    db,
    `AND ( (t.done_at IS NULL AND t.due_at IS NOT NULL AND t.due_at < ?) OR (t.done_at >= ?) )
     ORDER BY t.has_time DESC, t.due_at ASC, t.created_at ASC`,
    startOfNextDay(), startOfDay(),
  );
}

// In arrivo: da domani in poi, non completate
export function listUpcoming(db: SQLiteDatabase) {
  return query(db, 'AND t.done_at IS NULL AND t.due_at >= ? ORDER BY t.due_at ASC', startOfNextDay());
}

// Un giorno preciso (per il calendario), anche le completate
export function listDay(db: SQLiteDatabase, dayStart: number) {
  const next = startOfNextDay(new Date(dayStart));
  return query(db, 'AND t.due_at >= ? AND t.due_at < ? ORDER BY t.done_at IS NOT NULL, t.has_time DESC, t.due_at ASC', dayStart, next);
}

export function listImportant(db: SQLiteDatabase) {
  return query(db, 'AND t.important = 1 AND t.done_at IS NULL ORDER BY t.due_at IS NULL, t.due_at ASC');
}

export function listAllOpen(db: SQLiteDatabase) {
  return query(db, 'AND t.done_at IS NULL ORDER BY t.due_at IS NULL, t.due_at ASC, t.created_at ASC');
}

// Una lista: da fare prima, poi completate
export function listProject(db: SQLiteDatabase, projectId: string) {
  return query(
    db,
    'AND t.project_id = ? ORDER BY t.done_at IS NOT NULL, t.due_at IS NULL, t.due_at ASC, t.created_at ASC',
    projectId,
  );
}

export async function getTask(db: SQLiteDatabase, id: string): Promise<Task | null> {
  const list = await query(db, 'AND t.id = ?', id);
  return list[0] ?? null;
}

// Giorni del mese che hanno almeno un'attività (per i puntini del calendario)
export async function daysWithTasks(db: SQLiteDatabase, from: number, to: number): Promise<Set<number>> {
  const rows = await db.getAllAsync<{ due_at: number }>(
    'SELECT due_at FROM tasks WHERE deleted_at IS NULL AND due_at >= ? AND due_at < ?',
    from, to,
  );
  return new Set(rows.map((r) => startOfDay(new Date(r.due_at))));
}

export interface Counts {
  today: number;
  important: number;
  upcoming: number;
  all: number;
}

export async function getCounts(db: SQLiteDatabase): Promise<Counts> {
  const one = async (sql: string, ...p: number[]) =>
    (await db.getFirstAsync<{ n: number }>(sql, ...p))?.n ?? 0;
  const base = 'SELECT COUNT(*) AS n FROM tasks WHERE deleted_at IS NULL AND done_at IS NULL';
  return {
    today: await one(`${base} AND due_at IS NOT NULL AND due_at < ?`, startOfNextDay()),
    important: await one(`${base} AND important = 1`),
    upcoming: await one(`${base} AND due_at >= ?`, startOfNextDay()),
    all: await one(base),
  };
}

// ---------- liste ----------

export interface ProjectInfo extends ProjectRef {
  color: string;
  icon: string;
  open: number;
}

export async function listProjects(db: SQLiteDatabase): Promise<ProjectRef[]> {
  return db.getAllAsync<ProjectRef>(
    'SELECT id, name, color FROM projects WHERE deleted_at IS NULL ORDER BY sort_order ASC, created_at ASC',
  );
}

export async function listProjectsWithCounts(db: SQLiteDatabase): Promise<ProjectInfo[]> {
  return db.getAllAsync<ProjectInfo>(
    `SELECT p.id, p.name, p.color, p.icon,
            (SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id AND t.deleted_at IS NULL AND t.done_at IS NULL) AS open
       FROM projects p
      WHERE p.deleted_at IS NULL
      ORDER BY p.sort_order ASC, p.created_at ASC`,
  );
}

export async function getProject(db: SQLiteDatabase, id: string): Promise<ProjectRef | null> {
  return db.getFirstAsync<ProjectRef>('SELECT id, name, color FROM projects WHERE id = ? AND deleted_at IS NULL', id);
}

export async function addProject(db: SQLiteDatabase, name: string, color: string) {
  const now = Date.now();
  const next = (await db.getFirstAsync<{ n: number }>('SELECT COALESCE(MAX(sort_order), -1) + 1 AS n FROM projects'))?.n ?? 0;
  await db.runAsync(
    'INSERT INTO projects (id, name, color, icon, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    randomUUID(), name.trim(), color, 'list', next, now, now,
  );
}

// ---------- attività ----------

// Salva il risultato del quick add. Se non è stata scritta nessuna data,
// l'attività è per oggi (si aggiunge dalla vista Oggi).
export async function addTask(db: SQLiteDatabase, r: QuickAddResult, fallbackDay: number | null = startOfDay()) {
  const now = Date.now();
  await db.runAsync(
    `INSERT INTO tasks (id, title, project_id, due_at, has_time, important, remind_minutes, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    randomUUID(),
    r.title.trim(),
    r.project?.id ?? null,
    r.dueAt ?? fallbackDay,
    r.hasTime ? 1 : 0,
    r.important ? 1 : 0,
    r.remindMinutes,
    now,
    now,
  );
}

export interface TaskPatch {
  title?: string;
  dueAt?: number | null;
  hasTime?: boolean;
  important?: boolean;
  projectId?: string | null;
}

export async function updateTask(db: SQLiteDatabase, id: string, patch: TaskPatch) {
  const sets: string[] = [];
  const values: (string | number | null)[] = [];
  const add = (col: string, v: string | number | null) => {
    sets.push(`${col} = ?`);
    values.push(v);
  };
  if (patch.title !== undefined) add('title', patch.title.trim());
  if (patch.dueAt !== undefined) add('due_at', patch.dueAt);
  if (patch.hasTime !== undefined) add('has_time', patch.hasTime ? 1 : 0);
  if (patch.important !== undefined) add('important', patch.important ? 1 : 0);
  if (patch.projectId !== undefined) add('project_id', patch.projectId);
  if (sets.length === 0) return;
  add('updated_at', Date.now());
  await db.runAsync(`UPDATE tasks SET ${sets.join(', ')} WHERE id = ?`, ...values, id);
}

export async function deleteTask(db: SQLiteDatabase, id: string) {
  const now = Date.now();
  await db.runAsync('UPDATE tasks SET deleted_at = ?, updated_at = ? WHERE id = ?', now, now, id);
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

// ---------- passi (checklist) ----------

export interface Subtask {
  id: string;
  title: string;
  doneAt: number | null;
}

export async function listSubtasks(db: SQLiteDatabase, taskId: string): Promise<Subtask[]> {
  const rows = await db.getAllAsync<{ id: string; title: string; done_at: number | null }>(
    'SELECT id, title, done_at FROM subtasks WHERE task_id = ? AND deleted_at IS NULL ORDER BY sort_order ASC, created_at ASC',
    taskId,
  );
  return rows.map((r) => ({ id: r.id, title: r.title, doneAt: r.done_at }));
}

export async function addSubtask(db: SQLiteDatabase, taskId: string, title: string) {
  const now = Date.now();
  const next =
    (await db.getFirstAsync<{ n: number }>(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS n FROM subtasks WHERE task_id = ?',
      taskId,
    ))?.n ?? 0;
  await db.runAsync(
    'INSERT INTO subtasks (id, task_id, title, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
    randomUUID(), taskId, title.trim(), next, now, now,
  );
}

export async function setSubtaskDone(db: SQLiteDatabase, id: string, done: boolean) {
  const now = Date.now();
  await db.runAsync('UPDATE subtasks SET done_at = ?, updated_at = ? WHERE id = ?', done ? now : null, now, id);
}

export async function deleteSubtask(db: SQLiteDatabase, id: string) {
  const now = Date.now();
  await db.runAsync('UPDATE subtasks SET deleted_at = ?, updated_at = ? WHERE id = ?', now, now, id);
}

// ---------- punti e serie (tema Arcade) ----------

// 20 XP per attività completata, 400 XP a livello
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
