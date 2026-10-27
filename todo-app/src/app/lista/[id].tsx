import { useCallback, useState } from 'react';
import { FlatList, KeyboardAvoidingView, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router, useLocalSearchParams } from 'expo-router';
import { useSQLiteContext, type SQLiteDatabase } from 'expo-sqlite';
import { AddBar } from '../../components/AddBar';
import { PageHeader } from '../../components/Banner';
import { Icon } from '../../components/Icon';
import { TaskCard } from '../../components/TaskCard';
import { useLoad, useTaskActions } from '../../db/hooks';
import { addTask, getProject, listAllOpen, listImportant, listProject, listProjects, type Task } from '../../db/tasks';
import type { ProjectRef, QuickAddResult } from '../../lib/quickAdd';
import { useTheme } from '../../theme/ThemeProvider';

interface Data {
  project: ProjectRef | null;
  tasks: Task[];
  projects: ProjectRef[];
}

// Elenco di una lista: "importanti", "tutte" oppure una lista tua (id)
export default function ListaScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { colors, look } = useTheme();
  const db = useSQLiteContext();
  const [showDone, setShowDone] = useState(false);

  const loader = useCallback(
    async (d: SQLiteDatabase): Promise<Data> => {
      const projects = await listProjects(d);
      if (id === 'importanti') return { project: null, tasks: await listImportant(d), projects };
      if (id === 'tutte') return { project: null, tasks: await listAllOpen(d), projects };
      return { project: await getProject(d, id), tasks: await listProject(d, id), projects };
    },
    [id],
  );
  const { data, reload } = useLoad<Data>(loader, { project: null, tasks: [], projects: [] });
  const { toggleDone, toggleImportant } = useTaskActions(reload);

  const title = id === 'importanti' ? 'Importanti' : id === 'tutte' ? 'Tutte le attività' : (data.project?.name ?? '…');
  const open = data.tasks.filter((t) => t.doneAt === null);
  const done = data.tasks.filter((t) => t.doneAt !== null);

  // In una lista le nuove attività ci restano dentro (e nelle "importanti" lo sono); senza data scritta non hanno data
  const handleAdd = async (parsed: QuickAddResult) => {
    await addTask(
      db,
      { ...parsed, project: parsed.project ?? data.project, important: parsed.important || id === 'importanti' },
      null,
    );
    await reload();
  };

  const open_ = (t: Task) => router.push(`/attivita/${t.id}`);

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={[styles.screen, { backgroundColor: colors.bg }]}
    >
      <StatusBar style={look.statusBar} />
      <PageHeader
        title={title}
        subtitle={open.length === 0 ? 'Niente da fare' : `${open.length} da fare`}
        onBack={() => router.back()}
      />
      <FlatList
        data={open}
        keyExtractor={(t) => t.id}
        contentContainerStyle={styles.list}
        keyboardShouldPersistTaps="handled"
        renderItem={({ item, index }) => (
          <TaskCard
            task={item}
            index={index}
            onToggle={() => toggleDone(item)}
            onImportant={() => toggleImportant(item)}
            onOpen={() => open_(item)}
          />
        )}
        ListEmptyComponent={
          <Text style={[styles.empty, { color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 2 }]}>
            Qui non c'è ancora niente. Aggiungi la prima attività qui sotto.
          </Text>
        }
        ListFooterComponent={
          done.length > 0 ? (
            <View style={styles.doneBlock}>
              <Pressable
                onPress={() => setShowDone((v) => !v)}
                accessibilityRole="button"
                accessibilityState={{ expanded: showDone }}
                style={styles.doneHeader}
              >
                <Icon name={showDone ? 'chevronDown' : 'chevronRight'} size={20} color={colors.onTint} strokeWidth={2.4} />
                <Text style={{ color: colors.onTint, fontFamily: look.fonts.strong, fontSize: look.sizes.strong + 1 }}>
                  {look.copy.completed(done.length)}
                </Text>
              </Pressable>
              {showDone &&
                done.map((t, i) => (
                  <TaskCard
                    key={t.id}
                    task={t}
                    index={i}
                    onToggle={() => toggleDone(t)}
                    onImportant={() => toggleImportant(t)}
                    onOpen={() => open_(t)}
                  />
                ))}
            </View>
          ) : undefined
        }
      />
      <AddBar projects={data.projects} onSubmit={handleAdd} />
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  list: { padding: 16, gap: 8, flexGrow: 1 },
  empty: { textAlign: 'center', marginTop: 40 },
  doneBlock: { gap: 8, marginTop: 4 },
  doneHeader: { flexDirection: 'row', alignItems: 'center', gap: 6, height: 44, alignSelf: 'flex-start' },
});
