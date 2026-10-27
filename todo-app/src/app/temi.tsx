import { Pressable, ScrollView, StyleSheet, Switch, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Banner, BannerTitle, Progress } from '../components/Banner';
import { Icon } from '../components/Icon';
import { useTheme } from '../theme/ThemeProvider';
import { useThemeSwitcher } from '../theme/ThemeTransition';
import { miniFor, type Mode, type ThemeDef } from '../theme/themes';

const MODES: { id: Mode; label: string }[] = [
  { id: 'light', label: 'Chiaro' },
  { id: 'dark', label: 'Scuro' },
  { id: 'auto', label: 'Auto' },
];

export default function TemiScreen() {
  const { colors, look, scheme, theme, themes, mode, soundsOn, setSoundsOn } = useTheme();
  const { switchTheme, switchMode } = useThemeSwitcher();
  const square = look.cardRadii[0] === 0;

  const labelStyle = {
    color: colors.muted,
    fontFamily: look.fonts.label,
    fontSize: look.sizes.label,
    letterSpacing: look.upperMeta ? 0 : 0.7,
  };

  const renderCard = (t: ThemeDef) => {
    const on = t.id === theme.id;
    const mini = miniFor(t, scheme);
    return (
      <Pressable
        key={t.id}
        onPress={() => switchTheme(t.id)}
        accessibilityRole="button"
        accessibilityLabel={`Tema ${t.name}`}
        accessibilityState={{ selected: on }}
        style={[
          styles.card,
          {
            backgroundColor: colors.card,
            borderColor: on ? colors.primary : colors.border,
            borderRadius: square ? 0 : 16,
          },
        ]}
      >
        <View style={[styles.mini, { backgroundColor: mini.bg, borderRadius: square ? 0 : 9 }]}>
          <LinearGradient colors={mini.banner} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.miniBanner} />
          <View style={[styles.miniRow, { backgroundColor: mini.row, borderRadius: square ? 0 : 3 }]} />
          <View style={[styles.miniRow, { backgroundColor: mini.row, borderRadius: square ? 0 : 3 }]} />
        </View>
        <View style={styles.cardFooter}>
          <Text style={{ color: colors.text, fontFamily: look.fonts.strong, fontSize: look.sizes.strong + 1 }}>{t.name}</Text>
          {on && (
            <View style={[styles.badge, { backgroundColor: colors.primary, borderRadius: square ? 0 : 9 }]}>
              <Icon name="check" size={11} color={colors.onPrimary} strokeWidth={3.4} />
            </View>
          )}
        </View>
      </Pressable>
    );
  };

  return (
    <View style={[styles.screen, { backgroundColor: colors.bg }]}>
      <StatusBar style={look.statusBar} />

      <Banner>
        <View style={styles.titleRow}>
          <Pressable onPress={() => router.back()} accessibilityRole="button" accessibilityLabel="Indietro" style={styles.back}>
            <Icon name="chevronLeft" size={24} color={colors.onBanner} strokeWidth={2.2} />
          </Pressable>
          <Text style={{ color: colors.onBanner, fontFamily: look.fonts.title, fontSize: 20 }}>
            {look.upperMeta ? 'TEMI' : 'Temi'}
          </Text>
        </View>
        <BannerTitle greeting={`Anteprima · ${theme.name}`} />
        <Progress done={2} total={6} level={4} xp={240} xpMax={400} />
      </Banner>

      <ScrollView contentContainerStyle={styles.content}>
        <Text style={[labelStyle, styles.label]}>ASPETTO</Text>
        {theme.special ? (
          <View style={[styles.note, { borderColor: colors.border, borderRadius: square ? 0 : 14 }]}>
            <Text style={{ color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 1 }}>
              Questo tema ha un aspetto tutto suo: Chiaro e Scuro non si applicano.
            </Text>
          </View>
        ) : (
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
                  <Text
                    style={{
                      color: on ? colors.onTint : colors.muted,
                      fontFamily: look.fonts.strong,
                      fontSize: look.sizes.strong + 1,
                    }}
                  >
                    {m.label}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        )}

        <Text style={[labelStyle, styles.label, { marginTop: 8 }]}>TEMI</Text>
        <View style={styles.grid}>{themes.filter((t) => !t.special).map(renderCard)}</View>

        <Text style={[labelStyle, styles.label, { marginTop: 8 }]}>TEMI SPECIALI</Text>
        <View style={styles.grid}>{themes.filter((t) => t.special).map(renderCard)}</View>

        <Text style={[labelStyle, styles.label, { marginTop: 8 }]}>SUONI</Text>
        <View style={[styles.soundRow, { backgroundColor: colors.card, borderColor: colors.border, borderRadius: square ? 0 : 14 }]}>
          <Icon name="volume" size={22} color={colors.primary} />
          <View style={styles.soundText}>
            <Text style={{ color: colors.text, fontFamily: look.fonts.body, fontSize: look.sizes.body }}>Effetti sonori</Text>
            <Text style={{ color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta }}>
              Un suono diverso per ogni tema quando lo cambi
            </Text>
          </View>
          <Switch
            value={soundsOn}
            onValueChange={setSoundsOn}
            accessibilityLabel="Effetti sonori"
            trackColor={{ false: colors.border, true: colors.primary }}
            thumbColor={colors.card}
          />
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  titleRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginLeft: -10 },
  back: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  content: { padding: 16, paddingTop: 20, paddingBottom: 40, gap: 10 },
  label: { paddingHorizontal: 8 },
  note: { borderWidth: 1, borderStyle: 'dashed', padding: 12 },
  segmented: { flexDirection: 'row', padding: 4, borderRadius: 14, gap: 4 },
  segment: { flex: 1, height: 36, borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  card: { width: '31.6%', padding: 5, paddingBottom: 8, borderWidth: 2, gap: 6 },
  mini: { height: 44, overflow: 'hidden', gap: 4 },
  miniBanner: { height: 20 },
  miniRow: { height: 6, marginHorizontal: 5 },
  cardFooter: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 2 },
  badge: { width: 18, height: 18, alignItems: 'center', justifyContent: 'center' },
  soundRow: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 14, borderWidth: 1 },
  soundText: { flex: 1, gap: 2 },
});
