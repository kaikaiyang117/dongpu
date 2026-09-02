import { relationalStore } from '@kit.ArkData';
import { ProgramWorkoutExerciseV2, ProgramWorkoutV2, TrainingProgram } from '../../domain/program/ProgramV2Models';
import { AppDatabase } from '../database/AppDatabase';

const DEFAULT_PROGRAM_ID: string = 'fat_loss_upper_priority_3_4';

export class ProgramRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async getProgram(programId: string = DEFAULT_PROGRAM_ID): Promise<TrainingProgram | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, version, name, goal_type, duration_weeks, min_sessions, max_sessions, review_status, is_builtin
       FROM training_program WHERE id = ?`, [programId]
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      return new TrainingProgram(result.getString(0), result.getString(1), result.getString(2), result.getString(3),
        result.getLong(4), result.getLong(5), result.getLong(6), result.getString(7), result.getLong(8) === 1);
    } finally {
      result.close();
    }
  }

  async getWorkouts(programId: string = DEFAULT_PROGRAM_ID): Promise<ProgramWorkoutV2[]> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, program_id, code, name, focus_text, order_index, optional, estimated_minutes
       FROM program_workout WHERE program_id = ? ORDER BY order_index ASC`, [programId]
    );
    const workoutRows: ProgramWorkoutV2[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          workoutRows.push(new ProgramWorkoutV2(result.getString(0), result.getString(1), result.getString(2),
            result.getString(3), result.getString(4), result.getLong(5), result.getLong(6) === 1,
            result.getLong(7)));
        } while (result.goToNextRow());
      }
    } finally {
      result.close();
    }
    const workouts: ProgramWorkoutV2[] = [];
    for (const workout of workoutRows) {
      workout.exercises = await this.getWorkoutExercises(store, workout.id);
      workouts.push(workout);
    }
    return workouts;
  }

  async getWorkout(workoutId: string): Promise<ProgramWorkoutV2 | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, program_id, code, name, focus_text, order_index, optional, estimated_minutes
       FROM program_workout WHERE id = ?`, [workoutId]
    );
    let workout: ProgramWorkoutV2 | undefined;
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      workout = new ProgramWorkoutV2(result.getString(0), result.getString(1), result.getString(2), result.getString(3),
        result.getString(4), result.getLong(5), result.getLong(6) === 1, result.getLong(7));
    } finally {
      result.close();
    }
    if (workout === undefined) {
      return undefined;
    }
    workout.exercises = await this.getWorkoutExercises(store, workout.id);
    return workout;
  }

  private async getWorkoutExercises(store: relationalStore.RdbStore, workoutId: string): Promise<ProgramWorkoutExerciseV2[]> {
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, workout_id, exercise_id, order_index, planned_sets, rep_min, rep_max, rest_seconds,
       weight_increment_kg FROM program_workout_exercise WHERE workout_id = ? ORDER BY order_index ASC`, [workoutId]
    );
    const exercises: ProgramWorkoutExerciseV2[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          exercises.push(new ProgramWorkoutExerciseV2(result.getLong(0), result.getString(1), result.getString(2),
            result.getLong(3), result.getLong(4), result.getLong(5), result.getLong(6), result.getLong(7),
            result.getDouble(8)));
        } while (result.goToNextRow());
      }
      return exercises;
    } finally {
      result.close();
    }
  }
}
