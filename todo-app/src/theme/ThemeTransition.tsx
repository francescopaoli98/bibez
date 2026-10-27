import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ComponentRef,
  type ReactNode,
} from 'react';
import {
  AccessibilityInfo,
  Animated,
  Easing,
  StyleSheet,
  View,
  useColorScheme,
  type LayoutChangeEvent,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Canvas, Group, Image as SkiaImage, Path, Skia, type SkImage } from '@shopify/react-native-skia';
import { captureRef, releaseCapture } from 'react-native-view-shot';
import { playSound } from '../lib/sounds';
import { useTheme } from './ThemeProvider';
import { buildColors, schemeFor, type Fx, type Mode, type Scheme, type SoundId, type ThemeId } from './themes';
import { buildWave, makeSeed, type Direction, type WaveSeed } from './waves';

// Cambio tema "a onda": prima si fotografa la schermata attuale, poi si cambia
// tema sotto la foto e infine la foto viene "mangiata" dall'onda, lasciando entrare
// il tema nuovo. L'onda dipende dal tema di ARRIVO:
//   Arcade = pixel che crescono, Atelier = macchie di colore, Studio = barre da equalizzatore,
//   Oceano = fronte ondulato, Bosco = fronte irregolare, gli altri = barra lineare.
// La direzione dipende dalla posizione del tema nella lista:
//   ltr = il tema nuovo entra da sinistra, rtl = da destra.

interface Snapshot {
  uri: string;
  direction: Direction;
  edgeColor: string;
  fx: Fx;
  duration: number;
  sound: SoundId;
  image: SkImage | null;
  seed: WaveSeed;
}

interface RunOptions {
  direction: Direction;
  edgeColor: string;
  fx: Fx;
  duration: number;
  sound: SoundId;
  apply: () => void;
}

interface Switcher {
  switchTheme: (id: ThemeId) => void;
  switchMode: (mode: Mode) => void;
}

const SwitcherContext = createContext<Switcher | null>(null);

const MODE_ORDER: Mode[] = ['light', 'auto', 'dark'];
const EDGE_WIDTH = 40;

// ---- onda disegnata con Skia (pixel, macchie, barre, ondulata, irregolare) ----
interface WaveOverlayProps {
  snap: Snapshot;
  width: number;
  height: number;
  onCovered: () => void;
  onStart: () => void;
  onDone: () => void;
}

