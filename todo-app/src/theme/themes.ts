export type ThemeId =
  | 'indaco' | 'oceano' | 'bosco' | 'tramonto' | 'lavanda' | 'grafite'
  | 'arcade' | 'atelier' | 'studio';
export type Mode = 'light' | 'dark' | 'auto';
export type Scheme = 'light' | 'dark';

// Tipo di onda con cui si entra in un tema (decide il tema di arrivo)
export type Fx = 'bar' | 'wave' | 'organic' | 'pixel' | 'paint' | 'bars';
export type SoundId = 'soft' | 'arcade' | 'atelier' | 'studio';

// Parte del tema che cambia da un tema normale all'altro
export interface Accent {
  gradient: [string, string, string];
  primary: string;
  onPrimary: string;
  tint: string;
  onTint: string;
}

// Parte comune a tutti i temi normali, cambia solo tra chiaro e scuro
export interface Base {
  bg: string;
  card: string;
  border: string;
  divider: string;
  text: string;
  muted: string;
  ring: string;
  tabBar: string;
  important: string;
  onBanner: string;
}

export type Colors = Base & Accent & { done: string; onDone: string };

type Radii = [number, number, number, number]; // alto-sx, alto-dx, basso-dx, basso-sx

// Tutto ciò che, oltre ai colori, distingue un tema: carattere, forme, barra di avanzamento, testi
export interface Look {
  fonts: { title: string; label: string; strong: string; body: string; meta: string };
  sizes: { body: number; meta: number; strong: number; label: number };
  titleText: string;
  titleSize: number;
  titleTracking: number;
  titleShadow: string | null;
  cardRadii: Radii;
  cardBorder: number;
  cardShadow: 'none' | 'hard' | 'paper';
  cardTilt: boolean;
  check: 'circle' | 'square';
  progress: 'bar' | 'xp' | 'brush' | 'vu';
  banner: 'gradient' | 'pixel' | 'watercolor' | 'studio';
  bannerRadii: Radii;
  statusBar: 'light' | 'dark';
  upperMeta: boolean;
  reward: { text: string; color: string } | null;
  tag: { color: string } | null;
  showStreak: boolean;
  tabs: { indicator: 'pill' | 'topbar' | 'brush'; borderWidth: number };
  addBar: {
    radius: number;
    borderWidth: number;
    dashed: boolean;
    color: string | null; // null = colors.border
    hardShadow: boolean;
    leading: 'plus' | 'pencil' | 'rec';
  };
  copy: {
    greeting: (hour: number) => string;
    subtitle: (date: string, shortDate: string, open: number) => string;
    progress: (done: number, total: number, level: number, xp: number, xpMax: number) => string;
    add: string;
    empty: string;
    completed: (n: number) => string;
  };
}

export interface ThemeDef {
  id: ThemeId;
  name: string;
  special: boolean;
  fx: Fx;
  fxDuration: number; // ms
  rim: string | null; // colore del bordo dell'onda (null = colore del tema)
  sound: SoundId;
  light: Accent;
  dark: Accent;
  // solo temi speciali: aspetto fisso, indipendente da Chiaro/Scuro
  palette?: Colors;
  fixed?: Scheme;
  look: Look;
  // anteprima nella griglia dei temi
  mini: { bg: string; banner: [string, string]; row: string };
}

export const DEFAULT_THEME: ThemeId = 'indaco';
export const DEFAULT_MODE: Mode = 'auto';

export const BASE: Record<Scheme, Base> = {
  light: {
    bg: '#F1F2FB',
    card: '#FFFFFF',
    border: '#E4E6F5',
    divider: '#EEF0FA',
    text: '#1B1A3A',
    muted: '#5C5C7A',
    ring: '#8A8AAE',
    tabBar: '#FFFFFF',
    important: '#F2552F',
    onBanner: '#FFFFFF',
  },
  dark: {
    bg: '#0E0E1C',
    card: '#1A1A2E',
    border: '#2A2A44',
    divider: '#222238',
    text: '#ECECFA',
    muted: '#A3A3C2',
    ring: '#8585A8',
    tabBar: '#14142A',
    important: '#FF7A59',
    onBanner: '#FFFFFF',
  },
};

// ---------- testi ----------
const greetingStd = (h: number) => (h < 13 ? 'Buongiorno' : h < 18 ? 'Buon pomeriggio' : 'Buonasera');

