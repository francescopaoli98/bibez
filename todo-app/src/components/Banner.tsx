import type { ReactNode } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Svg, { Defs, Ellipse, Path, Pattern, RadialGradient, Rect, Stop } from 'react-native-svg';
import { useTheme } from '../theme/ThemeProvider';

// Altezze delle barre della "forma d'onda" del tema Studio
const WAVE = [24, 48, 80, 40, 104, 60, 16, 72, 116, 52, 32, 92, 64, 20, 100, 56, 28, 84, 112, 44, 68, 20, 88, 48, 76, 28, 96, 40, 12];

// Lo sfondo della testata cambia da tema a tema
function BannerBackground() {
  const { colors, look } = useTheme();

  if (look.banner === 'pixel') {
    return (
      <>
        <LinearGradient
          colors={[colors.gradient[0], colors.gradient[1]]}
          start={{ x: 0, y: 0 }}
          end={{ x: 0, y: 1 }}
          style={StyleSheet.absoluteFill}
        />
        <Svg style={StyleSheet.absoluteFill}>
          <Defs>
            <Pattern id="grid" width="12" height="12" patternUnits="userSpaceOnUse">
              <Path d="M12 0H0V12" fill="none" stroke="rgba(255,255,255,0.07)" strokeWidth="1" />
            </Pattern>
          </Defs>
          <Rect width="100%" height="100%" fill="url(#grid)" />
        </Svg>
        <View style={[styles.bottomLine, { height: 4, backgroundColor: colors.primary }]} />
      </>
    );
  }

  if (look.banner === 'watercolor') {
    return (
      <Svg style={StyleSheet.absoluteFill}>
        <Defs>
          <RadialGradient id="w1" cx="50%" cy="50%" r="50%">
            <Stop offset="0" stopColor="#F2B38A" stopOpacity="0.95" />
            <Stop offset="1" stopColor="#F2B38A" stopOpacity="0" />
          </RadialGradient>
          <RadialGradient id="w2" cx="50%" cy="50%" r="50%">
            <Stop offset="0" stopColor="#E7C06B" stopOpacity="0.9" />
            <Stop offset="1" stopColor="#E7C06B" stopOpacity="0" />
          </RadialGradient>
          <RadialGradient id="w3" cx="50%" cy="50%" r="50%">
            <Stop offset="0" stopColor="#C98BA8" stopOpacity="0.85" />
            <Stop offset="1" stopColor="#C98BA8" stopOpacity="0" />
          </RadialGradient>
        </Defs>
        <Rect width="100%" height="100%" fill="#FBEBD6" />
        <Ellipse cx="12%" cy="35%" rx="55%" ry="90%" fill="url(#w1)" />
        <Ellipse cx="85%" cy="18%" rx="50%" ry="80%" fill="url(#w2)" />
        <Ellipse cx="62%" cy="105%" rx="60%" ry="90%" fill="url(#w3)" />
      </Svg>
    );
  }

  if (look.banner === 'studio') {
    return (
      <>
        <View style={[StyleSheet.absoluteFill, { backgroundColor: colors.gradient[0] }]} />
        <Svg
          width="100%"
          height={120}
          viewBox="0 0 342 120"
          preserveAspectRatio="none"
          style={styles.waveform}
        >
          {WAVE.map((h, i) => (
            <Rect key={i} x={2 + i * 11.6} y={(120 - h) / 2} width={5} height={h} rx={2.5} fill={colors.primary} opacity={0.22} />
          ))}
        </Svg>
        <View style={[styles.bottomLine, { height: 1, backgroundColor: colors.border }]} />
      </>
    );
  }

  return (
    <LinearGradient
      colors={colors.gradient}
      locations={[0, 0.62, 1]}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={StyleSheet.absoluteFill}
    />
  );
}

interface BannerProps {
  children: ReactNode;
}

// Testata della schermata: sfondo del tema + contenuti in colonna
export function Banner({ children }: BannerProps) {
  const { look } = useTheme();
  const insets = useSafeAreaInsets();
  const r = look.bannerRadii;
  return (
    <View
      style={[
        styles.banner,
        {
          paddingTop: insets.top + 12,
          borderTopLeftRadius: r[0],
          borderTopRightRadius: r[1],
          borderBottomRightRadius: r[2],
          borderBottomLeftRadius: r[3],
        },
      ]}
    >
      <BannerBackground />
      {children}
    </View>
  );
}

interface TitleProps {
  greeting: string;
  subtitle?: string;
}

