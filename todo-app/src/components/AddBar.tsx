import { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { dueLabel } from '../lib/dates';
import { parseQuickAdd, type ProjectRef, type QuickAddResult } from '../lib/quickAdd';
import { useTheme } from '../theme/ThemeProvider';
import { fonts } from '../theme/themes';
import { Icon, type IconName } from './Icon';

interface Props {
  projects: ProjectRef[];
  onSubmit: (parsed: QuickAddResult) => void;
}

// Barra "Aggiungi un'attività": si scrive una frase sola, ad esempio
// "Chiama Marco domani alle 15 #lavoro !importante", e sopra compaiono i chip
// di quello che l'app ha capito. Il microfono (step 6) si innesta qui.
export function AddBar({ projects, onSubmit }: Props) {
  const { colors } = useTheme();
  const [text, setText] = useState('');

  const parsed = useMemo(() => (text.trim() ? parseQuickAdd(text, projects) : null), [text, projects]);

  const submit = () => {
    if (!parsed) return;
    onSubmit(parsed);
    setText('');
  };

  const chips: { key: string; icon?: IconName; dot?: string; label: string; hot?: boolean }[] = [];
  if (parsed) {
    if (parsed.dueAt !== null) chips.push({ key: 'due', icon: 'calendar', label: dueLabel(parsed.dueAt, parsed.hasTime) });
    if (parsed.project) chips.push({ key: 'project', dot: parsed.project.color ?? colors.muted, label: parsed.project.name });
    if (parsed.important) chips.push({ key: 'imp', icon: 'star', label: 'Importante', hot: true });
    if (parsed.remindMinutes !== null) chips.push({ key: 'rem', icon: 'bell', label: `${parsed.remindMinutes} min prima` });
  }

  return (
    <View style={styles.wrap}>
      {chips.length > 0 && (
        <View style={styles.chips} accessibilityLiveRegion="polite">
          {chips.map((c) => (
            <View
              key={c.key}
              style={[styles.chip, { backgroundColor: c.hot ? colors.important + '22' : colors.tint }]}
            >
              {c.icon && (
                <Icon
                  name={c.icon}
                  size={14}
                  color={c.hot ? colors.important : colors.onTint}
                  filled={c.icon === 'star'}
                  strokeWidth={2}
                />
              )}
              {c.dot && <View style={[styles.dot, { backgroundColor: c.dot }]} />}
              <Text style={[styles.chipText, { color: c.hot ? colors.important : colors.onTint }]}>{c.label}</Text>
            </View>
          ))}
        </View>
      )}

      <View
        style={[
          styles.bar,
          { backgroundColor: colors.card, borderColor: colors.border, shadowColor: colors.text },
        ]}
      >
        <Pressable onPress={submit} accessibilityRole="button" accessibilityLabel="Aggiungi attività" style={styles.plus}>
          <Icon name="plus" size={22} color={colors.primary} strokeWidth={2.4} />
        </Pressable>
        <TextInput
          value={text}
          onChangeText={setText}
          onSubmitEditing={submit}
          returnKeyType="done"
          placeholder="Aggiungi un'attività"
          placeholderTextColor={colors.muted}
          accessibilityLabel="Titolo della nuova attività"
          style={[styles.input, { color: colors.text }]}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginHorizontal: 16, marginBottom: 12, gap: 8 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, paddingHorizontal: 4 },
  chip: { flexDirection: 'row', alignItems: 'center', gap: 5, height: 30, paddingHorizontal: 11, borderRadius: 15 },
  chipText: { fontSize: 13, fontFamily: fonts.bold },
  dot: { width: 8, height: 8, borderRadius: 4 },
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 56,
    paddingHorizontal: 6,
    borderRadius: 28,
    borderWidth: 1,
    elevation: 4,
    shadowOpacity: 0.1,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
  },
  plus: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  input: { flex: 1, fontSize: 15, fontFamily: fonts.semibold, paddingVertical: 0, paddingRight: 12 },
});
