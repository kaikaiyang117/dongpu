import { relationalStore } from '@kit.ArkData';
import { DailyActivity } from '../../domain/activity/ActivityModels';
import { AppDatabase } from '../database/AppDatabase';

export class ActivityRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async get(dateKey: string): Promise<DailyActivity | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      'SELECT date_key, steps, cardio_minutes, source, updated_at FROM daily_activity WHERE date_key = ?', [dateKey]
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      return new DailyActivity(result.getString(0), result.getLong(1), result.getLong(2), result.getString(3),
        result.getLong(4));
    } finally {
      result.close();
    }
  }

  async save(activity: DailyActivity): Promise<DailyActivity> {
    if (activity.dateKey === '' || activity.steps < 0 || activity.cardioMinutes < 0) {
      throw new Error('Invalid activity');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const updatedAt: number = Date.now();
    await store.executeSql(
      `INSERT OR REPLACE INTO daily_activity (date_key, steps, cardio_minutes, source, updated_at)
       VALUES (?, ?, ?, ?, ?)`,
      [activity.dateKey, activity.steps, activity.cardioMinutes, activity.source, updatedAt]
    );
    return new DailyActivity(activity.dateKey, activity.steps, activity.cardioMinutes, activity.source, updatedAt);
  }

  async getRange(startDateKey: string, endDateKey: string): Promise<DailyActivity[]> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT date_key, steps, cardio_minutes, source, updated_at FROM daily_activity
       WHERE date_key >= ? AND date_key < ? ORDER BY date_key ASC`, [startDateKey, endDateKey]
    );
    const activities: DailyActivity[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          activities.push(new DailyActivity(result.getString(0), result.getLong(1), result.getLong(2),
            result.getString(3), result.getLong(4)));
        } while (result.goToNextRow());
      }
      return activities;
    } finally {
      result.close();
    }
  }
}