// Saluto + titolo + sottotitolo, con carattere e ombra del tema
export function BannerTitle({ greeting, subtitle }: TitleProps) {
  const { colors, look } = useTheme();
  return (
    <View>
      <Text style={{ color: colors.onBanner, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 2 }}>{greeting}</Text>
      <Text
        style={{
          color: colors.onBanner,
          fontFamily: look.fonts.title,
          fontSize: look.titleSize,
          letterSpacing: look.titleTracking,
          paddingVertical: 2,
          ...(look.titleShadow
            ? { textShadowColor: look.titleShadow, textShadowOffset: { width: 3, height: 3 }, textShadowRadius: 0 }
            : null),
        }}
      >
        {look.titleText}
      </Text>
      {subtitle ? (
        <Text style={{ color: colors.onBanner, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 1 }}>{subtitle}</Text>
      ) : null}
    </View>
  );
}

interface ProgressProps {
  done: number;
  total: number;
  level?: number;
  xp?: number;
  xpMax?: number;
}

const VU_SEGMENTS = 24;
const XP_BLOCKS = 10;
const BRUSH_PATH = 'M6 14 C 60 6, 110 20, 170 12 S 280 8, 336 14';
const BRUSH_LENGTH = 340; // lunghezza approssimata del tratto, per riempirlo in proporzione

// Barra di avanzamento: lineare, XP a blocchi, pennellata o VU-meter a seconda del tema
export function Progress({ done, total, level = 1, xp = 0, xpMax = 400 }: ProgressProps) {
  const { colors, look } = useTheme();
  const fraction = total === 0 ? 0 : done / total;
  const label = look.copy.progress(done, total, level, xp, xpMax);
  const labelStyle = { color: colors.onBanner, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 1 };

  if (look.progress === 'xp') {
    const lit = Math.round((xp / xpMax) * XP_BLOCKS);
    return (
      <View style={styles.stack}>
        <View style={styles.segments}>
          {Array.from({ length: XP_BLOCKS }, (_, i) => (
            <View key={i} style={[styles.block, { backgroundColor: i < lit ? colors.primary : colors.border }]} />
          ))}
        </View>
        <Text style={labelStyle}>{label}</Text>
      </View>
    );
  }

  if (look.progress === 'vu') {
    const lit = Math.round(fraction * VU_SEGMENTS);
    return (
      <View style={styles.stack}>
        <View style={styles.segments}>
          {Array.from({ length: VU_SEGMENTS }, (_, i) => {
            const on = i < lit;
            const hue = i < 16 ? colors.done : i < 21 ? colors.important : colors.primary;
            return <View key={i} style={[styles.vu, { backgroundColor: on ? hue : colors.border }]} />;
          })}
        </View>
        <Text style={labelStyle}>{label}</Text>
      </View>
    );
  }

  if (look.progress === 'brush') {
    return (
      <View style={styles.row}>
        <Svg width="100%" height={26} viewBox="0 0 342 26" preserveAspectRatio="none" style={styles.flex}>
          <Path d={BRUSH_PATH} fill="none" stroke={colors.onBanner + '26'} strokeWidth={12} strokeLinecap="round" />
          {fraction > 0 && (
            <Path
              d={BRUSH_PATH}
              fill="none"
              stroke={colors.primary}
              strokeWidth={12}
              strokeLinecap="round"
              strokeDasharray={[BRUSH_LENGTH * fraction, BRUSH_LENGTH * 2]}
            />
          )}
        </Svg>
        <Text style={[labelStyle, { fontSize: look.sizes.meta + 2 }]}>{label}</Text>
      </View>
    );
  }

  const pct = Math.round(fraction * 100);
  return (
    <View style={styles.row}>
      <View style={[styles.track, { backgroundColor: colors.onBanner + '4D' }]}>
        <View style={[styles.fill, { width: `${pct}%`, backgroundColor: colors.onBanner }]} />
      </View>
      <Text style={[labelStyle, { fontFamily: look.fonts.strong }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: { paddingHorizontal: 24, paddingBottom: 22, gap: 14, overflow: 'hidden' },
  bottomLine: { position: 'absolute', left: 0, right: 0, bottom: 0 },
  waveform: { position: 'absolute', left: 24, right: 24, top: 56 },
  flex: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  stack: { gap: 6 },
  segments: { flexDirection: 'row', gap: 3 },
  block: { flex: 1, height: 14 },
  vu: { flex: 1, height: 16, borderRadius: 2 },
  track: { flex: 1, height: 8, borderRadius: 4 },
  fill: { height: 8, borderRadius: 4 },
});
