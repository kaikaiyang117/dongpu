import { relationalStore } from '@kit.ArkData';
import { ProgramExercise, ProgramWorkout } from '../../domain/program/ProgramModels';
import {
  ExerciseProgress,
  SetRecord,
  UserProgramState,
  WorkoutExerciseRecord,
  WorkoutPhase,
  WorkoutSession,
  WorkoutStatus
} from '../../domain/workout/WorkoutModels';
import { AppDatabase } from '../database/AppDatabase';

export class WorkoutRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async getProgramState(): Promise<UserProgramState> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      'SELECT next_workout_code, weekly_completed, week_started_at FROM user_program_state WHERE id = 1'
    );
    try {
      if (!result.goToFirstRow()) {
        return new UserProgramState();
      }
      const nextCode: string = result.getString(0);
      const completed: number = result.getLong(1);
      const weekStartedAt: number = result.getLong(2);
      if (weekStartedAt > 0 && this.isNewWeek(weekStartedAt)) {
        await store.executeSql(
          'UPDATE user_program_state SET weekly_completed = 0, week_started_at = ? WHERE id = 1',
          [Date.now()]
        );
        return new UserProgramState(nextCode, 0);
      }
      return new UserProgramState(nextCode, completed);
    } finally {
      result.close();
    }
  }

  private isNewWeek(weekStartedAt: number): boolean {
    const start: Date = new Date(weekStartedAt);
    const now: Date = new Date();
    const startMonday: Date = this.mondayOf(start);
    const nowMonday: Date = this.mondayOf(now);
    return nowMonday.getTime() > startMonday.getTime();
  }

  private mondayOf(date: Date): Date {
    const d: Date = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const day: number = d.getDay();
    const offset: number = day === 0 ? -6 : 1 - day;
    d.setDate(d.getDate() + offset);
    return d;
  }

  async getActiveWorkout(): Promise<WorkoutSession | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, workout_code, workout_name_snapshot, source_type, status, phase,
       current_exercise_index, started_at, completed_at, rest_end_at
       FROM workout_session WHERE status = 'active' LIMIT 1`
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      const session: WorkoutSession = new WorkoutSession(
        result.getLong(0), result.getString(1), result.getString(2), result.getString(3), WorkoutStatus.Active,
        this.phaseFromString(result.getString(5)), result.getLong(6), result.getLong(7), result.getLong(8),
        result.getLong(9)
      );
      session.exercises = await this.getExercises(store, session.id);
      return session;
    } finally {
      result.close();
    }
  }

  async getHistory(): Promise<WorkoutSession[]> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, workout_code, workout_name_snapshot, source_type, status, phase,
       current_exercise_index, started_at, completed_at, rest_end_at
       FROM workout_session WHERE status = 'completed' ORDER BY completed_at DESC`
    );
    const sessions: WorkoutSession[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          sessions.push(new WorkoutSession(
            result.getLong(0), result.getString(1), result.getString(2), result.getString(3),
            WorkoutStatus.Completed, WorkoutPhase.Complete, result.getLong(6), result.getLong(7),
            result.getLong(8), result.getLong(9)
          ));
        } while (result.goToNextRow());
      }
    } finally {
      result.close();
    }
    for (const session of sessions) {
      session.exercises = await this.getExercises(store, session.id);
    }
    return sessions;
  }

  async startRecommendedWorkout(workout: ProgramWorkout): Promise<WorkoutSession> {
    return this.startWorkout(workout, 'recommended');
  }

  async startCustomWorkout(workout: ProgramWorkout): Promise<WorkoutSession> {
    return this.startWorkout(workout, 'custom');
  }

  private async startWorkout(workout: ProgramWorkout, sourceType: string): Promise<WorkoutSession> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const active: WorkoutSession | undefined = await this.getActiveWorkout();
    if (active !== undefined) {
      return active;
    }

    store.beginTransaction();
    try {
      const sessionId: number = await store.insert('workout_session', {
        workout_code: workout.code,
        workout_name_snapshot: workout.name,
        source_type: sourceType,
        status: WorkoutStatus.Active,
        phase: WorkoutPhase.Exercise,
        current_exercise_index: 0,
        started_at: Date.now(),
        completed_at: 0,
        rest_end_at: 0
      });
      for (let index: number = 0; index < workout.exercises.length; index++) {
        const exercise: ProgramExercise = workout.exercises[index];
        await store.insert('workout_exercise_record', {
          session_id: sessionId,
          original_exercise_id: exercise.exerciseId,
          actual_exercise_id: exercise.exerciseId,
          exercise_name_snapshot: exercise.nameSnapshot,
          part_name_snapshot: exercise.partName,
          equipment_name_snapshot: exercise.equipmentName,
          image_path_snapshot: exercise.imagePath,
          order_index: index,
          target_sets: exercise.sets,
          rep_min: exercise.repMin,
          rep_max: exercise.repMax,
          rest_seconds: exercise.restSeconds,
          completed_sets: 0
        });
      }
      store.commit();
      const session: WorkoutSession | undefined = await this.getActiveWorkout();
      if (session === undefined) {
        throw new Error('Failed to load the new workout session');
      }
      return session;
    } catch (_) {
      store.rollBack();
      throw new Error('Unable to start workout');
    }
  }

  async completeSet(session: WorkoutSession, weight: number, reps: number): Promise<WorkoutSession> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const exercise: WorkoutExerciseRecord = session.exercises[session.currentExerciseIndex];
    const nextCompletedSets: number = exercise.completedSets + 1;
    const isExerciseComplete: boolean = nextCompletedSets >= exercise.targetSets;
    const isWorkoutComplete: boolean = isExerciseComplete &&
      session.currentExerciseIndex >= session.exercises.length - 1;
    let nextPhase: WorkoutPhase = WorkoutPhase.Rest;
    let restEndAt: number = Date.now() + exercise.restSeconds * 1000;
    if (isWorkoutComplete) {
      nextPhase = WorkoutPhase.Complete;
      restEndAt = 0;
    } else if (isExerciseComplete) {
      nextPhase = WorkoutPhase.ExerciseCompleted;
      restEndAt = 0;
    }

    store.beginTransaction();
    try {
      await store.insert('set_record', {
        exercise_record_id: exercise.id,
        set_number: nextCompletedSets,
        weight: weight,
        reps: reps,
        completed_at: Date.now()
      });
      await store.executeSql(
        'UPDATE workout_exercise_record SET completed_sets = ? WHERE id = ?',
        [nextCompletedSets, exercise.id]
      );
      await store.executeSql(
        'UPDATE workout_session SET phase = ?, rest_end_at = ? WHERE id = ?',
        [nextPhase, restEndAt, session.id]
      );
      store.commit();
    } catch (_) {
      store.rollBack();
      throw new Error('Unable to save completed set');
    }
    const updated: WorkoutSession | undefined = await this.getActiveWorkout();
    if (updated === undefined) {
      throw new Error('Unable to reload workout');
    }
    return updated;
  }

  async finishRest(sessionId: number): Promise<WorkoutSession> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql(
      'UPDATE workout_session SET phase = ?, rest_end_at = 0 WHERE id = ?',
      [WorkoutPhase.Exercise, sessionId]
    );
    const updated: WorkoutSession | undefined = await this.getActiveWorkout();
    if (updated === undefined) {
      throw new Error('Unable to reload workout');
    }
    return updated;
  }

  async adjustRest(session: WorkoutSession, deltaSeconds: number): Promise<WorkoutSession> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const baseline: number = Math.max(Date.now(), session.restEndAt);
    const restEndAt: number = Math.max(Date.now(), baseline + deltaSeconds * 1000);
    await store.executeSql('UPDATE workout_session SET rest_end_at = ? WHERE id = ?', [restEndAt, session.id]);
    const updated: WorkoutSession | undefined = await this.getActiveWorkout();
    if (updated === undefined) {
      throw new Error('Unable to reload workout');
    }
    return updated;
  }

  async startNextExercise(session: WorkoutSession): Promise<WorkoutSession> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const nextIndex: number = Math.min(session.exercises.length - 1, session.currentExerciseIndex + 1);
    await store.executeSql(
      'UPDATE workout_session SET current_exercise_index = ?, phase = ?, rest_end_at = 0 WHERE id = ?',
      [nextIndex, WorkoutPhase.Exercise, session.id]
    );
    const updated: WorkoutSession | undefined = await this.getActiveWorkout();
    if (updated === undefined) {
      throw new Error('Unable to reload workout');
    }
    return updated;
  }

  async finishWorkout(session: WorkoutSession): Promise<void> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    store.beginTransaction();
    try {
      await store.executeSql(
        'UPDATE workout_session SET status = ?, phase = ?, completed_at = ?, rest_end_at = 0 WHERE id = ?',
        [WorkoutStatus.Completed, WorkoutPhase.Complete, Date.now(), session.id]
      );
      if (session.sourceType === 'recommended') {
        await store.executeSql(
          `UPDATE user_program_state SET next_workout_code = ?, weekly_completed = weekly_completed + 1,
           week_started_at = CASE WHEN weekly_completed = 0 THEN ? ELSE week_started_at END
           WHERE id = 1`,
          [session.workoutCode === 'A' ? 'B' : 'A', Date.now()]
        );
      } else {
        await store.executeSql(
          `UPDATE user_program_state SET weekly_completed = weekly_completed + 1,
           week_started_at = CASE WHEN weekly_completed = 0 THEN ? ELSE week_started_at END
           WHERE id = 1`,
          [Date.now()]
        );
      }
      store.commit();
    } catch (_) {
      store.rollBack();
      throw new Error('Unable to finish workout');
    }
  }

  async abandonWorkout(sessionId: number): Promise<void> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql(
      'UPDATE workout_session SET status = ?, rest_end_at = 0 WHERE id = ?',
      [WorkoutStatus.Abandoned, sessionId]
    );
  }

  async replaceCurrentExercise(session: WorkoutSession, replacement: ProgramExercise): Promise<WorkoutSession> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const current: WorkoutExerciseRecord = session.exercises[session.currentExerciseIndex];
    await store.executeSql(
      `UPDATE workout_exercise_record SET actual_exercise_id = ?, exercise_name_snapshot = ?,
       part_name_snapshot = ?, equipment_name_snapshot = ?, image_path_snapshot = ? WHERE id = ?`,
      [replacement.exerciseId, replacement.nameSnapshot, replacement.partName, replacement.equipmentName,
        replacement.imagePath, current.id]
    );
    const updated: WorkoutSession | undefined = await this.getActiveWorkout();
    if (updated === undefined) {
      throw new Error('Unable to reload workout');
    }
    return updated;
  }

  async moveCurrentExerciseToEnd(session: WorkoutSession): Promise<WorkoutSession> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const current: WorkoutExerciseRecord = session.exercises[session.currentExerciseIndex];
    const lastIndex: number = session.exercises.length - 1;
    store.beginTransaction();
    try {
      await store.executeSql(
        `UPDATE workout_exercise_record SET order_index = order_index - 1
         WHERE session_id = ? AND order_index > ?`,
        [session.id, current.orderIndex]
      );
      await store.executeSql('UPDATE workout_exercise_record SET order_index = ? WHERE id = ?', [lastIndex, current.id]);
      await store.executeSql('UPDATE workout_session SET phase = ? WHERE id = ?', [WorkoutPhase.Exercise, session.id]);
      store.commit();
    } catch (_) {
      store.rollBack();
      throw new Error('Unable to reorder workout');
    }
    const updated: WorkoutSession | undefined = await this.getActiveWorkout();
    if (updated === undefined) {
      throw new Error('Unable to reload workout');
    }
    return updated;
  }

  private phaseFromString(value: string): WorkoutPhase {
    if (value === WorkoutPhase.Rest) {
      return WorkoutPhase.Rest;
    }
    if (value === WorkoutPhase.ExerciseCompleted) {
      return WorkoutPhase.ExerciseCompleted;
    }
    if (value === WorkoutPhase.Complete) {
      return WorkoutPhase.Complete;
    }
    return WorkoutPhase.Exercise;
  }

  private async getExercises(store: relationalStore.RdbStore, sessionId: number): Promise<WorkoutExerciseRecord[]> {
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, original_exercise_id, actual_exercise_id, exercise_name_snapshot, part_name_snapshot,
       equipment_name_snapshot, image_path_snapshot, order_index, target_sets, rep_min, rep_max,
       rest_seconds, completed_sets
       FROM workout_exercise_record WHERE session_id = ? ORDER BY order_index`,
      [sessionId]
    );
    const exercises: WorkoutExerciseRecord[] = [];
    try {
      if (!result.goToFirstRow()) {
        return exercises;
      }
      do {
        exercises.push(new WorkoutExerciseRecord(
          result.getLong(0), sessionId, result.getString(1), result.getString(2), result.getString(3),
          result.getString(4), result.getString(5), result.getString(6), result.getLong(7), result.getLong(8),
          result.getLong(9), result.getLong(10), result.getLong(11), result.getLong(12)
        ));
      } while (result.goToNextRow());
    } finally {
      result.close();
    }
    for (const exercise of exercises) {
      exercise.setRecords = await this.getSetRecords(store, exercise.id);
      if (exercise.setRecords.length > 0) {
        const latest: SetRecord = exercise.setRecords[exercise.setRecords.length - 1];
        exercise.suggestedWeight = latest.weight;
        exercise.suggestedReps = latest.reps;
      } else {
        const previous: SetRecord | undefined = await this.getPreviousSet(store, exercise.actualExerciseId, sessionId);
        if (previous !== undefined) {
          exercise.suggestedWeight = previous.weight;
          exercise.suggestedReps = previous.reps;
        }
      }
    }
    return exercises;
  }

  private async getSetRecords(store: relationalStore.RdbStore, exerciseRecordId: number): Promise<SetRecord[]> {
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, set_number, weight, reps, completed_at FROM set_record
       WHERE exercise_record_id = ? ORDER BY set_number`,
      [exerciseRecordId]
    );
    const records: SetRecord[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          records.push(new SetRecord(
            result.getLong(0), exerciseRecordId, result.getLong(1), result.getDouble(2), result.getLong(3),
            result.getLong(4)
          ));
        } while (result.goToNextRow());
      }
      return records;
    } finally {
      result.close();
    }
  }

  private async getPreviousSet(store: relationalStore.RdbStore, exerciseId: string,
    excludedSessionId: number): Promise<SetRecord | undefined> {
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT sr.id, sr.exercise_record_id, sr.set_number, sr.weight, sr.reps, sr.completed_at
       FROM set_record sr
       JOIN workout_exercise_record wer ON wer.id = sr.exercise_record_id
       JOIN workout_session ws ON ws.id = wer.session_id
       WHERE wer.actual_exercise_id = ? AND wer.session_id != ? AND ws.status = 'completed'
       ORDER BY sr.completed_at DESC LIMIT 1`,
      [exerciseId, excludedSessionId]
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      return new SetRecord(
        result.getLong(0), result.getLong(1), result.getLong(2), result.getDouble(3), result.getLong(4),
        result.getLong(5)
      );
    } finally {
      result.close();
    }
  }

  async getProgressHighlights(session: WorkoutSession): Promise<ExerciseProgress[]> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const highlights: ExerciseProgress[] = [];
    for (const exercise of session.exercises) {
      if (exercise.setRecords.length === 0) {
        continue;
      }
      const latest: SetRecord = exercise.setRecords[exercise.setRecords.length - 1];
      const previous: SetRecord | undefined = await this.getPreviousSet(store, exercise.actualExerciseId,
        session.id);
      if (previous === undefined) {
        continue;
      }
      if (latest.weight > previous.weight || latest.reps > previous.reps) {
        highlights.push(new ExerciseProgress(
          exercise.exerciseNameSnapshot, previous.weight, latest.weight, previous.reps, latest.reps
        ));
      }
    }
    return highlights;
  }
}
