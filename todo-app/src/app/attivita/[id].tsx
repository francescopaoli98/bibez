import { useCallback, useEffect, useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router, useLocalSearchParams } from 'expo-router';
import { useSQLiteContext, type SQLiteDatabase } from 'expo-sqlite';
import { PageHeader } from '../../components/Banner';
import { Icon } from '../../components/Icon';
import { Chip, Panel, SectionLabel } from '../../components/Ui';
import { useLoad } from '../../db/hooks';
import {
  addSubtask,
  deleteSubtask,
  deleteTask,
  getTask,
  listProjects,
  listSubtasks,
  setDone,
  setSubtaskDone,
  updateTask,
  type Subtask,
  type Task,
  type TaskPatch,
} from '../../db/tasks';
import { dueLabel, moveToDay, startOfDay } from '../../lib/dates';
import { parseWhen, type ProjectRef } from '../../lib/quickAdd';
import { useTheme } from '../../theme/ThemeProvider';

interface Data {
  task: Task | null;
  subs: Subtask[];
  projects: ProjectRef[];
}

const dayOffset = (n: number) => {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return startOfDay(d);
};

// Dettaglio di un'attività: titolo, quando, lista, importante e passi (checklist)
export default function AttivitaScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { colors, look } = useTheme();
  const db = useSQLiteContext();
  const square = look.cardRadii[0] === 0;

  const loader = useCallback(
    async (d: SQLiteDatabase): Promise<Data> => ({
      task: await getTask(d, id),
      subs: await listSubtasks(d, id),
      projects: await listProjects(d),
    }),
    [id],
  );
  const { data, reload } = useLoad<Data>(loader, { task: null, subs: [], projects: [] });
  const { task, subs, projects } = data;

  const [title, setTitle] = useState('');
  const [when, setWhen] = useState('');
  const [whenError, setWhenError] = useState(false);
  const [newStep, setNewStep] = useState('');

  useEffect(() => {
    if (task) setTitle(task.title);
  }, [task?.id]); // eslint-disable-line react-hooks/exhaustive-deps

  const patch = async (p: TaskPatch) => {
    await updateTask(db, id, p);
    await reload();
  };

  const saveTitle = async () => {
    const t = title.trim();
    if (!t) {
      if (task) setTitle(task.title);
      return;
    }
    if (task && t !== task.title) await patch({ title: t });
  };

  const applyWhen = async () => {
    const parsed = parseWhen(when);
    if (!parsed) {
      setWhenError(true);
      return;
    }
    setWhenError(false);
    setWhen('');
    await patch({ dueAt: parsed.dueAt, hasTime: parsed.hasTime });
  };

  const addStep = async () => {
    if (!newStep.trim()) return;
    await addSubtask(db, id, newStep);
    setNewStep('');
    await reload();
  };

  const confirmDelete = () => {
    Alert.alert('Eliminare l\'attività?', task?.title ?? '', [
      { text: 'Annulla', style: 'cancel' },
      {
        text: 'Elimina',
        style: 'destructive',
        onPress: async () => {
          await deleteTask(db, id);
          router.back();
        },
      },
    ]);
  };

  if (!task) {
    return (
      <View style={[styles.screen, { backgroundColor: colors.bg }]}>
        <PageHeader title="Attività" onBack={() => router.back()} />
      </View>
    );
  }

  const done = task.doneAt !== null;
  const moveTo = (n: number) => patch({ dueAt: moveToDay(task.dueAt, task.hasTime, dayOffset(n)) });
  const inputStyle = {
    color: colors.text,
    borderColor: colors.border,
    backgroundColor: colors.card,
    fontFamily: look.fonts.body,
    fontSize: look.sizes.body,
    borderRadius: square ? 0 : 12,
  };

  return (
    <View style={[styles.screen, { backgroundColor: colors.bg }]}>
      <StatusBar style={look.statusBar} />
      <PageHeader title="Attività" subtitle={done ? 'Completata' : undefined} onBack={() => router.back()} />

      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        {/* titolo + completata */}
        <View style={styles.titleRow}>
          <Pressable
            onPress={async () => {
              await setDone(db, id, !done);
              await reload();
            }}
            accessibilityRole="checkbox"
            accessibilityState={{ checked: done }}
            accessibilityLabel={done ? 'Riapri' : 'Segna come fatta'}
            style={styles.touch}
          >
            <View
              style={[
                square ? styles.square : styles.circle,
                done ? { backgroundColor: colors.done, borderColor: colors.done } : { borderColor: colors.ring },
              ]}
            >
              {done && <Icon name="check" size={14} color={colors.onDone} strokeWidth={3.2} />}
            </View>
          </Pressable>
          <TextInput
            value={title}
            onChangeText={setTitle}
            onEndEditing={saveTitle}
            multiline
            accessibilityLabel="Titolo"
            style={[
              styles.title,
              { color: colors.text, fontFamily: look.fonts.body, fontSize: look.sizes.body + 4 },
              done && { textDecorationLine: 'line-through', color: colors.muted },
            ]}
          />
        </View>

        {/* quando */}
        <SectionLabel>QUANDO</SectionLabel>
        <View style={styles.chips}>
          <Chip label="Oggi" active={task.dueAt !== null && startOfDay(new Date(task.dueAt)) === dayOffset(0)} onPress={() => moveTo(0)} />
          <Chip label="Domani" active={task.dueAt !== null && startOfDay(new Date(task.dueAt)) === dayOffset(1)} onPress={() => moveTo(1)} />
          <Chip label="Dopodomani" active={task.dueAt !== null && startOfDay(new Date(task.dueAt)) === dayOffset(2)} onPress={() => moveTo(2)} />
          <Chip
            label="Senza data"
            active={task.dueAt === null}
            onPress={() => patch({ dueAt: null, hasTime: false })}
          />
        </View>
        <Text style={{ color: colors.muted, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 1, paddingHorizontal: 8 }}>
          {task.dueAt === null ? 'Nessuna data' : `Ora: ${dueLabel(task.dueAt, task.hasTime)}`}
        </Text>
        <TextInput
          value={when}
          onChangeText={(v) => {
            setWhen(v);
            setWhenError(false);
          }}
          onSubmitEditing={applyWhen}
          returnKeyType="done"
          placeholder="Oppure scrivi: venerdì alle 18"
          placeholderTextColor={colors.muted}
          accessibilityLabel="Scrivi quando"
          style={[styles.input, inputStyle, whenError && { borderColor: colors.important }]}
        />
        {whenError && (
          <Text style={{ color: colors.important, fontFamily: look.fonts.meta, fontSize: look.sizes.meta + 1, paddingHorizontal: 8 }}>
            Non ho capito la data. Prova con «domani alle 15» o «lunedì».
          </Text>
        )}

        {/* lista */}
        <SectionLabel>LISTA</SectionLabel>
        <View style={styles.chips}>
          <Chip label="Nessuna" active={task.projectId === null} onPress={() => patch({ projectId: null })} />
          {projects.map((p) => (
            <Chip
              key={p.id}
              label={p.name}
              dot={p.color}
              active={task.projectId === p.id}
              onPress={() => patch({ projectId: p.id })}
            />
          ))}
        </View>

        {/* importante */}
        <Pressable
          onPress={() => patch({ important: !task.important })}
          accessibilityRole="switch"
          accessibilityState={{ checked: task.important }}
          style={[
            styles.importantRow,
            { backgroundColor: colors.card, borderColor: colors.border, borderRadius: square ? 0 : 14 },
          ]}
        >
          <Icon
            name="star"
            size={22}
            color={task.important ? colors.important : colors.ring}
            filled={task.important}
            strokeWidth={1.8}
          />
          <Text style={{ flex: 1, color: colors.text, fontFamily: look.fonts.body, fontSize: look.sizes.body }}>Importante</Text>
        </Pressable>

        {/* passi */}
        <SectionLabel>PASSI</SectionLabel>
        <Panel>
          {subs.map((s, i) => (
            <View key={s.id} style={[styles.step, i < subs.length - 1 && { borderBottomWidth: 1, borderBottomColor: colors.divider }]}>
              <Pressable
                onPress={async () => {
                  await setSubtaskDone(db, s.id, s.doneAt === null);
                  await reload();
                }}
                accessibilityRole="checkbox"
                accessibilityState={{ checked: s.doneAt !== null }}
                accessibilityLabel={s.title}
                style={styles.touch}
              >
                <View
                  style={[
                    square ? styles.square : styles.circle,
                    s.doneAt !== null ? { backgroundColor: colors.done, borderColor: colors.done } : { borderColor: colors.ring },
                  ]}
                >
                  {s.doneAt !== null && <Icon name="check" size={14} color={colors.onDone} strokeWidth={3.2} />}
                </View>
              </Pressable>
              <Text
                style={[
                  { flex: 1, color: colors.text, fontFamily: look.fonts.body, fontSize: look.sizes.body },
                  s.doneAt !== null && { textDecorationLine: 'line-through', color: colors.muted },
                ]}
              >
                {s.title}
              </Text>
              <Pressable
                onPress={async () => {
                  await deleteSubtask(db, s.id);
                  await reload();
                }}
                accessibilityRole="button"
                accessibilityLabel={`Elimina il passo ${s.title}`}
                style={styles.touch}
              >
                <Icon name="close" size={18} color={colors.muted} strokeWidth={2} />
              </Pressable>
            </View>
          ))}
          <View style={styles.step}>
            <View style={styles.touch}>
              <Icon name="plus" size={22} color={colors.primary} strokeWidth={2.4} />
            </View>
            <TextInput
              value={newStep}
              onChangeText={setNewStep}
              onSubmitEditing={addStep}
              returnKeyType="done"
              placeholder="Aggiungi un passo"
              placeholderTextColor={colors.muted}
              accessibilityLabel="Nuovo passo"
              style={{ flex: 1, color: colors.text, fontFamily: look.fonts.body, fontSize: look.sizes.body, paddingVertical: 0 }}
            />
          </View>
        </Panel>

        <Pressable onPress={confirmDelete} accessibilityRole="button" style={styles.delete}>
          <Text style={{ color: colors.important, fontFamily: look.fonts.strong, fontSize: look.sizes.strong + 2 }}>
            Elimina attività
          </Text>
        </Pressable>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  content: { padding: 16, paddingBottom: 48, gap: 10 },
  titleRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 4, marginLeft: -6 },
  touch: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  circle: { width: 24, height: 24, borderRadius: 12, borderWidth: 2, alignItems: 'center', justifyContent: 'center' },
  square: { width: 22, height: 22, borderRadius: 0, borderWidth: 2, alignItems: 'center', justifyContent: 'center' },
  title: { flex: 1, paddingTop: 8, paddingBottom: 8 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  input: { borderWidth: 1, paddingHorizontal: 14, height: 48 },
  importantRow: { flexDirection: 'row', alignItems: 'center', gap: 12, minHeight: 52, paddingHorizontal: 16, borderWidth: 1 },
  step: { flexDirection: 'row', alignItems: 'center', gap: 4, minHeight: 52, paddingLeft: 8, paddingRight: 4 },
  delete: { height: 52, alignItems: 'center', justifyContent: 'center', marginTop: 8 },
});
