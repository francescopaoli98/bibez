import { useState } from 'react';
import { FlatList, KeyboardAvoidingView, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router } from 'expo-router';
import { AddBar } from '../../components/AddBar';
import { Banner, Progress } from '../../components/Banner';
import { Icon } from '../../components/Icon';
import { TaskCard } from '../../components/TaskCard';
import { useTodayTasks } from '../../db/useTodayTasks';
import { greeting, longDate } from '../../lib/dates';
import { useTheme } from '../../theme/ThemeProvider';
import { fonts } from '../../theme/themes';

export default function OggiScreen() {
  const { colors } = useTheme();
  const { open, done, add, toggleDone, toggleImportant } = useTodayTasks();
  const [showDone, setShowDone] = useState(false);

  const total = open.length + done.length;
  const now = new Date();

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={[styles.screen, { backgroundColor: colors.bg }]}
    >
      <StatusBar style="light" />

      <Banner>
        <View style={styles.topRow}>
          <Text style={styles.hello}>{greeting(now)}</Text>
          <Pressable
            onPress={() => router.push('/temi')}
            accessibilityRole="button"
            accessibilityLabel="Temi e aspetto"
            style={styles.avatar}
          >
            <Icon name="palette" size={22} color="#FFFFFF" />
          </Pressable>
        </View>
        <View>
          <Text style={styles.title}>Oggi</Text>
          <Text style={styles.subtitle}>
            {longDate(now)} · {open.length === 0 ? 'niente da fare' : `${open.length} da fare`}
          </Text>
        </View>
        <Progress done={done.length} total={total} />
      </Banner>

      <FlatList
        data={open}
        keyExtractor={(t) => t.id}
        contentContainerStyle={styles.list}
        keyboardShouldPersistTaps="handled"
        renderItem={({ item }) => (
          <TaskCard task={item} onToggle={() => toggleDone(item)} onImportant={() => toggleImportant(item)} />
        )}
        ListEmptyComponent={
          <Text style={[styles.empty, { color: colors.muted }]}>
            Giornata libera. Aggiungi la prima attività qui sotto.
          </Text>
        }
        ListFooterComponent={
          done.length > 0 ? (
            <View style={styles.doneBlock}>
              <Pressable
                onPress={() => setShowDone((v) => !v)}
                accessibilityRole="button"
                accessibilityState={{ expanded: showDone }}
                style={styles.doneHeader}
              >
                <Icon name={showDone ? 'chevronDown' : 'chevronRight'} size={20} color={colors.onTint} strokeWidth={2.4} />
                <Text style={[styles.doneLabel, { color: colors.onTint }]}>Completate · {done.length}</Text>
              </Pressable>
              {showDone &&
                done.map((t) => (
                  <TaskCard key={t.id} task={t} onToggle={() => toggleDone(t)} onImportant={() => toggleImportant(t)} />
                ))}
            </View>
          ) : undefined
        }
      />

      <AddBar onSubmit={add} />
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  topRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  hello: { color: '#FFFFFF', fontSize: 15, fontFamily: fonts.medium },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.2)',
  },
  title: { color: '#FFFFFF', fontSize: 34, fontFamily: fonts.extrabold, letterSpacing: -0.8 },
  subtitle: { color: '#FFFFFF', fontSize: 14, fontFamily: fonts.medium },
  list: { padding: 16, gap: 8, flexGrow: 1 },
  empty: { textAlign: 'center', fontSize: 15, fontFamily: fonts.medium, marginTop: 40 },
  doneBlock: { gap: 8, marginTop: 4 },
  doneHeader: { flexDirection: 'row', alignItems: 'center', gap: 6, height: 44, alignSelf: 'flex-start' },
  doneLabel: { fontSize: 14, fontFamily: fonts.bold },
});
