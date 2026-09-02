import { relationalStore } from '@kit.ArkData';
import { UserProfile } from '../../domain/profile/ProfileModels';
import { AppDatabase } from '../database/AppDatabase';

export class ProfileRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async getProfile(): Promise<UserProfile | undefined> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, height_cm, sex, birth_year, onboarding_completed, created_at, updated_at
       FROM user_profile WHERE id = 1`
    );
    try {
      if (!result.goToFirstRow()) {
        return undefined;
      }
      return new UserProfile(result.getLong(0), result.getDouble(1), result.getString(2), result.getLong(3),
        result.getLong(4) === 1, result.getLong(5), result.getLong(6));
    } finally {
      result.close();
    }
  }

  async saveProfile(profile: UserProfile): Promise<UserProfile> {
    if (profile.heightCm < 0 || profile.birthYear < 0) {
      throw new Error('Invalid profile values');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const now: number = Date.now();
    const createdAt: number = profile.createdAt > 0 ? profile.createdAt : now;
    await store.executeSql(
      `INSERT OR REPLACE INTO user_profile
       (id, height_cm, sex, birth_year, onboarding_completed, created_at, updated_at)
       VALUES (1, ?, ?, ?, ?, ?, ?)`,
      [profile.heightCm, profile.sex, profile.birthYear > 0 ? profile.birthYear : null,
        profile.onboardingCompleted ? 1 : 0, createdAt, now]
    );
    return new UserProfile(1, profile.heightCm, profile.sex, profile.birthYear, profile.onboardingCompleted,
      createdAt, now);
  }

  async setOnboardingCompleted(completed: boolean): Promise<void> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql('UPDATE user_profile SET onboarding_completed = ?, updated_at = ? WHERE id = 1',
      [completed ? 1 : 0, Date.now()]);
  }
}
