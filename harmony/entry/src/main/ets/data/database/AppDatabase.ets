import { relationalStore } from '@kit.ArkData';

const DATABASE_NAME: string = 'dongpu.db';
const DATABASE_VERSION: number = 3;

interface QuickFoodSeed {
  name: string;
  servingName: string;
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
}

interface ProgramWorkoutSeed {
  id: string;
  code: string;
  name: string;
  focusText: string;
  orderIndex: number;
  optional: number;
  estimatedMinutes: number;
}

interface ProgramExerciseSeed {
  workoutId: string;
  exerciseId: string;
  orderIndex: number;
  plannedSets: number;
  repMin: number;
  repMax: number;
  restSeconds: number;
  weightIncrementKg: number;
}

const V1_SCHEMA: string[] = [
  `CREATE TABLE IF NOT EXISTS app_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    weekly_frequency INTEGER NOT NULL DEFAULT 3,
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

const V2_SCHEMA: string[] = [
  `CREATE TABLE IF NOT EXISTS user_profile (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    height_cm REAL NOT NULL DEFAULT 0,
    sex TEXT,
    birth_year INTEGER,
    onboarding_completed INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS fitness_goal (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    goal_type TEXT NOT NULL,
    start_weight_kg REAL NOT NULL,
    target_weight_kg REAL NOT NULL,
    start_date INTEGER NOT NULL,
    target_calories INTEGER NOT NULL,
    target_protein_g INTEGER NOT NULL,
    target_steps INTEGER NOT NULL,
    training_frequency_min INTEGER NOT NULL,
    training_frequency_max INTEGER NOT NULL,
    training_location TEXT NOT NULL,
    dedicated_leg_day INTEGER NOT NULL DEFAULT 0,
    prefer_machines INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS body_measurement (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recorded_at INTEGER NOT NULL,
    weight_kg REAL,
    waist_cm REAL,
    body_fat_percent REAL,
    note TEXT
  )`,
  `CREATE TABLE IF NOT EXISTS quick_food (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    serving_name TEXT NOT NULL,
    calories REAL NOT NULL,
    protein_g REAL NOT NULL,
    carbs_g REAL,
    fat_g REAL,
    is_builtin INTEGER NOT NULL DEFAULT 0,
    is_enabled INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS food_entry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recorded_at INTEGER NOT NULL,
    meal_type TEXT NOT NULL,
    food_name TEXT NOT NULL,
    serving_name TEXT,
    servings REAL NOT NULL DEFAULT 1,
    calories REAL NOT NULL,
    protein_g REAL NOT NULL,
    carbs_g REAL,
    fat_g REAL,
    quick_food_id INTEGER,
    created_at INTEGER NOT NULL,
    FOREIGN KEY(quick_food_id) REFERENCES quick_food(id) ON DELETE SET NULL
  )`,
  `CREATE TABLE IF NOT EXISTS daily_activity (
    date_key TEXT PRIMARY KEY,
    steps INTEGER NOT NULL DEFAULT 0,
    cardio_minutes INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'manual',
    updated_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS training_program (
    id TEXT PRIMARY KEY,
    version TEXT NOT NULL,
    name TEXT NOT NULL,
    goal_type TEXT NOT NULL,
    duration_weeks INTEGER NOT NULL,
    min_sessions INTEGER NOT NULL,
    max_sessions INTEGER NOT NULL,
    review_status TEXT NOT NULL,
    is_builtin INTEGER NOT NULL DEFAULT 1
  )`,
  `CREATE TABLE IF NOT EXISTS program_workout (
    id TEXT PRIMARY KEY,
    program_id TEXT NOT NULL,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    focus_text TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    optional INTEGER NOT NULL DEFAULT 0,
    estimated_minutes INTEGER NOT NULL,
    FOREIGN KEY(program_id) REFERENCES training_program(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS program_workout_exercise (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    workout_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    planned_sets INTEGER NOT NULL,
    rep_min INTEGER NOT NULL,
    rep_max INTEGER NOT NULL,
    rest_seconds INTEGER NOT NULL,
    weight_increment_kg REAL NOT NULL DEFAULT 2.5,
    FOREIGN KEY(workout_id) REFERENCES program_workout(id) ON DELETE CASCADE
  )`,
  `CREATE TABLE IF NOT EXISTS active_program_state (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    goal_id INTEGER NOT NULL,
    program_id TEXT NOT NULL,
    program_version TEXT NOT NULL,
    started_at INTEGER NOT NULL,
    current_week INTEGER NOT NULL DEFAULT 1,
    next_required_workout_index INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY(goal_id) REFERENCES fitness_goal(id),
    FOREIGN KEY(program_id) REFERENCES training_program(id)
  )`,
  `CREATE INDEX IF NOT EXISTS body_measurement_by_date
    ON body_measurement(recorded_at DESC)`,
  `CREATE INDEX IF NOT EXISTS food_entry_by_date
    ON food_entry(recorded_at DESC)`,
  `CREATE UNIQUE INDEX IF NOT EXISTS one_active_goal
    ON fitness_goal(status) WHERE status = 'active'`,
  `CREATE UNIQUE INDEX IF NOT EXISTS builtin_quick_food_identity
    ON quick_food(name, serving_name) WHERE is_builtin = 1`,
  `CREATE UNIQUE INDEX IF NOT EXISTS one_program_workout_exercise
    ON program_workout_exercise(workout_id, order_index)`
];

const QUICK_FOOD_SEEDS: QuickFoodSeed[] = [
  { name: '乳清蛋白', servingName: '1 勺', calories: 120, proteinG: 24, carbsG: 3, fatG: 2 },
  { name: '鸡蛋', servingName: '2 个', calories: 140, proteinG: 12, carbsG: 1, fatG: 10 },
  { name: '牛奶', servingName: '250ml', calories: 160, proteinG: 8, carbsG: 12, fatG: 8 },
  { name: '鸡胸肉', servingName: '200g', calories: 330, proteinG: 60, carbsG: 0, fatG: 7 }
];

const PROGRAM_ID: string = 'fat_loss_upper_priority_3_4';
const PROGRAM_WORKOUT_SEEDS: ProgramWorkoutSeed[] = [
  { id: `${PROGRAM_ID}_push`, code: 'push', name: 'Push', focusText: '胸 / 肩 / 三头', orderIndex: 0, optional: 0, estimatedMinutes: 55 },
  { id: `${PROGRAM_ID}_pull_posterior`, code: 'pull_posterior', name: 'Pull + 后链', focusText: '背 / 二头 / 后链', orderIndex: 1, optional: 0, estimatedMinutes: 55 },
  { id: `${PROGRAM_ID}_upper`, code: 'upper', name: 'Upper', focusText: '胸 / 背 / 肩 / 少量腿部', orderIndex: 2, optional: 0, estimatedMinutes: 60 },
  { id: `${PROGRAM_ID}_optional`, code: 'optional_arms', name: 'Optional', focusText: '肩 / 手臂 / 低强度有氧', orderIndex: 3, optional: 1, estimatedMinutes: 30 }
];

// The catalog has no approved bench-press or triceps-extension entry, so 0577/0200
// are the nearest approved + gymEligible machine/cable substitutions.
// The same rule selects 1350/0599/0215/0868 for chest-supported row/RDL/face-pull/
// dumbbell-curl references that are not present as approved catalog entries.
const PROGRAM_EXERCISE_SEEDS: ProgramExerciseSeed[] = [
  { workoutId: `${PROGRAM_ID}_push`, exerciseId: '0577', orderIndex: 0, plannedSets: 4, repMin: 6, repMax: 10, restSeconds: 90, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_push`, exerciseId: '1299', orderIndex: 1, plannedSets: 3, repMin: 8, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_push`, exerciseId: '0603', orderIndex: 2, plannedSets: 3, repMin: 8, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_push`, exerciseId: '0584', orderIndex: 3, plannedSets: 4, repMin: 12, repMax: 20, restSeconds: 60, weightIncrementKg: 1 },
  { workoutId: `${PROGRAM_ID}_push`, exerciseId: '0200', orderIndex: 4, plannedSets: 3, repMin: 10, repMax: 15, restSeconds: 60, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_push`, exerciseId: '0200', orderIndex: 5, plannedSets: 2, repMin: 10, repMax: 15, restSeconds: 60, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_pull_posterior`, exerciseId: '0818', orderIndex: 0, plannedSets: 4, repMin: 8, repMax: 12, restSeconds: 90, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_pull_posterior`, exerciseId: '1350', orderIndex: 1, plannedSets: 3, repMin: 8, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_pull_posterior`, exerciseId: '1350', orderIndex: 2, plannedSets: 3, repMin: 8, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_pull_posterior`, exerciseId: '0599', orderIndex: 3, plannedSets: 3, repMin: 8, repMax: 12, restSeconds: 90, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_pull_posterior`, exerciseId: '0215', orderIndex: 4, plannedSets: 3, repMin: 12, repMax: 20, restSeconds: 60, weightIncrementKg: 1 },
  { workoutId: `${PROGRAM_ID}_pull_posterior`, exerciseId: '0868', orderIndex: 5, plannedSets: 3, repMin: 10, repMax: 15, restSeconds: 60, weightIncrementKg: 1 },
  { workoutId: `${PROGRAM_ID}_upper`, exerciseId: '1299', orderIndex: 0, plannedSets: 3, repMin: 8, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_upper`, exerciseId: '0818', orderIndex: 1, plannedSets: 3, repMin: 8, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_upper`, exerciseId: '0577', orderIndex: 2, plannedSets: 3, repMin: 10, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_upper`, exerciseId: '1350', orderIndex: 3, plannedSets: 3, repMin: 10, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_upper`, exerciseId: '2287', orderIndex: 4, plannedSets: 3, repMin: 10, repMax: 15, restSeconds: 90, weightIncrementKg: 5 },
  { workoutId: `${PROGRAM_ID}_upper`, exerciseId: '0584', orderIndex: 5, plannedSets: 4, repMin: 12, repMax: 20, restSeconds: 60, weightIncrementKg: 1 },
  { workoutId: `${PROGRAM_ID}_upper`, exerciseId: '0868', orderIndex: 6, plannedSets: 3, repMin: 10, repMax: 15, restSeconds: 60, weightIncrementKg: 1 },
  { workoutId: `${PROGRAM_ID}_upper`, exerciseId: '0200', orderIndex: 7, plannedSets: 3, repMin: 10, repMax: 15, restSeconds: 60, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_optional`, exerciseId: '0603', orderIndex: 0, plannedSets: 3, repMin: 8, repMax: 12, restSeconds: 75, weightIncrementKg: 2.5 },
  { workoutId: `${PROGRAM_ID}_optional`, exerciseId: '0584', orderIndex: 1, plannedSets: 4, repMin: 12, repMax: 20, restSeconds: 60, weightIncrementKg: 1 },
  { workoutId: `${PROGRAM_ID}_optional`, exerciseId: '0868', orderIndex: 2, plannedSets: 3, repMin: 10, repMax: 15, restSeconds: 60, weightIncrementKg: 1 },
  { workoutId: `${PROGRAM_ID}_optional`, exerciseId: '0200', orderIndex: 3, plannedSets: 3, repMin: 10, repMax: 15, restSeconds: 60, weightIncrementKg: 2.5 }
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
    if (currentVersion === 0) {
      await AppDatabase.createSchemaV1(store);
    }
    if (currentVersion < 2) {
      await AppDatabase.migrateV1ToV2(store);
      store.version = 2;
    }
    if (store.version < 3) {
      await AppDatabase.migrateV2ToV3(store);
      store.version = DATABASE_VERSION;
    }
    // Repair stores created by pre-V2 builds whose version was already advanced.
    for (const sql of V2_SCHEMA) {
      await store.executeSql(sql);
    }
    await AppDatabase.addColumnIfMissing(store, 'workout_session', 'program_id', 'TEXT');
    await AppDatabase.addColumnIfMissing(store, 'workout_session', 'program_workout_id', 'TEXT');
    await AppDatabase.addColumnIfMissing(store, 'workout_session', 'program_version', 'TEXT');
    await AppDatabase.addColumnIfMissing(store, 'workout_session', 'goal_id', 'INTEGER');
    await AppDatabase.addColumnIfMissing(store, 'workout_exercise_record', 'suggested_weight_kg', 'REAL');
    await AppDatabase.addColumnIfMissing(store, 'workout_exercise_record', 'program_workout_exercise_id', 'INTEGER');
    await AppDatabase.addColumnIfMissing(store, 'workout_exercise_record', 'weight_increment_kg', 'REAL NOT NULL DEFAULT 2.5');
    await AppDatabase.backfillV3(store);
    // Keep built-in catalog rows available for databases created by an earlier V2 build.
    await AppDatabase.seedV2(store);
    AppDatabase.store = store;
    return store;
  }

  private static async createSchemaV1(store: relationalStore.RdbStore): Promise<void> {
    for (const sql of V1_SCHEMA) {
      await store.executeSql(sql);
    }
    await store.executeSql(
      `INSERT OR IGNORE INTO app_settings (id, weekly_frequency, onboarding_completed, weight_unit)
       VALUES (1, 3, 0, 'kg')`
    );
    await store.executeSql(
      `INSERT OR IGNORE INTO user_program_state (id, next_workout_code, weekly_completed, week_started_at)
       VALUES (1, 'A', 0, 0)`
    );
  }

  private static async migrateV1ToV2(store: relationalStore.RdbStore): Promise<void> {
    for (const sql of V2_SCHEMA) {
      await store.executeSql(sql);
    }
    await AppDatabase.addColumnIfMissing(store, 'workout_session', 'program_id', 'TEXT');
    await AppDatabase.addColumnIfMissing(store, 'workout_session', 'program_workout_id', 'TEXT');
    await AppDatabase.addColumnIfMissing(store, 'workout_session', 'program_version', 'TEXT');
    await AppDatabase.addColumnIfMissing(store, 'workout_session', 'goal_id', 'INTEGER');
    await AppDatabase.addColumnIfMissing(store, 'workout_exercise_record', 'suggested_weight_kg', 'REAL');
    await AppDatabase.seedV2(store);
  }

  private static async migrateV2ToV3(store: relationalStore.RdbStore): Promise<void> {
    await AppDatabase.addColumnIfMissing(store, 'workout_exercise_record', 'program_workout_exercise_id', 'INTEGER');
    await AppDatabase.addColumnIfMissing(store, 'workout_exercise_record', 'weight_increment_kg', 'REAL NOT NULL DEFAULT 2.5');
    await AppDatabase.backfillV3(store);
  }

  private static async backfillV3(store: relationalStore.RdbStore): Promise<void> {
    await store.executeSql(
      `UPDATE workout_exercise_record
       SET program_workout_exercise_id = (
         SELECT pwe.id FROM program_workout_exercise pwe
         JOIN workout_session ws ON ws.program_workout_id = pwe.workout_id
         WHERE ws.id = workout_exercise_record.session_id
           AND pwe.order_index = workout_exercise_record.order_index
       ),
       weight_increment_kg = COALESCE((
         SELECT pwe.weight_increment_kg FROM program_workout_exercise pwe
         JOIN workout_session ws ON ws.program_workout_id = pwe.workout_id
         WHERE ws.id = workout_exercise_record.session_id
           AND pwe.order_index = workout_exercise_record.order_index
       ), 2.5)
       WHERE program_workout_exercise_id IS NULL`
    );
  }

  private static async addColumnIfMissing(store: relationalStore.RdbStore, table: string, column: string,
    definition: string): Promise<void> {
    const result: relationalStore.ResultSet = await store.querySql(`PRAGMA table_info(${table})`);
    let exists: boolean = false;
    try {
      if (result.goToFirstRow()) {
        do {
          if (result.getString(1) === column) {
            exists = true;
            break;
          }
        } while (result.goToNextRow());
      }
    } finally {
      result.close();
    }
    if (!exists) {
      await store.executeSql(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
    }
  }

  private static async seedV2(store: relationalStore.RdbStore): Promise<void> {
    const now: number = Date.now();
    for (const food of QUICK_FOOD_SEEDS) {
      await store.executeSql(
        `INSERT OR IGNORE INTO quick_food
         (name, serving_name, calories, protein_g, carbs_g, fat_g, is_builtin, is_enabled, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, 1, 1, ?, ?)`,
        [food.name, food.servingName, food.calories, food.proteinG, food.carbsG, food.fatG, now, now]
      );
    }
    await store.executeSql(
      `INSERT OR IGNORE INTO training_program
       (id, version, name, goal_type, duration_weeks, min_sessions, max_sessions, review_status, is_builtin)
       VALUES (?, '1.0', '减脂 · 上肢优先 · 3—4练', 'fat_loss', 8, 3, 4, 'approved', 1)`,
      [PROGRAM_ID]
    );
    for (const workout of PROGRAM_WORKOUT_SEEDS) {
      await store.executeSql(
        `INSERT OR IGNORE INTO program_workout
         (id, program_id, code, name, focus_text, order_index, optional, estimated_minutes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [workout.id, PROGRAM_ID, workout.code, workout.name, workout.focusText, workout.orderIndex,
          workout.optional, workout.estimatedMinutes]
      );
    }
    for (const exercise of PROGRAM_EXERCISE_SEEDS) {
      await store.executeSql(
        `INSERT OR IGNORE INTO program_workout_exercise
         (workout_id, exercise_id, order_index, planned_sets, rep_min, rep_max, rest_seconds, weight_increment_kg)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [exercise.workoutId, exercise.exerciseId, exercise.orderIndex, exercise.plannedSets, exercise.repMin,
          exercise.repMax, exercise.restSeconds, exercise.weightIncrementKg]
      );
    }
  }
}
