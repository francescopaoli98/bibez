import { useEffect, useState } from 'react';
import { FlatList, KeyboardAvoidingView, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router } from 'expo-router';
import { AddBar } from '../../components/AddBar';
import { Banner, BannerTitle, Progress } from '../../components/Banner';
import { Icon } from '../../components/Icon';
import { TaskCard } from '../../components/TaskCard';
import { useTodayTasks } from '../../db/useTodayTasks';
import { dueLabel, longDate, shortDate, startOfNextDay } from '../../lib/dates';
import type { QuickAddResult } from '../../lib/quickAdd';
import { useTheme } from '../../theme/ThemeProvider';

export default function OggiScreen() {
  const { colors, look } = useTheme();
  const { open, done, projects, stats, add, toggleDone, toggleImportant } = useTodayTasks();
  const [showDone, setShowDone] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  // L'attività è per un altro giorno: non comparirà qui, quindi lo si dice
  const handleAdd = async (parsed: QuickAddResult) => {
    await add(parsed);
    if (parsed.dueAt !== null && parsed.dueAt >= startOfNextDay()) {
      setNotice(`Aggiunta per ${dueLabel(parsed.dueAt, parsed.hasTime).toLowerCase()}`);
    }
  };

  useEffect(() => {
    if (!notice) return;
    const id = setTimeout(() => setNotice(null), 3500);
    return () => clearTimeout(id);
  }, [notice]);

  const total = open.length + done.length;
  const now = new Date();
  const squareUi = look.cardRadii[0] === 0;
  const buttonRadius = squareUi ? 0 : 22;

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={[styles.screen, { backgroundColor: colors.bg }]}
    >
      <StatusBar style={look.statusBar} />

      <Banner>
        <View style={styles.topRow}>
          {look.showStreak && (
            <View
              accessibilityLabel={`Serie di ${stats.streak} giorni`}
              style={[styles.streak, { borderColor: colors.important, borderRadius: buttonRadius }]}
            >
              <Icon name="flame" size={16} color={colors.important} filled strokeWidth={1.5} />
              <Text style={{ color: colors.important, fontFamily: look.fonts.strong, fontSize: look.sizes.strong }}>
                {stats.streak}
              </Text>
            </View>
          )}
          <Pressable
            onPress={() => router.push('/temi')}
            accessibilityRole="button"
            accessibilityLabel="Temi e aspetto"
            style={[styles.avatar, { backgroundColor: colors.onBanner + '33', borderRadius: buttonRadius }]}
          >
            <Icon name="palette" size={22} color={colors.onBanner} />
          </Pressable>
        </View>
        <BannerTitle
          greeting={look.copy.greeting(now.getHours())}
          subtitle={look.copy.subtitle(longDate(now), shortDate(now), open.length)}
        />
        <Progress done={done.length} total={total} level={stats.level} xp={stats.xp} xpMax={stats.xpMax} />
      </Banner>

      <FlatList
        data={open}
        keyExtractor={(t) => t.id}
        contentContainerStyle={styles.list}
        keyboardShouldPersistTaps="handled"
        renderItem={({ item, index }) => (
          <TaskCard
            task={item}
            index={index}
            onToggle={() => toggleDone(item)}
            onImportant={() => toggleImportant(item)}
            onOpen={() => router.push(`/attivita/${item.id}`)}
          />
        )}
        ListEmptyComponent={
          <Text style={[styles.empty, { color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 2 }]}>
            {look.copy.empty}
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
                <Text style={{ color: colors.onTint, fontFamily: look.fonts.strong, fontSize: look.sizes.strong + 1 }}>
                  {look.copy.completed(done.length)}
                </Text>
              </Pressable>
              {showDone &&
                done.map((t, i) => (
                  <TaskCard
                    key={t.id}
                    task={t}
                    index={i}
                    onToggle={() => toggleDone(t)}
                    onImportant={() => toggleImportant(t)}
                    onOpen={() => router.push(`/attivita/${t.id}`)}
                  />
                ))}
            </View>
          ) : undefined
        }
      />

      {notice && (
        <View
          accessibilityLiveRegion="polite"
          style={[styles.notice, { backgroundColor: colors.tint, borderRadius: squareUi ? 0 : 17 }]}
        >
          <Icon name="check" size={16} color={colors.onTint} strokeWidth={3} />
          <Text style={{ color: colors.onTint, fontFamily: look.fonts.strong, fontSize: look.sizes.strong }}>{notice}</Text>
        </View>
      )}

      <AddBar projects={projects} onSubmit={handleAdd} />
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  topRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'flex-end', gap: 8 },
  avatar: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  streak: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    height: 36,
    paddingHorizontal: 10,
    borderWidth: 2,
  },
  list: { padding: 16, gap: 8, flexGrow: 1 },
  empty: { textAlign: 'center', marginTop: 40 },
  notice: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'center',
    gap: 6,
    height: 34,
    paddingHorizontal: 14,
    marginBottom: 8,
  },
  doneBlock: { gap: 8, marginTop: 4 },
  doneHeader: { flexDirection: 'row', alignItems: 'center', gap: 6, height: 44, alignSelf: 'flex-start' },
});
