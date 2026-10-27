import type { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useTheme } from '../theme/ThemeProvider';
import { Icon, type IconName } from './Icon';

// Piccola etichetta di sezione (es. "LE MIE LISTE")
export function SectionLabel({ children }: { children: string }) {
  const { colors, look } = useTheme();
  return (
    <Text
      style={{
        color: colors.muted,
        fontFamily: look.fonts.label,
        fontSize: look.sizes.label,
        letterSpacing: look.upperMeta ? 0 : 0.7,
        paddingHorizontal: 8,
      }}
    >
      {children}
    </Text>
  );
}

interface ChipProps {
  label: string;
  active?: boolean;
  icon?: IconName;
  dot?: string;
  onPress: () => void;
}

// Pulsante a forma di pillola per scegliere tra poche opzioni
export function Chip({ label, active = false, icon, dot, onPress }: ChipProps) {
  const { colors, look } = useTheme();
  const square = look.cardRadii[0] === 0;
  const fg = active ? colors.onPrimary : colors.text;
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityState={{ selected: active }}
      style={[
        styles.chip,
        {
          borderRadius: square ? 0 : 20,
          backgroundColor: active ? colors.primary : colors.card,
          borderColor: active ? colors.primary : colors.border,
        },
      ]}
    >
      {icon && <Icon name={icon} size={16} color={fg} />}
      {dot && <View style={[styles.dot, { backgroundColor: dot }]} />}
      <Text style={{ color: fg, fontFamily: look.fonts.strong, fontSize: look.sizes.strong + 1 }}>{label}</Text>
    </Pressable>
  );
}

// Riquadro bianco (o scuro) che raggruppa delle righe
export function Panel({ children }: { children: ReactNode }) {
  const { colors, look } = useTheme();
  return (
    <View
      style={[
        styles.panel,
        { backgroundColor: colors.card, borderColor: colors.border, borderRadius: look.cardRadii[0] === 0 ? 0 : 18 },
      ]}
    >
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  chip: { flexDirection: 'row', alignItems: 'center', gap: 6, minHeight: 40, paddingHorizontal: 14, borderWidth: 1 },
  dot: { width: 8, height: 8, borderRadius: 4 },
  panel: { borderWidth: 1, overflow: 'hidden' },
});
