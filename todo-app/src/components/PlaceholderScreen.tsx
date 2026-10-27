import { StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeProvider';
import { fonts } from '../theme/themes';

interface Props {
  title: string;
  hint: string;
}

// Schermata segnaposto per le sezioni che arrivano negli step successivi
export function PlaceholderScreen({ title, hint }: Props) {
  const { colors, scheme } = useTheme();
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.screen, { backgroundColor: colors.bg, paddingTop: insets.top + 24 }]}>
      <StatusBar style={scheme === 'dark' ? 'light' : 'dark'} />
      <Text style={[styles.title, { color: colors.text }]}>{title}</Text>
      <Text style={[styles.hint, { color: colors.muted }]}>{hint}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24, gap: 8 },
  title: { fontSize: 34, fontFamily: fonts.extrabold, letterSpacing: -0.8 },
  hint: { fontSize: 15, fontFamily: fonts.medium },
});
