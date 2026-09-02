# 动谱现有实现参考（V1 兼容与迁移说明）

| 项目 | 内容 |
| --- | --- |
| 文档版本 | 1.0-legacy |
| 状态 | 现状参考，不再作为产品决策基线 |
| 更新日期 | 2026-09-03 |

> 本文档只用于帮助开发者理解当前已实现代码和 V1 数据语义。
> V2 开发请优先阅读：`PRODUCT_SPEC.md`、`DATABASE_DESIGN.md`、`PAGE_STRUCTURE.md`、`AGENT_IMPLEMENTATION_PLAN.md`。

## 1. 当前技术基线

- HarmonyOS NEXT 原生应用。
- ArkTS + ArkUI。
- ArkData 本地持久化。
- 首要真机：HUAWEI Mate 60 Pro。
- 核心流程不依赖登录、服务器或网络。
- 动作数据来自本地 vendor 数据集，并使用稳定动作 ID。

## 2. 当前工程结构

```text
harmony/entry/src/main/ets/
├── app/
│   ├── AppRoot.ets
│   ├── AppRoutes.ets
│   └── AppTheme.ets
├── components/
├── data/
│   ├── database/
│   └── repository/
├── domain/
├── features/
│   ├── onboarding/
│   ├── training/
│   ├── exercise/
│   ├── history/
│   ├── custom/
│   └── settings/
└── model/
```

V2 推荐的新目录边界见 `PAGE_STRUCTURE.md`。

## 3. 当前已实现能力

以下能力应优先复用，而不是重写：

- 动作目录与动作详情。
- 自定义训练计划。
- 推荐训练启动。
- `WorkoutSession`。
- `WorkoutExerciseRecord`。
- `SetRecord`。
- 完成一组后进入休息。
- `rest_end_at` 恢复倒计时。
- active workout 重启恢复。
- 动作替换。
- 训练完成页。
- 训练历史。

## 4. 当前 V1 数据库

当前数据库版本为 1，包含：

```text
app_settings
user_program_state
user_workout_plan
user_plan_exercise
workout_session
workout_exercise_record
set_record
```

这些表的原始语义如下。

### 4.1 app_settings

```text
weekly_frequency
onboarding_completed
weight_unit
```

V2 后 onboarding 状态迁移到 `user_profile`，但旧字段可暂保留兼容。

### 4.2 user_program_state

原逻辑主要服务 A/B 推荐训练：

```text
next_workout_code
weekly_completed
week_started_at
```

V2 新 Program 逻辑不应继续依赖 A/B，但迁移阶段可以保留旧状态用于历史兼容。

### 4.3 user_workout_plan / user_plan_exercise

继续作为用户自定义计划存储。

原则：

- 最多一个 draft。
- 删除 saved plan 不删除历史训练。

### 4.4 workout_session

现有核心字段：

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
```

V2 需要在不破坏旧字段的基础上扩展：

```text
program_id
program_workout_id
program_version
goal_id
```

### 4.5 workout_exercise_record

现有字段包括：

```text
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
```

这些快照字段必须保留，因为历史记录不能依赖动作目录未来版本。

### 4.6 set_record

```text
set_number
weight
reps
completed_at
```

V2 继续统一以公斤作为数据库重量单位。

## 5. AppRoot 当前职责过重

当前 `AppRoot.ets` 同时承担：

- route。
- settings。
- exercise catalog。
- current program。
- custom plan。
- active workout。
- history。
- onboarding。
- workout actions。

V2 不应继续把 Body、Nutrition、Trend、Goal 等状态直接加入 AppRoot。

迁移目标：

```text
AppRoot
→ route / tab / lifecycle / dependency wiring

Repository
→ persistence

Service
→ cross-domain aggregation and rules

Feature Page
→ feature-local UI state
```

## 6. 当前推荐训练逻辑

V1 使用 `recommendedWorkout('A' | 'B')` 生成固定 A/B 训练。

V2 中：

- 该能力视为 legacy。
- 新用户主流程使用数据库 `training_program`。
- 首个 V2 Program 是 3—4 练减脂上肢优先方案。
- 在 Program Engine 完成前，legacy A/B 可以保留用于迁移和回归测试。

不要立即删除 legacy 代码，先完成新 Program 路径和数据迁移，再清理。

## 7. 当前训练执行状态机

现有训练状态大体为：

```text
Workout
→ Rest
→ Workout / ExerciseCompleted
→ next exercise
→ WorkoutComplete
```

active session 由数据库恢复。

V2 必须保留这一核心机制。

### 7.1 完成组

正确顺序仍然是：

```text
validate input
→ persist set
→ update workout session
→ commit success
→ enter rest or next state
```

不得先切 UI 状态再异步保存。

### 7.2 Rest

`rest_end_at` 是事实源。

App 进入后台或被杀死后，恢复时应根据当前时间重新计算剩余时间，而不是重新开始 90 秒。

## 8. 当前动作目录

动作目录已经包含：

- stable exercise id。
- 中文名称。
- body part。
- equipment。
- gym eligibility。
- beginner recommendation。
- review status。
- image/media references。

V2 Program seed 必须引用真实稳定 ID。

Program 中所有首批动作必须满足：

```text
exists
contentReviewStatus == approved
gymEligible == true
```

若动作还要求新手友好，可继续验证 `recommendedForBeginner`。

## 9. 可保留的页面

以下页面或组件可继续演进：

- `WorkoutPreviewPage`
- `WorkoutPage`
- `RestPage`
- `ExerciseAlternativePage`
- `WorkoutCompletePage`
- `ExerciseLibraryPage`
- `ExerciseDetailPage`
- `WorkoutHistoryDetailPage`

以下需要明显重构或被替换：

- 旧 `OnboardingPage`
- 旧 `TrainingHomePage` 作为默认首页的定位
- 旧三 Tab `BottomNav`
- 只围绕 A/B 的推荐计划逻辑

## 10. V2 迁移红线

开发中禁止：

- 删除 V1 workout history。
- 重建数据库并要求用户清数据。
- 用 exercise 中文名称替换稳定 ID。
- 删除 snapshot 字段后依赖最新动作目录展示历史。
- 为了 V2 UI 重写已经稳定的训练持久化机制。
- 在 AppRoot 中直接加入大量 nutrition/body SQL。
- 未验证 restart 就修改 active workout 流程。

## 11. 构建与验证

从 `harmony/` 构建：

```bash
DEVECO_SDK_HOME="$PWD/.sdk" \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
assembleHap --mode module -p product=default -p module=entry@default \
-p buildMode=debug --no-daemon
```

涉及训练状态时重点验证：

```text
start workout
complete set
rest
kill app
restart
resume
finish
history
```

涉及数据库时重点验证：

```text
fresh install
V1 -> V2 migration
legacy history
active session recovery
```

## 12. V2 参考文档

产品与实现决策必须回到：

- `docs/PRODUCT_SPEC.md`
- `docs/DATABASE_DESIGN.md`
- `docs/PAGE_STRUCTURE.md`
- `docs/AGENT_IMPLEMENTATION_PLAN.md`

本文只负责解释“现在代码为什么长这样”和“哪些东西不能在重构时弄丢”。