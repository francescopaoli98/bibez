import { useMemo, useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { dueLabel } from '../lib/dates';
import { parseQuickAdd, type ProjectRef, type QuickAddResult } from '../lib/quickAdd';
import { useTheme } from '../theme/ThemeProvider';
import { Icon, type IconName } from './Icon';

interface Props {
  projects: ProjectRef[];
  onSubmit: (parsed: QuickAddResult) => void;
}

// Barra "Aggiungi un'attività": si scrive una frase sola, ad esempio
// "Chiama Marco domani alle 15 #lavoro !importante", e sopra compaiono i chip
// di quello che l'app ha capito. Il microfono (step 6) si innesta qui.
export function AddBar({ projects, onSubmit }: Props) {
  const { colors, look } = useTheme();
  const [text, setText] = useState('');
  const bar = look.addBar;

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
  const upper = (s: string) => (look.upperMeta ? s.toUpperCase() : s);
  const chipRadius = bar.radius === 0 ? 0 : 15;

  return (
    <View style={styles.wrap}>
      {chips.length > 0 && (
        <View style={styles.chips} accessibilityLiveRegion="polite">
          {chips.map((c) => (
            <View
              key={c.key}
              style={[
                styles.chip,
                { borderRadius: chipRadius, backgroundColor: c.hot ? colors.important + '22' : colors.tint },
              ]}
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
              <Text
                style={{
                  color: c.hot ? colors.important : colors.onTint,
                  fontFamily: look.fonts.strong,
                  fontSize: look.sizes.strong,
                }}
              >
                {upper(c.label)}
              </Text>
            </View>
          ))}
        </View>
      )}

      <View style={styles.barBox}>
        {bar.hardShadow && <View style={[StyleSheet.absoluteFill, styles.hardShadow]} />}
        <View
          style={[
            styles.bar,
            {
              backgroundColor: colors.card,
              borderColor: bar.color ?? colors.border,
              borderWidth: bar.borderWidth,
              borderStyle: bar.dashed ? 'dashed' : 'solid',
              borderRadius: bar.radius,
              shadowColor: colors.text,
            },
            !bar.hardShadow && styles.softShadow,
          ]}
        >
          <Pressable onPress={submit} accessibilityRole="button" accessibilityLabel="Aggiungi attività" style={styles.leading}>
            {bar.leading === 'rec' ? (
              <View style={[styles.rec, { backgroundColor: colors.primary }]} />
            ) : (
              <Icon
                name={bar.leading === 'pencil' ? 'pencil' : 'plus'}
                size={22}
                color={colors.primary}
                strokeWidth={bar.leading === 'plus' ? 2.4 : 1.9}
              />
            )}
          </Pressable>
          <TextInput
            value={text}
            onChangeText={setText}
            onSubmitEditing={submit}
            returnKeyType="done"
            placeholder={look.copy.add}
            placeholderTextColor={colors.muted}
            accessibilityLabel="Titolo della nuova attività"
            style={[
              styles.input,
              { color: colors.text, fontFamily: look.fonts.body, fontSize: Math.max(15, look.sizes.body - 1) },
            ]}
          />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginHorizontal: 16, marginBottom: 12, gap: 8 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, paddingHorizontal: 4 },
  chip: { flexDirection: 'row', alignItems: 'center', gap: 5, height: 30, paddingHorizontal: 11 },
  dot: { width: 8, height: 8, borderRadius: 4 },
  barBox: { marginRight: 4, marginBottom: 4 },
  hardShadow: { backgroundColor: '#000000', transform: [{ translateX: 4 }, { translateY: 4 }] },
  bar: { flexDirection: 'row', alignItems: 'center', height: 56, paddingHorizontal: 6 },
  softShadow: {
    elevation: 4,
    shadowOpacity: 0.1,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
  },
  leading: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  rec: { width: 12, height: 12, borderRadius: 6 },
  input: { flex: 1, paddingVertical: 0, paddingRight: 12 },
});
