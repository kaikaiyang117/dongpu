import { relationalStore } from '@kit.ArkData';
import { AppSettings } from '../../domain/settings/AppSettings';
import { AppDatabase } from '../database/AppDatabase';

export class SettingsRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async getSettings(): Promise<AppSettings> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      'SELECT weekly_frequency, onboarding_completed, weight_unit FROM app_settings WHERE id = 1'
    );
    try {
      if (!result.goToFirstRow()) {
        return new AppSettings();
      }
      return new AppSettings(result.getLong(0), result.getLong(1) === 1, result.getString(2));
    } finally {
      result.close();
    }
  }

  async completeOnboarding(weeklyFrequency: number): Promise<void> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql(
      'UPDATE app_settings SET weekly_frequency = ?, onboarding_completed = 1 WHERE id = 1',
      [weeklyFrequency]
    );
  }

  async updateWeeklyFrequency(weeklyFrequency: number): Promise<void> {
    if (weeklyFrequency !== 3 && weeklyFrequency !== 4) {
      throw new Error('V2 supports three or four weekly sessions');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql('UPDATE app_settings SET weekly_frequency = ? WHERE id = 1', [weeklyFrequency]);
  }

  async updateWeightUnit(weightUnit: string): Promise<void> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql('UPDATE app_settings SET weight_unit = ? WHERE id = 1', [weightUnit]);
  }
}
