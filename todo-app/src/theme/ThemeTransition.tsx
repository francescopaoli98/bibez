import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ComponentRef,
  type ReactNode,
} from 'react';
import { AccessibilityInfo, Animated, Easing, StyleSheet, View, type LayoutChangeEvent } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { captureRef, releaseCapture } from 'react-native-view-shot';
import { useTheme } from './ThemeProvider';
import type { Mode, ThemeId } from './themes';

// Cambio tema "a onda": prima si fotografa la schermata attuale, poi si cambia
// tema sotto la foto e infine la foto scorre via, lasciando entrare il tema nuovo.
//   ltr = il nuovo tema entra da sinistra e va verso destra
//   rtl = il nuovo tema entra da destra e va verso sinistra
// La direzione dipende dalla posizione del tema nella lista: uno più avanti
// spazza verso destra, uno più indietro verso sinistra.

type Direction = 'ltr' | 'rtl';

interface Snapshot {
  uri: string;
  direction: Direction;
  edgeColor: string;
}

interface Switcher {
  switchTheme: (id: ThemeId) => void;
  switchMode: (mode: Mode) => void;
}

const SwitcherContext = createContext<Switcher | null>(null);

const MODE_ORDER: Mode[] = ['light', 'auto', 'dark'];
const DURATION = 650;
const EDGE_WIDTH = 40;

export function ThemeTransitionHost({ children }: { children: ReactNode }) {
  const { theme, themes, scheme, mode, colors, setThemeId, setMode } = useTheme();

  const rootRef = useRef<ComponentRef<typeof View>>(null);
  const sizeRef = useRef({ width: 0, height: 0 });
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [snap, setSnap] = useState<Snapshot | null>(null);
  const progress = useRef(new Animated.Value(0)).current;
  const busy = useRef(false);
  const pendingApply = useRef<(() => void) | null>(null);

  const onLayout = (e: LayoutChangeEvent) => {
    const { width, height } = e.nativeEvent.layout;
    sizeRef.current = { width, height };
    setSize({ width, height });
  };

  const run = useCallback(
    async (direction: Direction, edgeColor: string, apply: () => void) => {
      if (busy.current) return;
      busy.current = true;
      try {
        const reduceMotion = await AccessibilityInfo.isReduceMotionEnabled();
        if (reduceMotion || sizeRef.current.width === 0) {
          apply();
          busy.current = false;
          return;
        }
        const uri = await captureRef(rootRef, { format: 'jpg', quality: 0.92, result: 'tmpfile' });
        progress.setValue(0);
        pendingApply.current = apply;
        setSnap({ uri, direction, edgeColor });
      } catch {
        // Se la foto non riesce, il cambio avviene comunque, senza animazione
        apply();
        busy.current = false;
      }
    },
    [progress],
  );

  // La foto è sullo schermo: ora si cambia tema sotto e si fa partire l'onda
  const onSnapshotLoaded = () => {
    if (!snap) return;
    const uri = snap.uri;
    pendingApply.current?.();
    pendingApply.current = null;
    setTimeout(() => {
      Animated.timing(progress, {
        toValue: 1,
        duration: DURATION,
        easing: Easing.inOut(Easing.cubic),
        useNativeDriver: true,
      }).start(() => {
        setSnap(null);
        releaseCapture(uri);
        busy.current = false;
      });
    }, 120);
  };

  const switcher = useMemo<Switcher>(
    () => ({
      switchTheme: (id) => {
        if (id === theme.id) return;
        const from = themes.findIndex((t) => t.id === theme.id);
        const next = themes.findIndex((t) => t.id === id);
        void run(next > from ? 'ltr' : 'rtl', themes[next][scheme].gradient[2], () => setThemeId(id));
      },
      switchMode: (m) => {
        if (m === mode) return;
        const dir: Direction = MODE_ORDER.indexOf(m) > MODE_ORDER.indexOf(mode) ? 'ltr' : 'rtl';
        void run(dir, colors.primary, () => setMode(m));
      },
    }),
    [theme.id, themes, scheme, mode, colors.primary, run, setThemeId, setMode],
  );

  const { width, height } = size;
  const ltr = snap?.direction === 'ltr';
  // Il "sipario" si sposta da una parte, la foto al suo interno si sposta dall'altra:
  // così la foto resta ferma sullo schermo e viene scoperta a poco a poco.
  const curtainX = progress.interpolate({ inputRange: [0, 1], outputRange: [0, ltr ? width : -width] });
  const photoX = progress.interpolate({ inputRange: [0, 1], outputRange: [0, ltr ? -width : width] });

  return (
    <SwitcherContext.Provider value={switcher}>
      <View style={styles.flex} onLayout={onLayout}>
        <View ref={rootRef} collapsable={false} style={styles.flex}>
          {children}
        </View>

        {snap && (
          <Animated.View
            style={[StyleSheet.absoluteFill, styles.curtain, { transform: [{ translateX: curtainX }] }]}
          >
            <Animated.Image
              source={{ uri: snap.uri }}
              onLoad={onSnapshotLoaded}
              resizeMode="stretch"
              style={{ width, height, transform: [{ translateX: photoX }] }}
            />
            {/* Bordo luminoso sul fronte dell'onda */}
            <LinearGradient
              pointerEvents="none"
              colors={ltr ? [snap.edgeColor + 'AA', snap.edgeColor + '00'] : [snap.edgeColor + '00', snap.edgeColor + 'AA']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={[styles.glow, ltr ? { left: 0 } : { right: 0 }]}
            />
            <View
              pointerEvents="none"
              style={[styles.line, { backgroundColor: snap.edgeColor }, ltr ? { left: 0 } : { right: 0 }]}
            />
          </Animated.View>
        )}
      </View>
    </SwitcherContext.Provider>
  );
}

export function useThemeSwitcher(): Switcher {
  const ctx = useContext(SwitcherContext);
  if (!ctx) throw new Error('useThemeSwitcher va usato dentro ThemeTransitionHost');
  return ctx;
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  curtain: { overflow: 'hidden' },
  glow: { position: 'absolute', top: 0, bottom: 0, width: EDGE_WIDTH },
  line: { position: 'absolute', top: 0, bottom: 0, width: 3 },
});
