import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { useColorScheme } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import { getSettingSync, setSetting } from '../db/settings';
import {
  DEFAULT_MODE,
  DEFAULT_THEME,
  THEMES,
  buildColors,
  findTheme,
  type Colors,
  type Mode,
  type Scheme,
  type ThemeDef,
  type ThemeId,
} from './themes';

interface ThemeContextValue {
  colors: Colors;
  scheme: Scheme;
  theme: ThemeDef;
  mode: Mode;
  themes: ThemeDef[];
  setThemeId: (id: ThemeId) => void;
  setMode: (mode: Mode) => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

const isMode = (v: string | null): v is Mode => v === 'light' || v === 'dark' || v === 'auto';

export function ThemeProvider({ children }: { children: ReactNode }) {
  const db = useSQLiteContext();
  const system = useColorScheme();

  // Stato iniziale letto in modo sincrono dal database
  const [themeId, setThemeIdState] = useState<ThemeId>(() => findTheme(getSettingSync(db, 'theme')).id);
  const [mode, setModeState] = useState<Mode>(() => {
    const saved = getSettingSync(db, 'mode');
    return isMode(saved) ? saved : DEFAULT_MODE;
  });

  const setThemeId = useCallback(
    (id: ThemeId) => {
      setThemeIdState(id);
      void setSetting(db, 'theme', id);
    },
    [db],
  );
  const setMode = useCallback(
    (m: Mode) => {
      setModeState(m);
      void setSetting(db, 'mode', m);
    },
    [db],
  );

  const value = useMemo<ThemeContextValue>(() => {
    const scheme: Scheme = mode === 'auto' ? (system === 'dark' ? 'dark' : 'light') : mode;
    const theme = findTheme(themeId ?? DEFAULT_THEME);
    return { colors: buildColors(theme, scheme), scheme, theme, mode, themes: THEMES, setThemeId, setMode };
  }, [themeId, mode, system, setThemeId, setMode]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme va usato dentro ThemeProvider');
  return ctx;
}
