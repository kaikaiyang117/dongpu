import { relationalStore } from '@kit.ArkData';
import { FitnessGoal } from '../../domain/goal/GoalModels';
import { ActiveProgramState } from '../../domain/program/ProgramV2Models';
import { AppDatabase } from '../database/AppDatabase';

export class GoalRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async getActiveGoal(): Promise<FitnessGoal | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, goal_type, start_weight_kg, target_weight_kg, start_date, target_calories,
       target_protein_g, target_steps, training_frequency_min, training_frequency_max,
       training_location, dedicated_leg_day, prefer_machines, status, created_at, updated_at
       FROM fitness_goal WHERE status = 'active' ORDER BY updated_at DESC LIMIT 1`
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      return this.readGoal(result);
    } finally {
      result.close();
    }
  }

  async saveActiveGoal(goal: FitnessGoal): Promise<FitnessGoal> {
    if (goal.startWeightKg <= 0 || goal.targetWeightKg <= 0 || goal.targetCalories < 0 ||
      goal.targetProteinG < 0 || goal.targetSteps < 0) {
      throw new Error('Invalid goal values');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const now: number = Date.now();
    store.beginTransaction();
    try {
      await store.executeSql('UPDATE fitness_goal SET status = \'archived\', updated_at = ? WHERE status = \'active\'',
        [now]);
      const id: number = await store.insert('fitness_goal', {
        goal_type: goal.goalType,
        start_weight_kg: goal.startWeightKg,
        target_weight_kg: goal.targetWeightKg,
        start_date: goal.startDate > 0 ? goal.startDate : now,
        target_calories: goal.targetCalories,
        target_protein_g: goal.targetProteinG,
        target_steps: goal.targetSteps,
        training_frequency_min: goal.trainingFrequencyMin,
        training_frequency_max: goal.trainingFrequencyMax,
        training_location: goal.trainingLocation,
        dedicated_leg_day: goal.dedicatedLegDay ? 1 : 0,
        prefer_machines: goal.preferMachines ? 1 : 0,
        status: 'active',
        created_at: goal.createdAt > 0 ? goal.createdAt : now,
        updated_at: now
      });
      store.commit();
      return new FitnessGoal(id, goal.goalType, goal.startWeightKg, goal.targetWeightKg,
        goal.startDate > 0 ? goal.startDate : now, goal.targetCalories, goal.targetProteinG, goal.targetSteps,
        goal.trainingFrequencyMin, goal.trainingFrequencyMax, goal.trainingLocation, goal.dedicatedLegDay,
        goal.preferMachines, 'active', goal.createdAt > 0 ? goal.createdAt : now, now);
    } catch (_) {
      store.rollBack();
      throw new Error('Unable to save active goal');
    }
  }

  async updateActiveTargets(targetCalories: number, targetProteinG: number, targetSteps: number): Promise<void> {
    if (targetCalories < 0 || targetProteinG < 0 || targetSteps < 0) {
      throw new Error('Invalid goal targets');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql(
      `UPDATE fitness_goal SET target_calories = ?, target_protein_g = ?, target_steps = ?, updated_at = ?
       WHERE status = 'active'`,
      [targetCalories, targetProteinG, targetSteps, Date.now()]
    );
  }

  async updateActiveTrainingPreference(frequency: number, location: string, dedicatedLegDay: boolean,
    preferMachines: boolean): Promise<void> {
    if (frequency < 1 || frequency > 7 || location === '') {
      throw new Error('Invalid training preference');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql(
      `UPDATE fitness_goal SET training_frequency_min = ?, training_frequency_max = ?, training_location = ?,
       dedicated_leg_day = ?, prefer_machines = ?, updated_at = ? WHERE status = 'active'`,
      [frequency, frequency, location, dedicatedLegDay ? 1 : 0, preferMachines ? 1 : 0, Date.now()]
    );
  }

  async getActiveProgramState(): Promise<ActiveProgramState | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, goal_id, program_id, program_version, started_at, current_week, next_required_workout_index
       FROM active_program_state WHERE id = 1`
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      return new ActiveProgramState(result.getLong(0), result.getLong(1), result.getString(2), result.getString(3),
        result.getLong(4), result.getLong(5), result.getLong(6));
    } finally {
      result.close();
    }
  }

  async saveActiveProgramState(state: ActiveProgramState): Promise<ActiveProgramState> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql(
      `INSERT OR REPLACE INTO active_program_state
       (id, goal_id, program_id, program_version, started_at, current_week, next_required_workout_index)
       VALUES (1, ?, ?, ?, ?, ?, ?)`,
      [state.goalId, state.programId, state.programVersion, state.startedAt, state.currentWeek,
        state.nextRequiredWorkoutIndex]
    );
    return state;
  }

  private readGoal(result: relationalStore.ResultSet): FitnessGoal {
    return new FitnessGoal(result.getLong(0), result.getString(1), result.getDouble(2), result.getDouble(3),
      result.getLong(4), result.getLong(5), result.getLong(6), result.getLong(7), result.getLong(8),
      result.getLong(9), result.getString(10), result.getLong(11) === 1, result.getLong(12) === 1,
      result.getString(13), result.getLong(14), result.getLong(15));
  }
}
