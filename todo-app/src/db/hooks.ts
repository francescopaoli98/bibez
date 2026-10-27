import { useCallback, useState } from 'react';
import { useFocusEffect } from 'expo-router';
import { useSQLiteContext, type SQLiteDatabase } from 'expo-sqlite';
import { setDone, setImportant, type Task } from './tasks';

// Carica dati dal database e li ricarica ogni volta che la schermata torna in primo piano.
// `loader` deve essere stabile (useCallback) altrimenti ricarica a ogni render.
export function useLoad<T>(loader: (db: SQLiteDatabase) => Promise<T>, initial: T) {
  const db = useSQLiteContext();
  const [data, setData] = useState<T>(initial);

  const reload = useCallback(async () => {
    setData(await loader(db));
  }, [db, loader]);

  useFocusEffect(
    useCallback(() => {
      void reload();
    }, [reload]),
  );

  return { data, reload };
}

// Azioni comuni alle liste di attività: completa e importante, poi ricarica
export function useTaskActions(reload: () => Promise<void>) {
  const db = useSQLiteContext();

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

  return { toggleDone, toggleImportant };
}
