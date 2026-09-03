# 动谱数据库设计（Current Schema）

| 项目 | 内容 |
| --- | --- |
| 当前版本 | 3 |
| 数据库 | `dongpu.db` |
| 存储 | HarmonyOS ArkData / relationalStore |
| 原则 | 本地优先、迁移安全、历史快照稳定 |

## 1. 当前迁移链

当前代码中的 `DATABASE_VERSION = 3`。

正式迁移链：

```text
Fresh install
V1 schema
→ migrateV1ToV2
→ migrateV2ToV3
→ version 3

V1
→ V2
→ V3

V2
→ V3
```

禁止通过删除数据库、DROP 历史表或清空用户数据解决升级问题。

初始化代码还包含 repair 路径，用于兼容早期开发版本中 schema/version 不完全一致的数据库。后续修改数据库时仍应优先新增正式 migration，而不是只依赖 repair SQL。

## 2. 数据单位与时间约定

- 数据库中的重量统一存 **kg**。
- UI 可显示 kg/lb，但转换只发生在 UI/Formatter 边界。
- `recorded_at`、`started_at`、`completed_at` 等时间使用毫秒时间戳。
- `daily_activity.date_key` 使用本地日期键，例如 `2026-09-03`。

## 3. V1 兼容表

### app_settings

```text
id
weekly_frequency
onboarding_completed
weight_unit
```

`onboarding_completed` 为历史兼容字段。V2 readiness 不能只依赖该字段。

### user_program_state

```text
next_workout_code
weekly_completed
week_started_at
```

这是 legacy 状态。

V2 Dashboard、Weekly Review 和 Program 完成率不能把 `weekly_completed` 当作数据真相，应从 `workout_session` 推导。

### user_workout_plan / user_plan_exercise

继续支持用户自定义训练计划。

## 4. 用户与目标

### user_profile

核心字段：

```text
height_cm
sex optional
birth_year optional
onboarding_completed
created_at
updated_at
```

当前只允许一个 profile。

### fitness_goal

核心字段：

```text
goal_type
start_weight_kg
target_weight_kg
start_date
target_calories
target_protein_g
target_steps
training_frequency_min
training_frequency_max
training_location
dedicated_leg_day
prefer_machines
status
created_at
updated_at
```

状态：

```text
active
completed
archived
```

数据库通过 partial unique index 保证最多一个 active goal。

当前 V2 产品实际支持 3 次 Required + 可选第 4 次训练。业务层必须统一训练频率语义，不能让相同 UI 选择在不同入口写入不同 min/max 组合。

## 5. 身体数据

### body_measurement

```text
id
recorded_at
weight_kg optional
waist_cm optional
body_fat_percent optional
note optional
```

趋势计算使用每日代表值和窗口统计，不直接对单次体重波动下结论。

## 6. 营养

### quick_food

```text
name
serving_name
calories
protein_g
carbs_g optional
fat_g optional
is_builtin
is_enabled
created_at
updated_at
```

当前内置快捷食物包括乳清蛋白、鸡蛋、牛奶、鸡胸肉。

### food_entry

```text
recorded_at
meal_type
food_name
serving_name
servings
calories
protein_g
carbs_g optional
fat_g optional
quick_food_id optional
created_at
```

每日营养汇总从 `food_entry` 聚合，不单独维护容易失真的 daily total 表。

## 7. 活动

### daily_activity

```text
date_key PRIMARY KEY
steps
cardio_minutes
source
updated_at
```

当前主要支持 manual source。未来接系统健康数据时保留 source 区分。

没有活动记录不等于 0 步；周平均只对有记录日计算。

## 8. Program

### training_program

```text
id
version
name
goal_type
duration_weeks
min_sessions
max_sessions
review_status
is_builtin
```

当前内置 Program ID：

```text
fat_loss_upper_priority_3_4
```

### program_workout

当前 Program 包含：

```text
push            Required
pull_posterior  Required
upper           Required
optional_arms   Optional
```

字段包含：

```text
id
program_id
code
name
focus_text
order_index
optional
estimated_minutes
```

### program_workout_exercise

```text
id
workout_id
exercise_id
order_index
planned_sets
rep_min
rep_max
rest_seconds
weight_increment_kg
```

`id` 是 Program 中具体动作槽位的稳定身份，Double Progression 应优先使用该 slot identity，而不是只按 exercise ID 匹配历史。

### active_program_state

```text
id = 1
goal_id
program_id
program_version
started_at
current_week
next_required_workout_index
```

`next_required_workout_index` 只是 Program cursor，不是“本周是否完成”的事实来源。

自然周完成状态应由 completed `workout_session` 推导。

## 9. 训练事实表

### workout_session

核心字段包含：

```text
workout_code
workout_name_snapshot
source_type
status
phase
current_exercise_index
started_at
completed_at
rest_end_at
program_id optional
program_workout_id optional
program_version optional
goal_id optional
```

关键不变量：

- 同时最多一条 active workout。
- 完成 Program workout 与推进 Program cursor 必须保持一致。
- finish 操作必须幂等，completed session 不得重复推进 Program。

### workout_exercise_record

核心字段包含：

```text
session_id
original_exercise_id
actual_exercise_id
exercise_name_snapshot
part_name_snapshot
equipment_name_snapshot
image_path_snapshot
order_index
target_sets
rep_min
rep_max
rest_seconds
completed_sets
suggested_weight_kg optional
program_workout_exercise_id optional
weight_increment_kg
```

Program 规则必须 snapshot 到 session，避免后续 Program 更新改变历史训练含义。

### set_record

```text
exercise_record_id
set_number
weight
reps
completed_at
```

数据库重量始终为 kg。

做到可用版前，自重动作必须允许合法保存：

```text
weight = 0
reps > 0
```

## 10. 周统计的数据真相

以下指标均从历史事实查询：

```text
totalWorkoutsThisWeek
requiredProgramWorkoutsThisWeek
optionalProgramWorkoutsThisWeek
nutritionLoggedDays
activityLoggedDays
proteinTargetDays
```

禁止从：

```text
next_required_workout_index
weekly_completed
页面本地状态
```

推导历史完成事实。

## 11. 下一次数据库修改规则

任何 schema 变化必须：

1. 增加数据库版本号。
2. 新增独立 migration，例如 `migrateV3ToV4`。
3. Fresh install 能直接创建最新可用结构。
4. 旧版本能顺序升级到最新。
5. 不修改历史 `set_record` 的重量/次数事实。
6. migration 失败不得静默清空数据库。
7. 至少验证 Fresh、V1→Latest、V2→Latest、Current restart 四条路径。

当前数据库相关待办见 `docs/ROADMAP.md`。