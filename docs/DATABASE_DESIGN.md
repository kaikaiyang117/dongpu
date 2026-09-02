# 动谱 V2 数据库设计

| 项目 | 内容 |
| --- | --- |
| 版本 | 2.0 |
| 更新日期 | 2026-09-03 |
| 存储 | HarmonyOS ArkData / relationalStore |
| 原则 | 本地优先、可迁移、历史快照稳定、规则可演进 |

## 1. 设计目标

V2 数据库必须同时支撑四条数据链路：

1. **目标链路**：用户是谁、当前目标是什么、每日目标是多少。
2. **身体链路**：体重、腰围和趋势。
3. **营养链路**：每日摄入、快捷食物、每日汇总。
4. **训练链路**：训练计划、场次、动作、组记录和渐进建议。

现有 V1 的训练历史数据不能因升级而丢失。

## 2. 迁移策略

当前 `DATABASE_VERSION = 1`。V2 实现时升级到：

```ts
const DATABASE_VERSION: number = 2;
```

数据库初始化流程：

```text
version == 0
  -> createSchemaV1
  -> migrateV1ToV2
  -> version = 2

version == 1
  -> migrateV1ToV2
  -> version = 2

version >= 2
  -> 正常打开
```

要求：

- 所有迁移必须幂等。
- 不删除 V1 训练记录。
- 不修改历史 `set_record` 的重量和次数语义。
- 新增字段尽量使用默认值或 nullable，避免旧数据迁移失败。
- 每次迁移完成后再设置 `store.version`。

## 3. V1 表保留策略

以下 V1 表继续保留并演进：

- `app_settings`
- `user_program_state`
- `user_workout_plan`
- `user_plan_exercise`
- `workout_session`
- `workout_exercise_record`
- `set_record`

其中 `user_program_state` 后续不再只围绕 A/B 使用；P0 可以继续保留兼容字段，但新 Program 逻辑应由新表管理。

## 4. 新增表

### 4.1 user_profile

```sql
CREATE TABLE IF NOT EXISTS user_profile (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  height_cm REAL NOT NULL DEFAULT 0,
  sex TEXT,
  birth_year INTEGER,
  onboarding_completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

约束：

- 只存在一行。
- `sex` 为可选，不参与 MVP 强制流程。

### 4.2 fitness_goal

```sql
CREATE TABLE IF NOT EXISTS fitness_goal (
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
);
```

`status`：

```text
active
completed
archived
```

约束：数据库最多只有一个 `active` goal。

推荐索引：

```sql
CREATE UNIQUE INDEX IF NOT EXISTS one_active_goal
ON fitness_goal(status) WHERE status = 'active';
```

### 4.3 body_measurement

```sql
CREATE TABLE IF NOT EXISTS body_measurement (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recorded_at INTEGER NOT NULL,
  weight_kg REAL,
  waist_cm REAL,
  body_fat_percent REAL,
  note TEXT
);
```

规则：

- 至少一个指标非空。
- 体重统一以 kg 保存。
- 腰围统一以 cm 保存。
- UI 单位转换只在展示层处理。

索引：

```sql
CREATE INDEX IF NOT EXISTS body_measurement_by_date
ON body_measurement(recorded_at DESC);
```

### 4.4 quick_food

```sql
CREATE TABLE IF NOT EXISTS quick_food (
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
);
```

首批内置快捷食物：

- 1 勺乳清蛋白
- 2 个鸡蛋
- 250ml 牛奶
- 200g 鸡胸

不要把品牌写死在业务逻辑里。

### 4.5 food_entry

```sql
CREATE TABLE IF NOT EXISTS food_entry (
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
);
```

`meal_type`：

```text
breakfast
lunch
dinner
snack
```

索引：

```sql
CREATE INDEX IF NOT EXISTS food_entry_by_date
ON food_entry(recorded_at DESC);
```

### 4.6 daily_activity

```sql
CREATE TABLE IF NOT EXISTS daily_activity (
  date_key TEXT PRIMARY KEY,
  steps INTEGER NOT NULL DEFAULT 0,
  cardio_minutes INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL DEFAULT 'manual',
  updated_at INTEGER NOT NULL
);
```

`date_key` 使用本地日期：

```text
YYYY-MM-DD
```

不要直接用 UTC 日期做天级聚合。

### 4.7 training_program

```sql
CREATE TABLE IF NOT EXISTS training_program (
  id TEXT PRIMARY KEY,
  version TEXT NOT NULL,
  name TEXT NOT NULL,
  goal_type TEXT NOT NULL,
  duration_weeks INTEGER NOT NULL,
  min_sessions INTEGER NOT NULL,
  max_sessions INTEGER NOT NULL,
  review_status TEXT NOT NULL,
  is_builtin INTEGER NOT NULL DEFAULT 1
);
```

首个内置计划：

```text
id: fat_loss_upper_priority_3_4
name: 减脂 · 上肢优先 · 3—4练
```

### 4.8 program_workout

```sql
CREATE TABLE IF NOT EXISTS program_workout (
  id TEXT PRIMARY KEY,
  program_id TEXT NOT NULL,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  focus_text TEXT NOT NULL,
  order_index INTEGER NOT NULL,
  optional INTEGER NOT NULL DEFAULT 0,
  estimated_minutes INTEGER NOT NULL,
  FOREIGN KEY(program_id) REFERENCES training_program(id) ON DELETE CASCADE
);
```

示例：

```text
push
pull_posterior
upper
optional_arms
```

### 4.9 program_workout_exercise

```sql
CREATE TABLE IF NOT EXISTS program_workout_exercise (
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
);
```

### 4.10 active_program_state

```sql
CREATE TABLE IF NOT EXISTS active_program_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  goal_id INTEGER NOT NULL,
  program_id TEXT NOT NULL,
  program_version TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  current_week INTEGER NOT NULL DEFAULT 1,
  next_required_workout_index INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(goal_id) REFERENCES fitness_goal(id),
  FOREIGN KEY(program_id) REFERENCES training_program(id)
);
```

`next_required_workout_index` 只推进必做训练。optional workout 不影响它。

## 5. 对现有训练表的 V2 扩展

### 5.1 workout_session 新增字段

建议迁移新增：

```sql
ALTER TABLE workout_session ADD COLUMN program_id TEXT;
ALTER TABLE workout_session ADD COLUMN program_workout_id TEXT;
ALTER TABLE workout_session ADD COLUMN program_version TEXT;
ALTER TABLE workout_session ADD COLUMN goal_id INTEGER;
```

SQLite/ArkData 迁移时应逐条检查列是否已存在，或采用项目可用的安全迁移方式。

`source_type` 扩展为：

```text
program
userPlan
adHoc
legacyRecommended
```

旧数据继续保留原值。

### 5.2 workout_exercise_record 新增字段

P1 为 Double Progression 增加：

```sql
ALTER TABLE workout_exercise_record ADD COLUMN suggested_weight_kg REAL;
```

建议重量是本次启动时的快照，不依赖之后算法变化。

## 6. 是否需要 daily_nutrition 表

P0 不建议增加物化汇总表。

每日热量/蛋白质直接由 `food_entry` 聚合：

```sql
SELECT
  SUM(calories),
  SUM(protein_g),
  SUM(carbs_g),
  SUM(fat_g)
