import { useCallback, useState } from 'react';
import { useFocusEffect } from 'expo-router';
import { useSQLiteContext } from 'expo-sqlite';
import type { ProjectRef, QuickAddResult } from '../lib/quickAdd';
import { useTaskActions } from './hooks';
import { addTask, getStats, listProjects, listToday, type GameStats, type Task } from './tasks';

const NO_STATS: GameStats = { level: 1, xp: 0, xpMax: 400, streak: 0 };

// Attività della vista "Oggi": si ricarica ogni volta che la schermata torna in primo piano
export function useTodayTasks() {
  const db = useSQLiteContext();
  const [tasks, setTasks] = useState<Task[]>([]);
  const [projects, setProjects] = useState<ProjectRef[]>([]);
  const [stats, setStats] = useState<GameStats>(NO_STATS);

  const reload = useCallback(async () => {
    const [t, p, s] = await Promise.all([listToday(db), listProjects(db), getStats(db)]);
    setTasks(t);
    setProjects(p);
    setStats(s);
  }, [db]);

  useFocusEffect(
    useCallback(() => {
      void reload();
    }, [reload]),
  );

  const add = useCallback(
    async (parsed: QuickAddResult) => {
      await addTask(db, parsed);
      await reload();
    },
    [db, reload],
  );

  const { toggleDone, toggleImportant } = useTaskActions(reload);

  const open = tasks.filter((t) => t.doneAt === null);
  const done = tasks.filter((t) => t.doneAt !== null);

  return { open, done, projects, stats, add, toggleDone, toggleImportant };
}
