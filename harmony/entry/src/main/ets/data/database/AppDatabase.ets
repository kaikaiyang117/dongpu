import { relationalStore } from '@kit.ArkData';

const DATABASE_NAME: string = 'dongpu.db';
const DATABASE_VERSION: number = 1;

const SCHEMA: string[] = [
  `CREATE TABLE IF NOT EXISTS app_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    weekly_frequency INTEGER NOT NULL DEFAULT 2,
    onboarding_completed INTEGER NOT NULL DEFAULT 0,
    weight_unit TEXT NOT NULL DEFAULT 'kg'
  )`,
  `CREATE TABLE IF NOT EXISTS user_program_state (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    next_workout_code TEXT NOT NULL DEFAULT 'A',
    weekly_completed INTEGER NOT NULL DEFAULT 0,
    week_started_at INTEGER NOT NULL DEFAULT 0
  )`,
  `CREATE TABLE IF NOT EXISTS user_workout_plan (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS user_plan_exercise (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plan_id INTEGER NOT NULL,
    exercise_id TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    sets INTEGER NOT NULL,
    rep_min INTEGER NOT NULL,
    rep_max INTEGER NOT NULL,
    rest_seconds INTEGER NOT NULL,
    FOREIGN KEY(plan_id) REFERENCES user_workout_plan(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS workout_session (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_code TEXT NOT NULL,
    workout_name_snapshot TEXT NOT NULL,
    source_type TEXT NOT NULL,
    status TEXT NOT NULL,
    phase TEXT NOT NULL,
    current_exercise_index INTEGER NOT NULL DEFAULT 0,
    started_at INTEGER NOT NULL,
    completed_at INTEGER NOT NULL DEFAULT 0,
    rest_end_at INTEGER NOT NULL DEFAULT 0
  )`,
  `CREATE TABLE IF NOT EXISTS workout_exercise_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL,
    original_exercise_id TEXT NOT NULL,
    actual_exercise_id TEXT NOT NULL,
    exercise_name_snapshot TEXT NOT NULL,
    part_name_snapshot TEXT NOT NULL,
    equipment_name_snapshot TEXT NOT NULL,
    image_path_snapshot TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    target_sets INTEGER NOT NULL,
    rep_min INTEGER NOT NULL,
    rep_max INTEGER NOT NULL,
    rest_seconds INTEGER NOT NULL,
    completed_sets INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY(session_id) REFERENCES workout_session(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS set_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    exercise_record_id INTEGER NOT NULL,
    set_number INTEGER NOT NULL,
    weight REAL NOT NULL,
    reps INTEGER NOT NULL,
    completed_at INTEGER NOT NULL,
    FOREIGN KEY(exercise_record_id) REFERENCES workout_exercise_record(id) ON DELETE CASCADE
  )`,
  `CREATE UNIQUE INDEX IF NOT EXISTS one_active_workout
    ON workout_session(status) WHERE status = 'active'`,
  `CREATE UNIQUE INDEX IF NOT EXISTS one_draft_plan
    ON user_workout_plan(status) WHERE status = 'draft'`,
  `CREATE INDEX IF NOT EXISTS workout_history_by_date
    ON workout_session(status, completed_at DESC)`,
  `CREATE INDEX IF NOT EXISTS exercise_records_by_session
    ON workout_exercise_record(session_id, order_index)`
];

export class AppDatabase {
  private static store: relationalStore.RdbStore | undefined;

  static async getStore(context: Context): Promise<relationalStore.RdbStore> {
    if (AppDatabase.store !== undefined) {
      return AppDatabase.store;
    }

    const config: relationalStore.StoreConfig = {
      name: DATABASE_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, config);
    const currentVersion: number = store.version;
    if (currentVersion < 1) {
      await AppDatabase.createSchemaV1(store);
    }
    store.version = DATABASE_VERSION;
    AppDatabase.store = store;
    return store;
  }

  private static async createSchemaV1(store: relationalStore.RdbStore): Promise<void> {
    for (const sql of SCHEMA) {
      await store.executeSql(sql);
    }
    await store.executeSql(
      `INSERT OR IGNORE INTO app_settings (id, weekly_frequency, onboarding_completed, weight_unit)
       VALUES (1, 2, 0, 'kg')`
    );
    await store.executeSql(
      `INSERT OR IGNORE INTO user_program_state (id, next_workout_code, weekly_completed, week_started_at)
       VALUES (1, 'A', 0, 0)`
    );
  }
}
