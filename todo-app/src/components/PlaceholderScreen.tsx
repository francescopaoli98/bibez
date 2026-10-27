import { StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeProvider';

interface Props {
  title: string;
  hint: string;
}

// Schermata segnaposto per le sezioni che arrivano negli step successivi
export function PlaceholderScreen({ title, hint }: Props) {
  const { colors, scheme, look } = useTheme();
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.screen, { backgroundColor: colors.bg, paddingTop: insets.top + 24 }]}>
      <StatusBar style={scheme === 'dark' ? 'light' : 'dark'} />
      <Text
        style={{
          color: colors.text,
          fontFamily: look.fonts.title,
          fontSize: Math.min(look.titleSize, 34),
          letterSpacing: look.titleTracking,
        }}
      >
        {look.upperMeta ? title.toUpperCase() : title}
      </Text>
      <Text style={{ color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 2 }}>{hint}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24, gap: 8 },
});
