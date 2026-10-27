import { Suspense } from 'react';
import { Stack } from 'expo-router';
import { useFonts } from 'expo-font';
import { SQLiteProvider } from 'expo-sqlite';
import {
  PlusJakartaSans_500Medium,
  PlusJakartaSans_600SemiBold,
  PlusJakartaSans_700Bold,
  PlusJakartaSans_800ExtraBold,
} from '@expo-google-fonts/plus-jakarta-sans';
import { PressStart2P_400Regular } from '@expo-google-fonts/press-start-2p';
import { VT323_400Regular } from '@expo-google-fonts/vt323';
import { Fraunces_600SemiBold, Fraunces_600SemiBold_Italic } from '@expo-google-fonts/fraunces';
import { Caveat_600SemiBold } from '@expo-google-fonts/caveat';
import { SpaceGrotesk_600SemiBold, SpaceGrotesk_700Bold } from '@expo-google-fonts/space-grotesk';
import { JetBrainsMono_500Medium, JetBrainsMono_700Bold } from '@expo-google-fonts/jetbrains-mono';
import { DB_NAME, migrate } from '../db/schema';
import { ThemeProvider } from '../theme/ThemeProvider';
import { ThemeTransitionHost } from '../theme/ThemeTransition';

export default function RootLayout() {
  // Font dei temi normali + quelli dei temi speciali (Arcade, Atelier, Studio)
  const [fontsLoaded] = useFonts({
    PlusJakartaSans_500Medium,
    PlusJakartaSans_600SemiBold,
    PlusJakartaSans_700Bold,
    PlusJakartaSans_800ExtraBold,
    PressStart2P_400Regular,
    VT323_400Regular,
    Fraunces_600SemiBold,
    Fraunces_600SemiBold_Italic,
    Caveat_600SemiBold,
    SpaceGrotesk_600SemiBold,
    SpaceGrotesk_700Bold,
    JetBrainsMono_500Medium,
    JetBrainsMono_700Bold,
  });

  if (!fontsLoaded) return null;

  return (
    <Suspense fallback={null}>
      <SQLiteProvider databaseName={DB_NAME} onInit={migrate} useSuspense>
        <ThemeProvider>
          <ThemeTransitionHost>
            <Stack screenOptions={{ headerShown: false }} />
          </ThemeTransitionHost>
        </ThemeProvider>
      </SQLiteProvider>
    </Suspense>
  );
}
