import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Banner, Progress } from '../components/Banner';
import { Icon } from '../components/Icon';
import { useTheme } from '../theme/ThemeProvider';
import { useThemeSwitcher } from '../theme/ThemeTransition';
import { fonts, type Mode } from '../theme/themes';

const MODES: { id: Mode; label: string }[] = [
  { id: 'light', label: 'Chiaro' },
  { id: 'dark', label: 'Scuro' },
  { id: 'auto', label: 'Auto' },
];

export default function TemiScreen() {
  const { colors, scheme, theme, themes, mode } = useTheme();
  const { switchTheme, switchMode } = useThemeSwitcher();

  return (
    <View style={[styles.screen, { backgroundColor: colors.bg }]}>
      <StatusBar style="light" />

      <Banner>
        <View style={styles.titleRow}>
          <Pressable onPress={() => router.back()} accessibilityRole="button" accessibilityLabel="Indietro" style={styles.back}>
            <Icon name="chevronLeft" size={24} color="#FFFFFF" strokeWidth={2.2} />
          </Pressable>
          <Text style={styles.screenTitle}>Temi</Text>
        </View>
        <View>
          <Text style={styles.preview}>Anteprima · {theme.name}</Text>
          <Text style={styles.title}>Oggi</Text>
        </View>
        <Progress done={2} total={6} />
      </Banner>

      <ScrollView contentContainerStyle={styles.content}>
        <Text style={[styles.label, { color: colors.muted }]}>ASPETTO</Text>
        <View style={[styles.segmented, { backgroundColor: scheme === 'dark' ? colors.card : '#E3E5F3' }]}>
          {MODES.map((m) => {
            const on = mode === m.id;
            return (
              <Pressable
                key={m.id}
                onPress={() => switchMode(m.id)}
                accessibilityRole="button"
                accessibilityState={{ selected: on }}
                style={[styles.segment, on && { backgroundColor: colors.tint }]}
              >
                <Text style={[styles.segmentText, { color: on ? colors.onTint : colors.muted }]}>{m.label}</Text>
              </Pressable>
            );
          })}
        </View>

        <Text style={[styles.label, { color: colors.muted, marginTop: 8 }]}>TEMI</Text>
        <View style={styles.grid}>
          {themes.map((t) => {
            const on = t.id === theme.id;
            const accent = t[scheme];
            return (
              <Pressable
                key={t.id}
                onPress={() => switchTheme(t.id)}
                accessibilityRole="button"
                accessibilityLabel={`Tema ${t.name}`}
                accessibilityState={{ selected: on }}
                style={[
                  styles.card,
                  { backgroundColor: colors.card, borderColor: on ? colors.primary : colors.border },
                ]}
              >
                <View style={[styles.mini, { backgroundColor: colors.bg }]}>
                  <LinearGradient
                    colors={accent.gradient}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.miniBanner}
                  />
                  <View style={[styles.miniRow, { backgroundColor: colors.card }]} />
                  <View style={[styles.miniRow, { backgroundColor: colors.card }]} />
                </View>
                <View style={styles.cardFooter}>
                  <Text style={[styles.cardName, { color: colors.text }]}>{t.name}</Text>
                  {on && (
                    <View style={[styles.badge, { backgroundColor: colors.primary }]}>
                      <Icon name="check" size={12} color={colors.onPrimary} strokeWidth={3.4} />
                    </View>
                  )}
                </View>
              </Pressable>
            );
          })}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginLeft: -10 },
  back: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  screenTitle: { color: '#FFFFFF', fontSize: 20, fontFamily: fonts.extrabold },
  preview: { color: '#FFFFFF', fontSize: 14, fontFamily: fonts.medium },
  title: { color: '#FFFFFF', fontSize: 34, fontFamily: fonts.extrabold, letterSpacing: -0.8 },
  content: { padding: 16, paddingTop: 20, gap: 12 },
  label: { fontSize: 12, fontFamily: fonts.bold, letterSpacing: 0.7, paddingHorizontal: 8 },
  segmented: { flexDirection: 'row', padding: 4, borderRadius: 14, gap: 4 },
  segment: { flex: 1, height: 40, borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
  segmentText: { fontSize: 14, fontFamily: fonts.bold },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  card: { width: '47.8%', padding: 8, paddingBottom: 12, borderRadius: 18, borderWidth: 2, gap: 10 },
  mini: { height: 76, borderRadius: 12, overflow: 'hidden', gap: 6 },
  miniBanner: { height: 34 },
  miniRow: { height: 10, marginHorizontal: 8, borderRadius: 5 },
  cardFooter: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 2 },
  cardName: { fontSize: 14, fontFamily: fonts.bold },
  badge: { width: 20, height: 20, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
});