FROM food_entry
WHERE recorded_at >= ? AND recorded_at < ?;
```

理由：

- MVP 数据量很小。
- 避免 food entry 与汇总表不同步。
- 后续性能真的出现问题再引入 cache/materialized summary。

## 7. Repository 边界

### ProfileRepository

负责：

- 用户基本信息。
- onboarding 状态。

### GoalRepository

负责：

- active goal。
- 目标修改。
- program state。

### BodyRepository

负责：

- 写入体重/腰围。
- 最近一次测量。
- 日期区间查询。

### NutritionRepository

负责：

- food entry CRUD。
- quick food CRUD。
- 某日营养汇总。

### ActivityRepository

负责：

- 步数写入与查询。
- 数据来源标记。

### ProgramRepository

负责：

- 内置 program catalog。
- 当前 program。
- program workout 模板读取。

### WorkoutRepository

继续负责：

- start workout。
- active session。
- complete set。
- rest。
- finish workout。
- history。

不要让 UI 直接执行 SQL。

## 8. Service 层建议

V2 开始增加 service 层，避免把计算逻辑塞进 `AppRoot`。

### DashboardService

聚合今日页所需 ViewModel：

- active goal
- latest weight
- weight trend
- nutrition summary
- steps
- today workout
- checklist

### TrendService

负责：

- 每日代表体重。
- 7 日平均。
- 周变化。
- 趋势状态。

### RecommendationService

P1/P2 负责：

- Double Progression。
- 蛋白质快捷建议。
- 未来热量/步数调整建议。

## 9. 7 日平均算法

### 9.1 每日代表体重

对于某个本地日期，当天存在多条 `weight_kg` 时：

- MVP：使用当天最后一条。

### 9.2 当前 7 日窗口

使用“今天及之前 6 个本地日期”。

只有至少 4 个有效体重日时才返回有效平均值。

### 9.3 上一个 7 日窗口

使用之前连续 7 个日期；同样至少需要 4 个有效日。

### 9.4 周变化百分比

```text
changeKg = currentAverage - previousAverage
changePercent = changeKg / previousAverage * 100
```

UI 可将减重显示为负值，例如 `-0.4 kg`。

## 10. 数据完整性规则

- 重量不得小于等于 0。
- 目标体重不得小于合理下限；UI 应做基本校验。
- 热量和蛋白质不得为负。
- reps 不得为负。
- steps 不得为负。
- active goal 最多一个。
- active workout 最多一个。
- draft user plan 最多一个。
- 删除快捷食物不得删除历史 food entry。
- 删除自定义计划不得删除历史 workout session。

## 11. 时间处理

所有数据库时间戳继续使用 Unix milliseconds。

天级统计必须通过本地时区边界计算：

```text
local day start
local next day start
```

不要用：

```text
timestamp / 86400000
```

直接作为用户本地日期，避免时区错误。

## 12. V2 初始化种子数据

第一次升级/新安装时插入：

1. 内置 training program。
2. program workouts。
3. program workout exercises。
4. built-in quick foods。

种子操作必须 `INSERT OR IGNORE` 或等价幂等实现。

## 13. V2 数据库验收

Agent 完成数据库阶段后必须验证：

- V1 数据库可以无损升级到 V2。
- 原训练历史仍能打开。
- active workout 若升级前存在，升级后仍能恢复。
- 新增目标可以保存并重启恢复。
- 体重可写入并读取 7 日范围。
- 快捷食物可添加为 food entry。
- program 模板可从数据库完整加载。
- 同时创建两个 active goal 会被阻止。
- 同时创建两个 active workout 会被阻止。

不得以“新装可用”替代迁移测试。