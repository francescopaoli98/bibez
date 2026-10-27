import { useState } from 'react';
import { Pressable, StyleSheet, TextInput, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { fonts } from '../theme/themes';
import { Icon } from './Icon';

interface Props {
  onSubmit: (title: string) => void;
}

// Barra "Aggiungi un'attività" fissa in basso. Il quick add con data e tag
// (step 3) e il microfono (step 6) si innestano qui.
export function AddBar({ onSubmit }: Props) {
  const { colors } = useTheme();
  const [text, setText] = useState('');

  const submit = () => {
    const title = text.trim();
    if (!title) return;
    onSubmit(title);
    setText('');
  };

  return (
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
  );
}

const styles = StyleSheet.create({
  bar: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 56,
    marginHorizontal: 16,
    marginBottom: 12,
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