// ---------- aspetto dei temi normali (Plus Jakarta Sans) ----------
export const STD_LOOK: Look = {
  fonts: {
    title: 'PlusJakartaSans_800ExtraBold',
    label: 'PlusJakartaSans_700Bold',
    strong: 'PlusJakartaSans_700Bold',
    body: 'PlusJakartaSans_600SemiBold',
    meta: 'PlusJakartaSans_500Medium',
  },
  sizes: { body: 16, meta: 13, strong: 13, label: 12 },
  titleText: 'Oggi',
  titleSize: 34,
  titleTracking: -0.8,
  titleShadow: null,
  cardRadii: [14, 14, 14, 14],
  cardBorder: 1,
  cardShadow: 'none',
  cardTilt: false,
  check: 'circle',
  progress: 'bar',
  banner: 'gradient',
  bannerRadii: [0, 0, 28, 28],
  statusBar: 'light',
  upperMeta: false,
  reward: null,
  tag: null,
  showStreak: false,
  tabs: { indicator: 'pill', borderWidth: 1 },
  addBar: { radius: 28, borderWidth: 1, dashed: false, color: null, hardShadow: false, leading: 'plus' },
  copy: {
    greeting: greetingStd,
    subtitle: (date, _s, open) => `${date} · ${open === 0 ? 'niente da fare' : `${open} da fare`}`,
    progress: (done, total) => `${done} di ${total} fatte`,
    add: "Aggiungi un'attività",
    empty: "Giornata libera. Aggiungi la prima attività qui sotto.",
    completed: (n) => `Completate · ${n}`,
  },
};

const std = (
  id: ThemeId,
  name: string,
  fx: Fx,
  light: Accent,
  dark: Accent,
): ThemeDef => ({
  id,
  name,
  special: false,
  fx,
  fxDuration: fx === 'bar' ? 650 : 800,
  rim: null,
  sound: 'soft',
  light,
  dark,
  look: STD_LOOK,
  mini: { bg: '', banner: ['', ''], row: '' }, // calcolata da miniFor()
});

// ---------- temi speciali ----------
const ARCADE_ACCENT: Accent = {
  gradient: ['#2A0F5E', '#14072F', '#14072F'],
  primary: '#39FF88',
  onPrimary: '#0B0B1A',
  tint: '#1E3B2E',
  onTint: '#39FF88',
};
const ARCADE: ThemeDef = {
  id: 'arcade',
  name: 'Arcade',
  special: true,
  fx: 'pixel',
  fxDuration: 1150,
  rim: '#39FF88',
  sound: 'arcade',
  light: ARCADE_ACCENT,
  dark: ARCADE_ACCENT,
  fixed: 'dark',
  palette: {
    bg: '#0B0B1A', card: '#15152B', border: '#34346B', divider: '#222244', text: '#FFFFFF', muted: '#9A9AD0',
    ring: '#39FF88', tabBar: '#0F0F26', important: '#FFD93D', onBanner: '#FFFFFF',
    ...ARCADE_ACCENT, done: '#39FF88', onDone: '#0B0B1A',
  },
  look: {
    fonts: {
      title: 'PressStart2P_400Regular', label: 'PressStart2P_400Regular',
      strong: 'VT323_400Regular', body: 'VT323_400Regular', meta: 'VT323_400Regular',
    },
    sizes: { body: 24, meta: 20, strong: 20, label: 9 },
    titleText: 'OGGI',
    titleSize: 24,
    titleTracking: 0,
    titleShadow: '#FF3EA5',
    cardRadii: [0, 0, 0, 0],
    cardBorder: 2,
    cardShadow: 'hard',
    cardTilt: false,
    check: 'square',
    progress: 'xp',
    banner: 'pixel',
    bannerRadii: [0, 0, 0, 0],
    statusBar: 'light',
    upperMeta: true,
    reward: { text: '+20 XP', color: '#2DE2FF' },
    tag: null,
    showStreak: true,
    tabs: { indicator: 'topbar', borderWidth: 3 },
    addBar: { radius: 0, borderWidth: 2, dashed: false, color: '#39FF88', hardShadow: true, leading: 'plus' },
    copy: {
      greeting: () => 'PLAYER 1',
      subtitle: (_d, short, open) => `${short} · ${open === 0 ? 'NESSUNA MISSIONE' : `${open} MISSIONI`}`,
      progress: (_d, _t, level, xp, xpMax) => `LIV ${level} · ${xp}/${xpMax} XP`,
      add: 'NUOVA MISSIONE',
      empty: 'NESSUNA MISSIONE. AGGIUNGINE UNA QUI SOTTO.',
      completed: (n) => `COMPLETATE · ${n}`,
    },
  },
  mini: { bg: '#0B0B1A', banner: ['#2A0F5E', '#14072F'], row: '#15152B' },
};

