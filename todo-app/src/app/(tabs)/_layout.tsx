import { StyleSheet, View } from 'react-native';
import { Tabs } from 'expo-router';
import { Icon, type IconName } from '../../components/Icon';
import { useTheme } from '../../theme/ThemeProvider';
import { fonts } from '../../theme/themes';

const TABS: { name: string; title: string; icon: IconName }[] = [
  { name: 'index', title: 'Oggi', icon: 'sun' },
  { name: 'in-arrivo', title: 'In arrivo', icon: 'agenda' },
  { name: 'calendario', title: 'Calendario', icon: 'calendar' },
  { name: 'liste', title: 'Liste', icon: 'lists' },
];

export default function TabsLayout() {
  const { colors } = useTheme();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.onTint,
        tabBarInactiveTintColor: colors.muted,
        tabBarStyle: { backgroundColor: colors.tabBar, borderTopColor: colors.border, paddingTop: 8 },
        tabBarLabelStyle: { fontSize: 11, fontFamily: fonts.bold },
      }}
    >
      {TABS.map((t) => (
        <Tabs.Screen
          key={t.name}
          name={t.name}
          options={{
            title: t.title,
            // Icona con la "pillola" colorata dietro quando la scheda è attiva
            tabBarIcon: ({ color, focused }) => (
              <View style={[styles.pill, focused && { backgroundColor: colors.tint }]}>
                <Icon name={t.icon} size={22} color={color} />
              </View>
            ),
          }}
        />
      ))}
    </Tabs>
  );
}

const styles = StyleSheet.create({
  pill: { width: 56, height: 30, borderRadius: 15, alignItems: 'center', justifyContent: 'center' },
});
