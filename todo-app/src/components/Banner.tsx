import type { ReactNode } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeProvider';
import { fonts } from '../theme/themes';

interface Props {
  children: ReactNode;
}

// Testata con il gradiente del tema; i figli vanno in colonna, testo bianco
export function Banner({ children }: Props) {
  const { colors } = useTheme();
  const insets = useSafeAreaInsets();
  return (
    <LinearGradient
      colors={colors.gradient}
      locations={[0, 0.62, 1]}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={[styles.banner, { paddingTop: insets.top + 12 }]}
    >
      {children}
    </LinearGradient>
  );
}

interface ProgressProps {
  done: number;
  total: number;
}

export function Progress({ done, total }: ProgressProps) {
  const pct = total === 0 ? 0 : Math.round((done / total) * 100);
  return (
    <View style={styles.progressRow}>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${pct}%` }]} />
      </View>
      <Text style={styles.progressLabel}>
        {done} di {total} fatte
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    paddingHorizontal: 24,
    paddingBottom: 22,
    borderBottomLeftRadius: 28,
    borderBottomRightRadius: 28,
    gap: 14,
  },
  progressRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  track: { flex: 1, height: 8, borderRadius: 4, backgroundColor: 'rgba(255,255,255,0.3)' },
  fill: { height: 8, borderRadius: 4, backgroundColor: '#FFFFFF' },
  progressLabel: { color: '#FFFFFF', fontSize: 13, fontFamily: fonts.semibold },
});