const ATELIER_ACCENT: Accent = {
  gradient: ['#F2B38A', '#E7C06B', '#C98BA8'],
  primary: '#C4552D',
  onPrimary: '#FFFFFF',
  tint: '#F3DFC4',
  onTint: '#7A2E12',
};
const ATELIER: ThemeDef = {
  id: 'atelier',
  name: 'Atelier',
  special: true,
  fx: 'paint',
  fxDuration: 1100,
  rim: '#C4552D',
  sound: 'atelier',
  light: ATELIER_ACCENT,
  dark: ATELIER_ACCENT,
  fixed: 'light',
  palette: {
    bg: '#FBF6EC', card: '#FFFDF8', border: '#E6D9C0', divider: '#EFE4CF', text: '#2B2118', muted: '#6E5F4E',
    ring: '#6E5F4E', tabBar: '#FFFDF8', important: '#C4552D', onBanner: '#2B2118',
    ...ATELIER_ACCENT, done: '#C4552D', onDone: '#FFFFFF',
  },
  look: {
    fonts: {
      title: 'Fraunces_600SemiBold_Italic', label: 'Fraunces_600SemiBold_Italic',
      strong: 'Fraunces_600SemiBold', body: 'Fraunces_600SemiBold', meta: 'Caveat_600SemiBold',
    },
    sizes: { body: 18, meta: 20, strong: 14, label: 13 },
    titleText: 'Oggi',
    titleSize: 46,
    titleTracking: -1,
    titleShadow: null,
    cardRadii: [16, 20, 14, 18],
    cardBorder: 1.5,
    cardShadow: 'paper',
    cardTilt: true,
    check: 'circle',
    progress: 'brush',
    banner: 'watercolor',
    bannerRadii: [0, 0, 36, 36],
    statusBar: 'dark',
    upperMeta: false,
    reward: null,
    tag: null,
    showStreak: false,
    tabs: { indicator: 'brush', borderWidth: 1.5 },
    addBar: { radius: 30, borderWidth: 1.5, dashed: true, color: '#BFAE8F', hardShadow: false, leading: 'pencil' },
    copy: {
      greeting: greetingStd,
      subtitle: (date, _s, open) => `${date} · ${open === 0 ? 'tela bianca' : `${open} da fare`}`,
      progress: (done, total) => `${done} di ${total} fatte`,
      add: 'Annota qualcosa…',
      empty: 'Tela bianca. Annota la prima cosa qui sotto.',
      completed: (n) => `Completate · ${n}`,
    },
  },
  mini: { bg: '#FBF6EC', banner: ['#F2B38A', '#E7C06B'], row: '#FFFDF8' },
};

const STUDIO_ACCENT: Accent = {
  gradient: ['#151821', '#151821', '#151821'],
  primary: '#FF3B3B',
  onPrimary: '#0F1115',
  tint: '#3A1A1D',
  onTint: '#FF8A8A',
};
const STUDIO: ThemeDef = {
  id: 'studio',
  name: 'Studio',
  special: true,
  fx: 'bars',
  fxDuration: 900,
  rim: '#FF3B3B',
  sound: 'studio',
  light: STUDIO_ACCENT,
  dark: STUDIO_ACCENT,
  fixed: 'dark',
  palette: {
    bg: '#0F1115', card: '#181B22', border: '#272B35', divider: '#1E222B', text: '#E9ECF2', muted: '#98A0B0',
    ring: '#FF3B3B', tabBar: '#12141A', important: '#FFB020', onBanner: '#E9ECF2',
    ...STUDIO_ACCENT, done: '#3DDC84', onDone: '#0F1115',
  },
  look: {
    fonts: {
      title: 'SpaceGrotesk_700Bold', label: 'JetBrainsMono_700Bold',
      strong: 'SpaceGrotesk_700Bold', body: 'SpaceGrotesk_600SemiBold', meta: 'JetBrainsMono_500Medium',
    },
    sizes: { body: 17, meta: 12, strong: 13, label: 11 },
    titleText: 'Oggi',
    titleSize: 40,
    titleTracking: -1,
    titleShadow: null,
    cardRadii: [12, 12, 12, 12],
    cardBorder: 1,
    cardShadow: 'none',
    cardTilt: false,
    check: 'circle',
    progress: 'vu',
    banner: 'studio',
    bannerRadii: [0, 0, 20, 20],
    statusBar: 'light',
    upperMeta: false,
    reward: null,
    tag: { color: '#FF6B6B' },
    showStreak: false,
    tabs: { indicator: 'topbar', borderWidth: 1 },
    addBar: { radius: 16, borderWidth: 1, dashed: false, color: null, hardShadow: false, leading: 'rec' },
    copy: {
      greeting: () => 'SALA 1',
      subtitle: (_d, short, open) => `${short} · ${open === 0 ? 'NESSUN TAKE' : `${open} TAKE DA GIRARE`}`,
      progress: (done, total) => `${done}/${total} TAKE CHIUSI`,
      add: 'Nuovo take',
      empty: 'Nessun take in scaletta. Aggiungi il primo qui sotto.',
      completed: (n) => `Chiusi · ${n}`,
    },
  },
  mini: { bg: '#0F1115', banner: ['#FF3B3B', '#151821'], row: '#181B22' },
};

