import { relationalStore } from '@kit.ArkData';
import { UserPlanExercise, UserWorkoutPlan } from '../../domain/plan/PlanModels';
import { PlanItem } from '../../model/WorkoutData';
import { AppDatabase } from '../database/AppDatabase';

export class PlanRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async getLatestPlan(): Promise<UserWorkoutPlan | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, name, status FROM user_workout_plan
       WHERE status IN ('draft', 'saved') ORDER BY CASE status WHEN 'draft' THEN 0 ELSE 1 END, updated_at DESC LIMIT 1`
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      const plan: UserWorkoutPlan = new UserWorkoutPlan(result.getLong(0), result.getString(1), result.getString(2));
      plan.exercises = await this.getExercises(store, plan.id);
      return plan;
    } finally {
      result.close();
    }
  }

  async saveDraft(items: PlanItem[]): Promise<UserWorkoutPlan> {
    return this.save('draft', items);
  }

  async savePlan(items: PlanItem[]): Promise<UserWorkoutPlan> {
    const plan: UserWorkoutPlan = await this.save('saved', items);
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql("DELETE FROM user_workout_plan WHERE status = 'draft'");
    return plan;
  }

  private async save(status: string, items: PlanItem[]): Promise<UserWorkoutPlan> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const current: UserWorkoutPlan | undefined = await this.findByStatus(store, status);
    store.beginTransaction();
    try {
      let planId: number;
      if (current === undefined) {
        planId = await store.insert('user_workout_plan', {
          name: '我的训练',
          status: status,
          created_at: Date.now(),
          updated_at: Date.now()
        });
      } else {
        planId = current.id;
        await store.executeSql('UPDATE user_workout_plan SET updated_at = ? WHERE id = ?', [Date.now(), planId]);
        await store.executeSql('DELETE FROM user_plan_exercise WHERE plan_id = ?', [planId]);
      }
      for (let index: number = 0; index < items.length; index++) {
        const item: PlanItem = items[index];
        await store.insert('user_plan_exercise', {
          plan_id: planId,
          exercise_id: item.exerciseId,
          order_index: index,
          sets: item.sets,
          rep_min: item.repMin,
          rep_max: item.repMax,
          rest_seconds: item.restSeconds
        });
      }
      store.commit();
      return new UserWorkoutPlan(planId, '我的训练', status,
        items.map((item: PlanItem, index: number) => new UserPlanExercise(
          item.exerciseId, index, item.sets, item.repMin, item.repMax, item.restSeconds
        )));
    } catch (_) {
      store.rollBack();
      throw new Error('Unable to save custom plan');
    }
  }

  private async findByStatus(store: relationalStore.RdbStore, status: string): Promise<UserWorkoutPlan | undefined> {
    const result: relationalStore.ResultSet = await store.querySql(
      'SELECT id, name, status FROM user_workout_plan WHERE status = ? ORDER BY updated_at DESC LIMIT 1',
      [status]
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      return new UserWorkoutPlan(result.getLong(0), result.getString(1), result.getString(2));
    } finally {
      result.close();
    }
  }

  private async getExercises(store: relationalStore.RdbStore, planId: number): Promise<UserPlanExercise[]> {
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT exercise_id, order_index, sets, rep_min, rep_max, rest_seconds
       FROM user_plan_exercise WHERE plan_id = ? ORDER BY order_index`,
      [planId]
    );
    const exercises: UserPlanExercise[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          exercises.push(new UserPlanExercise(
            result.getString(0), result.getLong(1), result.getLong(2), result.getLong(3), result.getLong(4),
            result.getLong(5)
          ));
        } while (result.goToNextRow());
      }
      return exercises;
    } finally {
      result.close();
    }
  }
}
