import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { Task } from '../db/tasks';
import { clock, startOfDay } from '../lib/dates';
import { useTheme } from '../theme/ThemeProvider';
import { fonts } from '../theme/themes';
import { Icon } from './Icon';

interface Props {
  task: Task;
  onToggle: () => void;
  onImportant: () => void;
}

export function TaskCard({ task, onToggle, onImportant }: Props) {
  const { colors } = useTheme();
  const done = task.doneAt !== null;
  const overdue = !done && task.dueAt !== null && task.dueAt < startOfDay();

  return (
    <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
      <Pressable
        onPress={onToggle}
        accessibilityRole="checkbox"
        accessibilityState={{ checked: done }}
        accessibilityLabel={done ? `Riapri: ${task.title}` : `Segna come fatto: ${task.title}`}
        style={styles.touch}
      >
        <View
          style={[
            styles.circle,
            done
              ? { backgroundColor: colors.primary, borderColor: colors.primary }
              : { borderColor: colors.ring },
          ]}
        >
          {done && <Icon name="check" size={14} color={colors.onPrimary} strokeWidth={3.2} />}
        </View>
      </Pressable>

      <View style={styles.body}>
        <Text
          style={[
            styles.title,
            { color: done ? colors.muted : colors.text },
            done && styles.strike,
          ]}
        >
          {task.title}
        </Text>
        {(task.hasTime || task.projectName || overdue) && (
          <View style={styles.meta}>
            {overdue && (
              <Text style={[styles.metaText, { color: colors.important }]}>In ritardo</Text>
            )}
            {task.hasTime && task.dueAt !== null && (
              <View style={styles.metaItem}>
                <Icon name="clock" size={13} color={colors.muted} />
                <Text style={[styles.metaText, { color: colors.muted }]}>{clock(task.dueAt)}</Text>
              </View>
            )}
            {task.projectName && (
              <View style={styles.metaItem}>
                <View style={[styles.dot, { backgroundColor: task.projectColor ?? colors.muted }]} />
                <Text style={[styles.metaText, { color: colors.muted }]}>{task.projectName}</Text>
              </View>
            )}
          </View>
        )}
      </View>

      <Pressable
        onPress={onImportant}
        accessibilityRole="button"
        accessibilityLabel={task.important ? 'Importante, tocca per toglierlo' : 'Segna come importante'}
        style={styles.touch}
      >
        <Icon
          name="star"
          size={22}
          color={task.important ? colors.important : colors.ring}
          filled={task.important}
          strokeWidth={1.8}
        />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: 14,
    paddingVertical: 4,
    paddingLeft: 6,
    paddingRight: 4,
  },
  touch: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  circle: {
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    alignItems: 'center',
    justifyContent: 'center',
  },
  body: { flex: 1, minWidth: 0, gap: 2, paddingVertical: 6 },
  title: { fontSize: 16, fontFamily: fonts.semibold },
  strike: { textDecorationLine: 'line-through' },
  meta: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  metaItem: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  metaText: { fontSize: 13, fontFamily: fonts.medium },
  dot: { width: 8, height: 8, borderRadius: 4 },
});
