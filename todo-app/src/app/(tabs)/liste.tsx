import { useCallback, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router } from 'expo-router';
import { useSQLiteContext, type SQLiteDatabase } from 'expo-sqlite';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Icon, type IconName } from '../../components/Icon';
import { Panel, SectionLabel } from '../../components/Ui';
import { useLoad } from '../../db/hooks';
import { addProject, getCounts, listProjectsWithCounts, type Counts, type ProjectInfo } from '../../db/tasks';
import { useTheme } from '../../theme/ThemeProvider';

const PALETTE = ['#0F7FA8', '#C2410C', '#15803D', '#8B3FB8', '#C73A2B', '#B8860B', '#3C4357', '#D63384'];

interface Data {
  counts: Counts;
  projects: ProjectInfo[];
}
const EMPTY: Data = { counts: { today: 0, important: 0, upcoming: 0, all: 0 }, projects: [] };

interface RowProps {
  icon: IconName;
  color: string;
  label: string;
  count: number;
  last?: boolean;
  onPress: () => void;
}

function Row({ icon, color, label, count, last, onPress }: RowProps) {
  const { colors, look } = useTheme();
  return (
    <Pressable
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={`${label}, ${count}`}
      style={[styles.row, !last && { borderBottomWidth: 1, borderBottomColor: colors.divider }]}
    >
      <View
        style={[
          styles.iconBox,
          { backgroundColor: color + '24', borderRadius: look.cardRadii[0] === 0 ? 0 : 10 },
        ]}
      >
        <Icon name={icon} size={20} color={color} />
      </View>
      <Text style={{ flex: 1, color: colors.text, fontFamily: look.fonts.body, fontSize: look.sizes.body }}>{label}</Text>
      <Text style={{ color: colors.muted, fontFamily: look.fonts.strong, fontSize: look.sizes.strong + 1 }}>{count}</Text>
    </Pressable>
  );
}

// Le liste: quelle automatiche (Oggi, Importanti…) e le tue
export default function ListeScreen() {
  const { colors, look, scheme } = useTheme();
  const db = useSQLiteContext();
  const insets = useSafeAreaInsets();
  const loader = useCallback(
    async (d: SQLiteDatabase): Promise<Data> => ({ counts: await getCounts(d), projects: await listProjectsWithCounts(d) }),
    [],
  );
  const { data, reload } = useLoad<Data>(loader, EMPTY);
  const [creating, setCreating] = useState(false);
  const [name, setName] = useState('');
  const [color, setColor] = useState(PALETTE[0]);

  const create = async () => {
    if (!name.trim()) return;
    await addProject(db, name, color);
    setName('');
    setCreating(false);
    await reload();
  };

  const c = data.counts;
  return (
    <View style={[styles.screen, { backgroundColor: colors.bg }]}>
      <StatusBar style={scheme === 'dark' ? 'light' : 'dark'} />
      <ScrollView contentContainerStyle={[styles.content, { paddingTop: insets.top + 16 }]} keyboardShouldPersistTaps="handled">
        <Text
          style={{
            color: colors.text,
            fontFamily: look.fonts.title,
            fontSize: Math.min(look.titleSize, 34),
            letterSpacing: look.titleTracking,
            paddingHorizontal: 8,
            paddingBottom: 4,
          }}
        >
          {look.upperMeta ? 'LISTE' : 'Liste'}
        </Text>

        <Panel>
          <Row icon="sun" color={colors.primary} label="Oggi" count={c.today} onPress={() => router.navigate('/')} />
          <Row icon="star" color={colors.important} label="Importanti" count={c.important} onPress={() => router.push('/lista/importanti')} />
          <Row icon="agenda" color="#0B6A8C" label="In arrivo" count={c.upcoming} onPress={() => router.navigate('/in-arrivo')} />
          <Row icon="list" color={colors.muted} label="Tutte le attività" count={c.all} last onPress={() => router.push('/lista/tutte')} />
        </Panel>

        <View style={styles.gap} />
        <SectionLabel>{look.upperMeta ? 'LE MIE LISTE' : 'LE MIE LISTE'}</SectionLabel>
        <Panel>
          {data.projects.map((p) => (
            <Row
              key={p.id}
              icon={p.icon === 'mic' ? 'mic' : p.icon === 'home' ? 'home' : 'list'}
              color={p.color}
              label={p.name}
              count={p.open}
              onPress={() => router.push(`/lista/${p.id}`)}
            />
          ))}
          {creating ? (
            <View style={styles.form}>
              <TextInput
                value={name}
                onChangeText={setName}
                onSubmitEditing={create}
                autoFocus
                maxLength={40}
                returnKeyType="done"
                placeholder="Nome della lista"
                placeholderTextColor={colors.muted}
                accessibilityLabel="Nome della nuova lista"
                style={[
                  styles.input,
                  { color: colors.text, borderColor: colors.border, fontFamily: look.fonts.body, fontSize: look.sizes.body },
                ]}
              />
              <View style={styles.colors}>
                {PALETTE.map((p) => (
                  <Pressable
                    key={p}
                    onPress={() => setColor(p)}
                    accessibilityRole="button"
                    accessibilityLabel={`Colore ${p}`}
                    accessibilityState={{ selected: p === color }}
                    style={[styles.swatch, { backgroundColor: p }, p === color && { borderColor: colors.text, borderWidth: 3 }]}
                  />
                ))}
              </View>
              <View style={styles.buttons}>
                <Pressable onPress={() => setCreating(false)} accessibilityRole="button" style={styles.cancel}>
                  <Text style={{ color: colors.muted, fontFamily: look.fonts.strong, fontSize: look.sizes.strong + 1 }}>Annulla</Text>
                </Pressable>
                <Pressable
                  onPress={create}
                  accessibilityRole="button"
                  style={[styles.create, { backgroundColor: colors.primary, borderRadius: look.cardRadii[0] === 0 ? 0 : 22 }]}
                >
                  <Text style={{ color: colors.onPrimary, fontFamily: look.fonts.strong, fontSize: look.sizes.strong + 1 }}>
                    Crea lista
                  </Text>
                </Pressable>
              </View>
            </View>
          ) : (
            <Pressable onPress={() => setCreating(true)} accessibilityRole="button" style={styles.row}>
              <View style={styles.iconBox}>
                <Icon name="plus" size={22} color={colors.onTint} strokeWidth={2.4} />
              </View>
              <Text style={{ color: colors.onTint, fontFamily: look.fonts.strong, fontSize: look.sizes.body }}>Nuova lista</Text>
            </Pressable>
          )}
        </Panel>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  content: { padding: 16, paddingBottom: 40, gap: 10 },
  gap: { height: 8 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 14, minHeight: 56, paddingHorizontal: 16 },
  iconBox: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
  form: { padding: 16, gap: 14 },
  input: { borderWidth: 1, borderRadius: 12, paddingHorizontal: 14, height: 48 },
  colors: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  swatch: { width: 32, height: 32, borderRadius: 16, borderWidth: 0 },
  buttons: { flexDirection: 'row', justifyContent: 'flex-end', alignItems: 'center', gap: 8 },
  cancel: { height: 44, paddingHorizontal: 14, justifyContent: 'center' },
  create: { height: 44, paddingHorizontal: 20, justifyContent: 'center' },
});
