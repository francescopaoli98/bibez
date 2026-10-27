import { useCallback, useMemo } from 'react';
import { SectionList, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router } from 'expo-router';
import type { SQLiteDatabase } from 'expo-sqlite';
import { PageHeader } from '../../components/Banner';
import { TaskCard } from '../../components/TaskCard';
import { useLoad, useTaskActions } from '../../db/hooks';
import { listUpcoming, type Task } from '../../db/tasks';
import { dayHeader, startOfDay } from '../../lib/dates';
import { useTheme } from '../../theme/ThemeProvider';

// Le attività dei prossimi giorni, raggruppate per giorno
export default function InArrivoScreen() {
  const { colors, look } = useTheme();
  const loader = useCallback((db: SQLiteDatabase) => listUpcoming(db), []);
  const { data, reload } = useLoad<Task[]>(loader, []);
  const { toggleDone, toggleImportant } = useTaskActions(reload);

  const sections = useMemo(() => {
    const byDay = new Map<number, Task[]>();
    for (const t of data) {
      const key = startOfDay(new Date(t.dueAt ?? 0));
      byDay.set(key, [...(byDay.get(key) ?? []), t]);
    }
    return [...byDay.entries()]
      .sort((a, b) => a[0] - b[0])
      .map(([day, tasks]) => ({ day, title: dayHeader(day), data: tasks }));
  }, [data]);

  const labelStyle = {
    color: colors.muted,
    fontFamily: look.fonts.label,
    fontSize: look.sizes.label,
    letterSpacing: look.upperMeta ? 0 : 0.7,
  };

  return (
    <View style={[styles.screen, { backgroundColor: colors.bg }]}>
      <StatusBar style={look.statusBar} />
      <PageHeader
        title="In arrivo"
        subtitle={data.length === 0 ? 'Niente in programma' : `${data.length} da fare nei prossimi giorni`}
      />
      <SectionList
        sections={sections}
        keyExtractor={(t) => t.id}
        contentContainerStyle={styles.list}
        stickySectionHeadersEnabled={false}
        renderSectionHeader={({ section }) => (
          <Text style={[labelStyle, styles.header]}>{look.upperMeta ? section.title.toUpperCase() : section.title}</Text>
        )}
        renderItem={({ item, index }) => (
          <View style={styles.item}>
            <TaskCard
              task={item}
              index={index}
              onToggle={() => toggleDone(item)}
              onImportant={() => toggleImportant(item)}
              onOpen={() => router.push(`/attivita/${item.id}`)}
            />
          </View>
        )}
        ListEmptyComponent={
          <Text style={[styles.empty, { color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 2 }]}>
            Niente in programma. Nella barra di Oggi scrivi una data, ad esempio «domani alle 15», e l'attività finisce qui.
          </Text>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  list: { padding: 16, paddingBottom: 32, flexGrow: 1 },
  header: { paddingHorizontal: 8, paddingTop: 16, paddingBottom: 8 },
  item: { marginBottom: 8 },
  empty: { textAlign: 'center', marginTop: 40, paddingHorizontal: 16 },
});
