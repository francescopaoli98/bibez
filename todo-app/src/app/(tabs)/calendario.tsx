import { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router } from 'expo-router';
import type { SQLiteDatabase } from 'expo-sqlite';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Icon } from '../../components/Icon';
import { TaskCard } from '../../components/TaskCard';
import { useLoad, useTaskActions } from '../../db/hooks';
import { daysWithTasks, listDay, type Task } from '../../db/tasks';
import { dayHeader, monthLabel, startOfDay } from '../../lib/dates';
import { useTheme } from '../../theme/ThemeProvider';

const WEEK = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

// Calendario del mese con un puntino sui giorni che hanno attività
export default function CalendarioScreen() {
  const { colors, look, scheme } = useTheme();
  const insets = useSafeAreaInsets();
  const square = look.cardRadii[0] === 0;

  const [month, setMonth] = useState(() => {
    const n = new Date();
    return new Date(n.getFullYear(), n.getMonth(), 1);
  });
  const [selected, setSelected] = useState(() => startOfDay());

  const from = month.getTime();
  const to = new Date(month.getFullYear(), month.getMonth() + 1, 1).getTime();
  const monthLoader = useCallback((db: SQLiteDatabase) => daysWithTasks(db, from, to), [from, to]);
  const dayLoader = useCallback((db: SQLiteDatabase) => listDay(db, selected), [selected]);
  const { data: marked, reload: reloadMonth } = useLoad<Set<number>>(monthLoader, new Set());
  const { data: tasks, reload: reloadDay } = useLoad<Task[]>(dayLoader, []);
  const reloadAll = useCallback(async () => {
    await Promise.all([reloadMonth(), reloadDay()]);
  }, [reloadMonth, reloadDay]);
  const { toggleDone, toggleImportant } = useTaskActions(reloadAll);

  // Celle del mese: prima i vuoti (settimana da lunedì), poi i giorni
  const cells = useMemo(() => {
    const lead = (month.getDay() + 6) % 7;
    const count = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
    return [
      ...Array.from({ length: lead }, () => null),
      ...Array.from({ length: count }, (_, i) => new Date(month.getFullYear(), month.getMonth(), i + 1).getTime()),
    ];
  }, [month]);

  const today = startOfDay();
  const go = (delta: number) => {
    const next = new Date(month.getFullYear(), month.getMonth() + delta, 1);
    setMonth(next);
    const now = new Date();
    const isThisMonth = next.getFullYear() === now.getFullYear() && next.getMonth() === now.getMonth();
    setSelected(isThisMonth ? startOfDay() : next.getTime());
  };

  const textFont = { fontFamily: look.fonts.strong };
  return (
    <View style={[styles.screen, { backgroundColor: colors.bg }]}>
      <StatusBar style={scheme === 'dark' ? 'light' : 'dark'} />
      <ScrollView contentContainerStyle={[styles.content, { paddingTop: insets.top + 12 }]}>
        <View style={styles.head}>
          <Text
            style={{
              color: colors.text,
              fontFamily: look.fonts.title,
              fontSize: Math.min(look.titleSize, 30),
              letterSpacing: look.titleTracking,
              flex: 1,
            }}
          >
            {look.upperMeta ? monthLabel(month).toUpperCase() : monthLabel(month)}
          </Text>
          <Pressable onPress={() => go(-1)} accessibilityRole="button" accessibilityLabel="Mese precedente" style={styles.arrow}>
            <Icon name="chevronLeft" size={22} color={colors.text} strokeWidth={2.2} />
          </Pressable>
          <Pressable onPress={() => go(1)} accessibilityRole="button" accessibilityLabel="Mese successivo" style={styles.arrow}>
            <Icon name="chevronRight" size={22} color={colors.text} strokeWidth={2.2} />
          </Pressable>
        </View>

        <View style={[styles.month, { backgroundColor: colors.card, borderColor: colors.border, borderRadius: square ? 0 : 20 }]}>
          <View style={styles.row}>
            {WEEK.map((w, i) => (
              <Text key={i} style={[styles.weekday, { color: colors.muted }, textFont]}>
                {w}
              </Text>
            ))}
          </View>
          <View style={styles.grid}>
            {cells.map((ms, i) => {
              if (ms === null) return <View key={`e${i}`} style={styles.cell} />;
              const on = ms === selected;
              const isToday = ms === today;
              const day = new Date(ms).getDate();
              return (
                <Pressable
                  key={ms}
                  onPress={() => setSelected(ms)}
                  accessibilityRole="button"
                  accessibilityLabel={`${day} ${monthLabel(month)}${marked.has(ms) ? ', con attività' : ''}`}
                  accessibilityState={{ selected: on }}
                  style={styles.cell}
                >
                  <View
                    style={[
                      styles.day,
                      { borderRadius: square ? 0 : 18 },
                      on && { backgroundColor: colors.primary },
                      !on && isToday && { borderWidth: 2, borderColor: colors.primary },
                    ]}
                  >
                    <Text style={[{ color: on ? colors.onPrimary : colors.text, fontSize: 16 }, textFont]}>{day}</Text>
                  </View>
                  <View style={[styles.dot, { backgroundColor: marked.has(ms) ? colors.important : 'transparent' }]} />
                </Pressable>
              );
            })}
          </View>
        </View>

        <Text
          style={{
            color: colors.muted,
            fontFamily: look.fonts.label,
            fontSize: look.sizes.label,
            letterSpacing: look.upperMeta ? 0 : 0.7,
            paddingHorizontal: 8,
            paddingTop: 8,
          }}
        >
          {(look.upperMeta ? dayHeader(selected).toUpperCase() : dayHeader(selected)).replace('Domani · ', '')}
        </Text>

        {tasks.length === 0 ? (
          <Text style={{ color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 2, paddingHorizontal: 8 }}>
            Niente in programma.
          </Text>
        ) : (
          tasks.map((t, i) => (
            <TaskCard
              key={t.id}
              task={t}
              index={i}
              onToggle={() => toggleDone(t)}
              onImportant={() => toggleImportant(t)}
              onOpen={() => router.push(`/attivita/${t.id}`)}
            />
          ))
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  content: { padding: 16, paddingBottom: 32, gap: 8 },
  head: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 8 },
  arrow: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  month: { padding: 8, borderWidth: 1 },
  row: { flexDirection: 'row', paddingBottom: 4 },
  weekday: { flex: 1, textAlign: 'center', fontSize: 12 },
  grid: { flexDirection: 'row', flexWrap: 'wrap' },
  cell: { width: `${100 / 7}%`, height: 48, alignItems: 'center', justifyContent: 'center' },
  day: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
  dot: { width: 5, height: 5, borderRadius: 3, marginTop: 1 },
});
