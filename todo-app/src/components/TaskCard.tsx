import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { Task } from '../db/tasks';
import { clock, startOfDay } from '../lib/dates';
import { useTheme } from '../theme/ThemeProvider';
import { Icon } from './Icon';

interface Props {
  task: Task;
  index: number; // posizione nella lista (serve a "TAKE 01" e all'inclinazione dell'Atelier)
  onToggle: () => void;
  onImportant: () => void;
  onOpen?: () => void; // tocco sul titolo: apre il dettaglio
}

export function TaskCard({ task, index, onToggle, onImportant, onOpen }: Props) {
  const { colors, look } = useTheme();
  const done = task.doneAt !== null;
  const overdue = !done && task.dueAt !== null && task.dueAt < startOfDay();
  const r = look.cardRadii;
  const hard = look.cardShadow === 'hard';
  const tilt = look.cardTilt ? (index % 2 === 0 ? -0.4 : 0.3) : 0;
  const square = look.check === 'square';
  const upper = (s: string) => (look.upperMeta ? s.toUpperCase() : s);
  const metaStyle = { color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta };

  return (
    <View
      style={[
        hard && styles.hardGap,
        tilt !== 0 && { transform: [{ rotate: `${tilt}deg` }] },
      ]}
    >
      {hard && <View style={[StyleSheet.absoluteFill, styles.hardShadow]} />}
      <View
        style={[
          styles.card,
          {
            backgroundColor: colors.card,
            borderColor: colors.border,
            borderWidth: look.cardBorder,
            borderTopLeftRadius: r[0],
            borderTopRightRadius: r[1],
            borderBottomRightRadius: r[2],
            borderBottomLeftRadius: r[3],
          },
          look.cardShadow === 'paper' && { borderBottomWidth: look.cardBorder + 2 },
        ]}
      >
        <Pressable
          onPress={onToggle}
          accessibilityRole="checkbox"
          accessibilityState={{ checked: done }}
          accessibilityLabel={done ? `Riapri: ${task.title}` : `Segna come fatto: ${task.title}`}
          style={styles.touch}
        >
          <View
            style={[
              square ? styles.square : styles.circle,
              done
                ? { backgroundColor: colors.done, borderColor: colors.done }
                : { borderColor: colors.ring },
            ]}
          >
            {done && <Icon name="check" size={14} color={colors.onDone} strokeWidth={square ? 4 : 3.2} />}
          </View>
        </Pressable>

        <Pressable
          onPress={onOpen}
          disabled={!onOpen}
          accessibilityRole="button"
          accessibilityLabel={`Apri: ${task.title}`}
          style={styles.body}
        >
          {look.tag && !done && (
            <Text style={{ color: look.tag.color, fontFamily: look.fonts.label, fontSize: 11, letterSpacing: 1 }}>
              {`TAKE ${String(index + 1).padStart(2, '0')}`}
            </Text>
          )}
          <Text
            style={[
              {
                color: done ? colors.muted : colors.text,
                fontFamily: look.fonts.body,
                fontSize: look.sizes.body,
                lineHeight: Math.round(look.sizes.body * 1.15),
              },
              done && styles.strike,
            ]}
          >
            {task.title}
          </Text>
          {(task.hasTime || task.projectName || overdue || look.reward || task.subTotal > 0) && (
            <View style={styles.meta}>
              {overdue && <Text style={[metaStyle, { color: colors.important }]}>{upper('In ritardo')}</Text>}
              {task.hasTime && task.dueAt !== null && (
                <View style={styles.metaItem}>
                  <Icon name="clock" size={Math.min(look.sizes.meta, 14)} color={colors.muted} />
                  <Text style={metaStyle}>{clock(task.dueAt)}</Text>
                </View>
              )}
              {task.projectName && (
                <View style={styles.metaItem}>
                  <View style={[styles.dot, { backgroundColor: task.projectColor ?? colors.muted }]} />
                  <Text style={metaStyle}>{upper(task.projectName)}</Text>
                </View>
              )}
              {task.subTotal > 0 && (
                <View style={styles.metaItem}>
                  <Icon name="list" size={Math.min(look.sizes.meta, 14)} color={colors.muted} />
                  <Text style={metaStyle}>
                    {task.subDone}/{task.subTotal}
                  </Text>
                </View>
              )}
              {look.reward && (
                <Text style={[metaStyle, { color: done ? colors.done : look.reward.color }]}>{look.reward.text}</Text>
              )}
            </View>
          )}
        </Pressable>

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
    </View>
  );
}

const styles = StyleSheet.create({
  hardGap: { marginRight: 4, marginBottom: 4 },
  hardShadow: { backgroundColor: '#000000', transform: [{ translateX: 4 }, { translateY: 4 }] },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
    paddingLeft: 6,
    paddingRight: 4,
  },
  touch: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  circle: { width: 24, height: 24, borderRadius: 12, borderWidth: 2, alignItems: 'center', justifyContent: 'center' },
  square: { width: 22, height: 22, borderRadius: 0, borderWidth: 2, alignItems: 'center', justifyContent: 'center' },
  body: { flex: 1, minWidth: 0, gap: 2, paddingVertical: 6 },
  strike: { textDecorationLine: 'line-through' },
  meta: { flexDirection: 'row', alignItems: 'center', gap: 10, flexWrap: 'wrap' },
  metaItem: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  dot: { width: 8, height: 8, borderRadius: 4 },
});
