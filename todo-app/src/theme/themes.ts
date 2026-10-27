export type ThemeId = 'indaco' | 'oceano' | 'bosco' | 'tramonto' | 'lavanda' | 'grafite';
export type Mode = 'light' | 'dark' | 'auto';
export type Scheme = 'light' | 'dark';

// Parte del tema che cambia da un tema all'altro
export interface Accent {
  gradient: [string, string, string];
  primary: string;
  onPrimary: string;
  tint: string;
  onTint: string;
}

// Parte comune a tutti i temi, cambia solo tra chiaro e scuro
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
}

export type Colors = Base & Accent;

export interface ThemeDef {
  id: ThemeId;
  name: string;
  light: Accent;
  dark: Accent;
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
  },
};

export const THEMES: ThemeDef[] = [
  {
    id: 'indaco',
    name: 'Indaco',
    light: { gradient: ['#2B2780', '#4F46E5', '#7C5CFA'], primary: '#4F46E5', onPrimary: '#FFFFFF', tint: '#E5E3FD', onTint: '#3730A3' },
    dark: { gradient: ['#14123A', '#2F2A9E', '#5B47D6'], primary: '#9D8FFF', onPrimary: '#0E0E1C', tint: '#2A2755', onTint: '#C9C2FF' },
  },
  {
    id: 'oceano',
    name: 'Oceano',
    light: { gradient: ['#0B3C5D', '#0F7FA8', '#3FB8D4'], primary: '#0B6F96', onPrimary: '#FFFFFF', tint: '#D6EEF6', onTint: '#0B5A7A' },
    dark: { gradient: ['#071F30', '#0B5A7A', '#1F8AA6'], primary: '#3FB8D4', onPrimary: '#0E0E1C', tint: '#12384A', onTint: '#A5E3F2' },
  },
  {
    id: 'bosco',
    name: 'Bosco',
    light: { gradient: ['#0F3B28', '#15803D', '#4CAF73'], primary: '#15803D', onPrimary: '#FFFFFF', tint: '#DDF3E4', onTint: '#116B33' },
    dark: { gradient: ['#08201A', '#0F5A2C', '#2E8B57'], primary: '#4CC77F', onPrimary: '#0E0E1C', tint: '#14382A', onTint: '#A8E8C3' },
  },
  {
    id: 'tramonto',
    name: 'Tramonto',
    light: { gradient: ['#7A1F3D', '#D6402F', '#F59E5B'], primary: '#C73A2B', onPrimary: '#FFFFFF', tint: '#FDE3DD', onTint: '#8F2417' },
    dark: { gradient: ['#3D0F1F', '#8F2A22', '#C9703A'], primary: '#FF8A6B', onPrimary: '#0E0E1C', tint: '#4A2420', onTint: '#FFC9BA' },
  },
  {
    id: 'lavanda',
    name: 'Lavanda',
    light: { gradient: ['#4A1D6B', '#9A4BC4', '#D77BE6'], primary: '#8B3FB8', onPrimary: '#FFFFFF', tint: '#F0E1F8', onTint: '#6B2C91' },
    dark: { gradient: ['#26103A', '#6D2F95', '#A44FC4'], primary: '#D08AF0', onPrimary: '#0E0E1C', tint: '#3A2250', onTint: '#EBC8FA' },
  },
  {
    id: 'grafite',
    name: 'Grafite',
    light: { gradient: ['#1F2330', '#3C4357', '#5B6478'], primary: '#3C4357', onPrimary: '#FFFFFF', tint: '#E3E6EE', onTint: '#2B3142' },
    dark: { gradient: ['#0F121A', '#262C3B', '#3E4659'], primary: '#A9B4CE', onPrimary: '#0E0E1C', tint: '#2A3042', onTint: '#D5DCEC' },
  },
];

export function findTheme(id: string | null | undefined): ThemeDef {
  return THEMES.find((t) => t.id === id) ?? THEMES[0];
}

export function buildColors(theme: ThemeDef, scheme: Scheme): Colors {
  return { ...BASE[scheme], ...theme[scheme] };
}

export const fonts = {
  medium: 'PlusJakartaSans_500Medium',
  semibold: 'PlusJakartaSans_600SemiBold',
  bold: 'PlusJakartaSans_700Bold',
  extrabold: 'PlusJakartaSans_800ExtraBold',
} as const;