function WaveOverlay({ snap, width, height, onCovered, onStart, onDone }: WaveOverlayProps) {
  const [p, setP] = useState(0);

  useEffect(() => {
    let raf = 0;
    let cancelled = false;
    // 1) la foto è già sullo schermo -> si cambia tema sotto   2) parte l'onda
    const t1 = setTimeout(onCovered, 90);
    const t2 = setTimeout(() => {
      onStart();
      const t0 = Date.now();
      const tick = () => {
        if (cancelled) return;
        const next = Math.min(1, (Date.now() - t0) / snap.duration);
        setP(next);
        if (next < 1) raf = requestAnimationFrame(tick);
        else onDone();
      };
      raf = requestAnimationFrame(tick);
    }, 230);
    return () => {
      cancelled = true;
      clearTimeout(t1);
      clearTimeout(t2);
      cancelAnimationFrame(raf);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const { reveal, rim } = useMemo(
    () => buildWave(snap.fx, p, snap.direction, snap.seed, width, height),
    [p, snap, width, height],
  );

  if (!snap.image) return null;
  return (
    <Canvas style={StyleSheet.absoluteFill} pointerEvents="none">
      {/* la foto del vecchio tema, "bucata" dove l'onda è già passata */}
      <Group clip={reveal} invertClip>
        <SkiaImage image={snap.image} x={0} y={0} width={width} height={height} fit="fill" />
      </Group>
      {/* bordo colorato attorno alla zona già conquistata */}
      <Group clip={reveal} invertClip>
        <Path path={rim} color={snap.edgeColor} />
      </Group>
    </Canvas>
  );
}

export function ThemeTransitionHost({ children }: { children: ReactNode }) {
  const { theme, themes, mode, colors, soundsOn, setThemeId, setMode } = useTheme();
  const system = useColorScheme();

  const rootRef = useRef<ComponentRef<typeof View>>(null);
  const sizeRef = useRef({ width: 0, height: 0 });
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [snap, setSnap] = useState<Snapshot | null>(null);
  const snapRef = useRef<Snapshot | null>(null);
  const progress = useRef(new Animated.Value(0)).current;
  const busy = useRef(false);
  const pendingApply = useRef<(() => void) | null>(null);
  const soundsRef = useRef(soundsOn);
  soundsRef.current = soundsOn;

  const onLayout = (e: LayoutChangeEvent) => {
    const { width, height } = e.nativeEvent.layout;
    sizeRef.current = { width, height };
    setSize({ width, height });
  };

  const cover = useCallback(() => {
    pendingApply.current?.();
    pendingApply.current = null;
  }, []);
  const start = useCallback(() => {
    if (soundsRef.current && snapRef.current) playSound(snapRef.current.sound);
  }, []);
  const finish = useCallback(() => {
    const s = snapRef.current;
    snapRef.current = null;
    setSnap(null);
    if (s) releaseCapture(s.uri);
    busy.current = false;
  }, []);

  const run = useCallback(
    async (opts: RunOptions) => {
      if (busy.current) return;
      busy.current = true;
      try {
        const { width, height } = sizeRef.current;
        const reduceMotion = await AccessibilityInfo.isReduceMotionEnabled();
        if (reduceMotion || width === 0) {
          opts.apply();
          busy.current = false;
          return;
        }
        const uri = await captureRef(rootRef, { format: 'jpg', quality: 0.92, result: 'tmpfile' });

        // Per le onde disegnate serve la foto in formato Skia; se non riesce, si ripiega sulla barra
        let image: SkImage | null = null;
        if (opts.fx !== 'bar') {
          try {
            const data = await Skia.Data.fromURI(uri);
            image = Skia.Image.MakeImageFromEncoded(data);
          } catch {
            image = null;
          }
        }
        const fx: Fx = image ? opts.fx : 'bar';
        const next: Snapshot = {
          uri,
          direction: opts.direction,
          edgeColor: opts.edgeColor,
          fx,
          duration: fx === 'bar' ? 650 : opts.duration,
          sound: opts.sound,
          image,
          seed: makeSeed(width, height),
        };
        progress.setValue(0);
        pendingApply.current = opts.apply;
        snapRef.current = next;
        setSnap(next);
      } catch {
        // Se la foto non riesce, il cambio avviene comunque, senza animazione
        opts.apply();
        busy.current = false;
      }
    },
    [progress],
  );

  // Barra lineare: la foto scorre via (animazione nativa, leggera)
  const onBarPhotoLoaded = () => {
    cover();
    setTimeout(() => {
      start();
      Animated.timing(progress, {
        toValue: 1,
        duration: 650,
        easing: Easing.inOut(Easing.cubic),
        useNativeDriver: true,
      }).start(finish);
    }, 120);
  };

  const switcher = useMemo<Switcher>(() => {
    const wanted: Scheme = mode === 'auto' ? (system === 'dark' ? 'dark' : 'light') : mode;
    return {
      switchTheme: (id) => {
        if (id === theme.id) return;
        const from = themes.findIndex((t) => t.id === theme.id);
        const to = themes.findIndex((t) => t.id === id);
        const target = themes[to];
        const edgeColor = target.rim ?? buildColors(target, schemeFor(target, wanted)).gradient[2];
        void run({
          direction: to > from ? 'ltr' : 'rtl',
          edgeColor,
          fx: target.fx,
          duration: target.fxDuration,
          sound: target.sound,
          apply: () => setThemeId(id),
        });
      },
      switchMode: (m) => {
        if (m === mode) return;
        const dir: Direction = MODE_ORDER.indexOf(m) > MODE_ORDER.indexOf(mode) ? 'ltr' : 'rtl';
        void run({
          direction: dir,
          edgeColor: colors.primary,
          fx: theme.fx,
          duration: theme.fxDuration,
          sound: theme.sound,
          apply: () => setMode(m),
        });
      },
    };
  }, [theme, themes, mode, system, colors.primary, run, setThemeId, setMode]);

  const { width, height } = size;
  const ltr = snap?.direction === 'ltr';
  // Barra lineare: il "sipario" si sposta da una parte, la foto al suo interno dall'altra,
  // così la foto resta ferma sullo schermo e viene scoperta a poco a poco.
  const curtainX = progress.interpolate({ inputRange: [0, 1], outputRange: [0, ltr ? width : -width] });
  const photoX = progress.interpolate({ inputRange: [0, 1], outputRange: [0, ltr ? -width : width] });

  return (
    <SwitcherContext.Provider value={switcher}>
      <View style={styles.flex} onLayout={onLayout}>
        <View ref={rootRef} collapsable={false} style={styles.flex}>
          {children}
        </View>

        {snap && snap.fx === 'bar' && (
          <Animated.View
            style={[StyleSheet.absoluteFill, styles.curtain, { transform: [{ translateX: curtainX }] }]}
          >
            <Animated.Image
              source={{ uri: snap.uri }}
              onLoad={onBarPhotoLoaded}
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

        {snap && snap.fx !== 'bar' && (
          <WaveOverlay
            snap={snap}
            width={width}
            height={height}
            onCovered={cover}
            onStart={start}
            onDone={finish}
          />
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