export const THEMES: ThemeDef[] = [
  std('indaco', 'Indaco', 'bar',
    { gradient: ['#2B2780', '#4F46E5', '#7C5CFA'], primary: '#4F46E5', onPrimary: '#FFFFFF', tint: '#E5E3FD', onTint: '#3730A3' },
    { gradient: ['#14123A', '#2F2A9E', '#5B47D6'], primary: '#9D8FFF', onPrimary: '#0E0E1C', tint: '#2A2755', onTint: '#C9C2FF' }),
  std('oceano', 'Oceano', 'wave',
    { gradient: ['#0B3C5D', '#0F7FA8', '#3FB8D4'], primary: '#0B6F96', onPrimary: '#FFFFFF', tint: '#D6EEF6', onTint: '#0B5A7A' },
    { gradient: ['#071F30', '#0B5A7A', '#1F8AA6'], primary: '#3FB8D4', onPrimary: '#0E0E1C', tint: '#12384A', onTint: '#A5E3F2' }),
  std('bosco', 'Bosco', 'organic',
    { gradient: ['#0F3B28', '#15803D', '#4CAF73'], primary: '#15803D', onPrimary: '#FFFFFF', tint: '#DDF3E4', onTint: '#116B33' },
    { gradient: ['#08201A', '#0F5A2C', '#2E8B57'], primary: '#4CC77F', onPrimary: '#0E0E1C', tint: '#14382A', onTint: '#A8E8C3' }),
  std('tramonto', 'Tramonto', 'bar',
    { gradient: ['#7A1F3D', '#D6402F', '#F59E5B'], primary: '#C73A2B', onPrimary: '#FFFFFF', tint: '#FDE3DD', onTint: '#8F2417' },
    { gradient: ['#3D0F1F', '#8F2A22', '#C9703A'], primary: '#FF8A6B', onPrimary: '#0E0E1C', tint: '#4A2420', onTint: '#FFC9BA' }),
  std('lavanda', 'Lavanda', 'bar',
    { gradient: ['#4A1D6B', '#9A4BC4', '#D77BE6'], primary: '#8B3FB8', onPrimary: '#FFFFFF', tint: '#F0E1F8', onTint: '#6B2C91' },
    { gradient: ['#26103A', '#6D2F95', '#A44FC4'], primary: '#D08AF0', onPrimary: '#0E0E1C', tint: '#3A2250', onTint: '#EBC8FA' }),
  std('grafite', 'Grafite', 'bar',
    { gradient: ['#1F2330', '#3C4357', '#5B6478'], primary: '#3C4357', onPrimary: '#FFFFFF', tint: '#E3E6EE', onTint: '#2B3142' },
    { gradient: ['#0F121A', '#262C3B', '#3E4659'], primary: '#A9B4CE', onPrimary: '#0E0E1C', tint: '#2A3042', onTint: '#D5DCEC' }),
  ARCADE,
  ATELIER,
  STUDIO,
];

export function findTheme(id: string | null | undefined): ThemeDef {
  return THEMES.find((t) => t.id === id) ?? THEMES[0];
}

// Schema effettivo: i temi speciali hanno il loro, gli altri seguono Chiaro/Scuro/Auto
export function schemeFor(theme: ThemeDef, wanted: Scheme): Scheme {
  return theme.fixed ?? wanted;
}

export function buildColors(theme: ThemeDef, scheme: Scheme): Colors {
  if (theme.palette) return theme.palette;
  const a = theme[scheme];
  return { ...BASE[scheme], ...a, done: a.primary, onDone: a.onPrimary };
}

// Anteprima nella griglia dei temi (per i normali segue il chiaro/scuro in uso)
export function miniFor(theme: ThemeDef, scheme: Scheme): ThemeDef['mini'] {
  if (theme.special) return theme.mini;
  const g = theme[scheme].gradient;
  return { bg: BASE[scheme].bg, banner: [g[0], g[2]], row: BASE[scheme].card };
}

// Font di default, usati dalle schermate che non dipendono dal tema
export const fonts = {
  medium: 'PlusJakartaSans_500Medium',
  semibold: 'PlusJakartaSans_600SemiBold',
  bold: 'PlusJakartaSans_700Bold',
  extrabold: 'PlusJakartaSans_800ExtraBold',
} as const;
