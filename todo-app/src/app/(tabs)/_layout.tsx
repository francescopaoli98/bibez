import { StyleSheet, View, type ColorValue } from 'react-native';
import { Tabs } from 'expo-router';
import Svg, { Path } from 'react-native-svg';
import { Icon, type IconName } from '../../components/Icon';
import { useTheme } from '../../theme/ThemeProvider';

const TABS: { name: string; title: string; icon: IconName }[] = [
  { name: 'index', title: 'Oggi', icon: 'sun' },
  { name: 'in-arrivo', title: 'In arrivo', icon: 'agenda' },
  { name: 'calendario', title: 'Calendario', icon: 'calendar' },
  { name: 'liste', title: 'Liste', icon: 'lists' },
];

// Icona della scheda + segno della scheda attiva (pillola, barretta in alto o pennellata)
function TabIcon({ name, color, focused }: { name: IconName; color: ColorValue; focused: boolean }) {
  const { colors, look } = useTheme();
  const kind = look.tabs.indicator;

  if (kind === 'pill') {
    return (
      <View style={[styles.pill, focused && { backgroundColor: colors.tint }]}>
        <Icon name={name} size={22} color={color} />
      </View>
    );
  }
  return (
    <View style={styles.column}>
      {kind === 'topbar' && (
        <View style={[styles.topbar, { backgroundColor: focused ? colors.primary : 'transparent' }]} />
      )}
      <Icon name={name} size={24} color={color} />
      {kind === 'brush' && (
        <Svg width={28} height={6} viewBox="0 0 28 6">
          <Path
            d="M2 3c4-2.5 8 2.5 12 0s8 2 12 0"
            fill="none"
            stroke={focused ? colors.primary : 'transparent'}
            strokeWidth={2.5}
            strokeLinecap="round"
          />
        </Svg>
      )}
    </View>
  );
}

export default function TabsLayout() {
  const { colors, look } = useTheme();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.onTint,
        tabBarInactiveTintColor: colors.muted,
        tabBarStyle: {
          backgroundColor: colors.tabBar,
          borderTopColor: colors.border,
          borderTopWidth: look.tabs.borderWidth,
          paddingTop: 8,
        },
        tabBarLabelStyle: { fontFamily: look.fonts.strong, fontSize: look.upperMeta ? 18 : 11 },
      }}
    >
      {TABS.map((t) => (
        <Tabs.Screen
          key={t.name}
          name={t.name}
          options={{
            title: t.title,
            tabBarLabel: look.upperMeta ? t.title.toUpperCase() : t.title,
            tabBarIcon: ({ color, focused }) => <TabIcon name={t.icon} color={color} focused={focused} />,
          }}
        />
      ))}
    </Tabs>
  );
}

const styles = StyleSheet.create({
  pill: { width: 56, height: 30, borderRadius: 15, alignItems: 'center', justifyContent: 'center' },
  column: { alignItems: 'center', gap: 3 },
  topbar: { width: 40, height: 3, borderRadius: 2, marginTop: -6 },
});
