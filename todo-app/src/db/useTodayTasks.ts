import { useCallback, useState } from 'react';
import { useFocusEffect } from 'expo-router';
import { useSQLiteContext } from 'expo-sqlite';
import { addTaskForToday, listToday, setDone, setImportant, type Task } from './tasks';

// Attività della vista "Oggi": si ricarica ogni volta che la schermata torna in primo piano
export function useTodayTasks() {
  const db = useSQLiteContext();
  const [tasks, setTasks] = useState<Task[]>([]);

  const reload = useCallback(async () => {
    setTasks(await listToday(db));
  }, [db]);

  useFocusEffect(
    useCallback(() => {
      void reload();
    }, [reload]),
  );

  const add = useCallback(
    async (title: string) => {
      await addTaskForToday(db, title);
      await reload();
    },
    [db, reload],
  );

  const toggleDone = useCallback(
    async (task: Task) => {
      await setDone(db, task.id, task.doneAt === null);
      await reload();
    },
    [db, reload],
  );

  const toggleImportant = useCallback(
    async (task: Task) => {
      await setImportant(db, task.id, !task.important);
      await reload();
    },
    [db, reload],
  );

  const open = tasks.filter((t) => t.doneAt === null);
  const done = tasks.filter((t) => t.doneAt !== null);

  return { open, done, add, toggleDone, toggleImportant };
}
