# 动谱 V2 Agent 开发任务拆解

| 项目 | 内容 |
| --- | --- |
| 版本 | 2.0 |
| 更新日期 | 2026-09-03 |
| 目标执行者 | Codex / Claude Code / 其他代码 Agent |
| 目标 | 在不破坏 V1 训练历史的前提下，将产品升级为目标驱动的减脂 + 力量训练执行助手 |

## 1. Agent 开工前必读

按顺序阅读：

1. `AGENTS.md`
2. `docs/PRODUCT_SPEC.md`
3. `docs/DATABASE_DESIGN.md`
4. `docs/PAGE_STRUCTURE.md`
5. `docs/IMPLEMENTATION_REFERENCE.md`
6. 当前 `harmony/` 源码

如果文档冲突，以前四项为准。

禁止根据旧 `PRODUCT_SPEC` 记忆继续实现 A/B 新手产品。

## 2. 总体实施策略

原则：**先重构数据和边界，再换产品壳，再扩业务，不要先堆 UI。**

推荐顺序：

```text
Phase 0  基线确认
Phase 1  数据库 V2 与 Repository
Phase 2  Domain / Service 拆分
Phase 3  Onboarding 与 Goal
Phase 4  Dashboard
Phase 5  Nutrition
Phase 6  Program Engine
Phase 7  训练执行适配
Phase 8  Progress / 7日趋势
Phase 9  Profile / Settings
Phase 10 P1 渐进与周复盘
```

每个 Phase 完成后都必须保持工程可构建。

## 3. Phase 0：确认当前基线

### 任务

- 阅读当前目录结构。
- 确认 `AppDatabase.ets` 当前 version。
- 确认现有 tables。
- 确认 active workout 恢复逻辑。
- 确认 `AppRoute` / `BottomNav`。
- 确认现有动作 catalog stable ID。
- 运行一次当前 HAP build。

### 不允许修改

此阶段不做产品功能修改。

### 验收

输出一份短开发记录，至少明确：

```text
current database version
current routes
current repositories
active workout recovery path
current program model
build result
```

若 build 本身已经失败，先修复基线问题再进入 Phase 1。

## 4. Phase 1：数据库 V2

### 目标

完成 V1 → V2 的可升级数据库，不改变现有训练历史语义。

### 任务 1.1 AppDatabase migration framework

修改：

```text
harmony/entry/src/main/ets/data/database/AppDatabase.ets
```

要求：

- `DATABASE_VERSION = 2`。
- 拆分 `createSchemaV1` 和 `migrateV1ToV2`。
- migration 幂等。
- upgrade 成功后才更新 version。

### 任务 1.2 新表

按 `DATABASE_DESIGN.md` 实现：

- `user_profile`
- `fitness_goal`
- `body_measurement`
- `quick_food`
- `food_entry`
- `daily_activity`
- `training_program`
- `program_workout`
- `program_workout_exercise`
- `active_program_state`

### 任务 1.3 扩展 workout_session

安全新增：

- program_id
- program_workout_id
- program_version
- goal_id

### 任务 1.4 seed

初始化：

- 内置快捷食物。
- 首个减脂 Program。
- Program workouts。
- Program exercises。

所有 exercise ID 必须存在于当前审核动作目录中。

如果找不到完全对应动作：

- 先使用语义最接近且 `approved + gymEligible` 的动作。
- 在代码注释/开发记录中明确替代。
- 不得凭空构造不存在的 ID。

### 任务 1.5 Repository

新增：

```text
ProfileRepository.ets
GoalRepository.ets
BodyRepository.ets
NutritionRepository.ets
ActivityRepository.ets
ProgramRepository.ets
```

### Phase 1 验收

必须验证：

- fresh install 可建 V2。
- V1 数据库可迁移。
- 原 workout history 不丢。
- active workout 可恢复。
- active goal uniqueness 生效。
- quick foods seeded。
- program seeded。

## 5. Phase 2：Domain 与 Service

### 目标

避免继续把所有逻辑塞到 `AppRoot.ets`。

### 任务 2.1 Domain models

建议新增：

```text
domain/profile/ProfileModels.ets
domain/goal/GoalModels.ets
domain/nutrition/NutritionModels.ets
domain/activity/ActivityModels.ets
domain/progress/ProgressModels.ets
domain/program/ProgramV2Models.ets
```

若现有 `ProgramModels.ets` 易于兼容，可直接演进，不要求重复文件。

### 任务 2.2 TrendService

新增：

```text
services/TrendService.ets
```

实现：

- daily representative weight。
- current 7-day average。
- previous 7-day average。
- changeKg / changePercent。
- status。

### 任务 2.3 DashboardService

新增：

```text
services/DashboardService.ets
```

输出一个聚合 ViewModel，至少包含：

```text
goal summary
body summary
nutrition summary
activity summary
today workout
checklist
active workout state
```

### 任务 2.4 AppRoot 瘦身第一步

不要一次重写全文件。

先将新增 V2 查询逻辑移入 service/repository，`AppRoot` 只负责：

- 初始化依赖。
- route。
- tab。
- 全局 active session 跳转。

### Phase 2 验收

- TrendService 有纯逻辑可测试函数，或至少可通过固定输入手动验证。
- AppRoot 不包含 body/nutrition SQL 或趋势计算。
- 工程 build 通过。

## 6. Phase 3：新版 Onboarding

### 目标

替换仅选择 2/3 次训练频率的旧 onboarding。

### 页面

按 `PAGE_STRUCTURE.md` 实现：

```text
OnboardingGoal
OnboardingBody
OnboardingTraining
OnboardingNutrition
OnboardingSummary
```

### 状态

使用一个 onboarding draft model：

```ts
class OnboardingDraft {
  goalType: string;
  heightCm: number;
  currentWeightKg: number;
  targetWeightKg: number;
  waistCm?: number;
  frequencyMin: number;
  frequencyMax: number;
  trainingLocation: string;
  dedicatedLegDay: boolean;
  preferMachines: boolean;
  nutritionMode: string;
}
```

### 目标生成

P0 不需要复杂 TDEE 精确算法。

允许使用可解释的默认计算/配置，但必须：

- 不把测试用户 2100 kcal 硬编码给所有人。
- 将最终目标保存到 active `fitness_goal`。
- summary 页可在用户确认前展示。

如果尚未实现可靠个性化热量公式，可采用：

```text
通过体重区间 + 活动水平得到初始建议
并明确该值是“初始目标，可后续调整”
```

### Phase 3 验收

fresh install：

```text
launch
→ onboarding
→ complete
→ restart
→ directly dashboard
```

数据库中：

- profile 存在。
- active goal 存在。
- initial body measurement 存在。
- active program state 存在。

## 7. Phase 4：Dashboard

### 目标

建立新版产品主屏。

### 页面

新增/重构：

```text
features/dashboard/DashboardPage.ets
```

### 组件

建议拆分：

```text
GoalSummaryCard
TodayChecklistCard
NutritionSummaryCard
TodayWorkoutCard
ActivityCard
```

### 交互

- 点击体重 → quick body entry。
- 点击营养 → Nutrition。
- 点击训练 → preview 或 active workout。
- 点击步数 → activity edit/P1 health detail。

### BottomNav

改为：

```text
今日 / 训练 / 数据 / 我的
```

移除动作一级 Tab。

### Phase 4 验收

Dashboard 必须覆盖三种状态：

1. 新用户刚完成 onboarding，没有足够趋势数据。
2. 普通日，无 active workout。
3. active workout 存在。

## 8. Phase 5：Nutrition

### 目标

完成最小“热量 + 蛋白质”闭环。

### 页面

```text
NutritionPage
FoodEntryEditorPage
QuickFoodEditorPage(P1 可延后)
```

### 核心动作

#### Quick Add

点击 `1 勺乳清蛋白`：

```text
insert food_entry
→ aggregate daily nutrition
→ UI refresh
```

#### Manual Add

字段：

```text
meal
name
servings
calories
protein
carbs optional
fat optional
```

### Dashboard integration

Nutrition 保存后返回 Dashboard：

- calories 更新。
- protein 更新。
- checklist 更新。
- 蛋白质建议更新。

### Phase 5 验收

从 Dashboard 到记录一勺蛋白粉并返回，不超过 3 次主要点击。

重启后记录仍存在。

## 9. Phase 6：Program Engine

### 目标

从固定 A/B 升级到 3—4 日 Program。

### 任务

- ProgramRepository 加载 active program。
- TrainingHome 显示 program workouts。
- required session 按顺序推进。
- optional session 不推进 required index。
- workout preview 使用 DB program exercise。

### 兼容

旧 `recommendedWorkout(A/B)` 在迁移期间可以保留，但：

- 新用户不得再依赖它作为主推荐。
- 最终标记 legacy。

### Phase 6 验收

参考 program：

```text
Push
Pull + 后链
Upper
Optional
```

可以正确显示和启动。

完成 optional 后，下一必做训练仍保持正确。

## 10. Phase 7：训练执行适配

### 目标

复用现有 WorkoutSession / Rest / History，而不是重写训练引擎。

### 必须保留

- 一次一个动作。
- 一组一次保存。
- rest_end_at。
- active session 恢复。
- exercise alternatives。
- history snapshots。

### 新增展示

- `last performance`。
- P1 前可以先不提供复杂 suggestedWeight。

### App restart 验收

测试：

```text
开始 Push
→ 完成 2 组
→ 进入 rest
→ 强杀 App
→ 重启
→ Dashboard 显示继续训练
→ 进入后 rest/session 状态正确
```

这是阻断级验收；失败不得进入下一 Phase。

## 11. Phase 8：Progress

### 目标

让减脂结果以趋势呈现。

### 任务 8.1 Body quick entry

支持：

- weight required。
- waist optional。

### 任务 8.2 7-day trend

UI 状态：

- insufficient data。
- normal。
- slow。
- fast。

### 任务 8.3 Progress page

至少：

```text
体重 Tab
训练 Tab
营养 Tab
```

P0 如果图表实现成本高：

- 先做高质量数值卡 + 简化趋势。
- 不允许因图表库阻塞发版。

### Phase 8 验收

固定模拟数据：

```text
week 1 avg = 82.0
week 2 avg = 81.6
```

UI 应得到约 `-0.4 kg`，而不是取“今天 - 昨天”。

## 12. Phase 9：Profile 与 Settings

### 页面

```text
ProfilePage
GoalSettingsPage
TrainingPreferencePage
AppSettingsPage
```

### 要求

修改：

```text
target calories
protein
steps
training preference
weight unit
```

保存后 Dashboard 即时使用新值。

改变训练频率不应破坏已经完成的历史 workout。

## 13. Phase 10：P1

P0 完整稳定后再实现。

### 13.1 Double Progression

规则：

```text
if all completed work sets reps >= repMax:
  suggestedWeight = previousWeight + increment
else:
  suggestedWeight = previousWeight
```

需要处理：

- 没有历史数据。
- 上次替换动作。
- 不完整场次。
- bodyweight 动作。

### 13.2 Waist trend

每 1—2 周记录，不做每日任务强制。

### 13.3 Weekly Review

实现：

- body summary。
- nutrition adherence。
- training adherence。
- activity summary。
- strength highlights。

### 13.4 健康步数接入

只有在 HarmonyOS 权限、SDK 和数据稳定验证后接入。

保留 manual fallback。

## 14. P2 明确后置

不得提前实现：

- 自动降低热量。
- 自动提高步数。
- AI Coach。
- 云同步。

除非 P0/P1 已全部通过验收并有单独任务。

## 15. 代码组织规则

### UI

UI 组件只关心：

```text
props/state
render
event callbacks
```

不要：

- 直接 SQL。
- 写趋势算法。
- 写跨领域推荐规则。

### Repository

负责 persistence，不生成 UI 文案。

### Service

负责跨表聚合、趋势和 recommendation rule。

### Domain

保存稳定业务模型，不依赖 ArkUI。

## 16. 错误与空状态

每个页面至少处理：

- loading。
- empty。
- database error。
- partial data。

禁止 `catch (_) {}` 后静默显示错误数据。

可以：

- 记录 operation error。
- 显示可恢复提示。
- 保持已有数据。

## 17. 视觉实现约束

设计方向：偏 Apple 的现代简洁风格，但继续保持动谱绿色品牌。

要求：

- 使用 `AppTheme` token。
- 扩展 token，而不是页面写大量 `#xxxxxx`。
- 卡片圆角统一。
- spacing 使用有限集合。
- CTA 高度和圆角统一。
- BottomNav 图标/文字状态统一。
- 页面不要重复展示同一个指标 3 次以上。

UI 重构优先保证：

```text
信息层级
可读性
一屏一个主动作
状态一致性
```

而不是动画数量。

## 18. 每次提交的最小质量门槛

每个 Agent commit / PR 至少：

1. 只覆盖一个明确 Phase 或子任务。
2. ArkTS 类型检查通过。
3. HAP build 通过。
4. 不提交 build outputs / signing material。
5. 如果改数据库，做 migration 验证。
6. 如果改 workout persistence，验证 restart。
7. 如果改页面，附 emulator screenshot 或至少说明实际验证页面。

## 19. 构建命令

从 `harmony/`：

```bash
DEVECO_SDK_HOME="$PWD/.sdk" \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
assembleHap --mode module -p product=default -p module=entry@default \
-p buildMode=debug --no-daemon
```

若本地 DevEco 路径不同，根据开发机调整，不要提交个人绝对路径配置。

## 20. Agent 工作记录格式

每完成一个 Phase，在回复/PR 描述中使用：

```text
完成：
- ...

主要文件：
- ...

数据迁移：
- ...

验证：
- build ...
- flow ...

尚未实现：
- ...

下一步：
- ...
```

不要用“基本完成”“大概可用”替代具体说明。

## 21. P0 Definition of Done

只有以下全部满足，才能认为 V2 P0 完成：

- 新 Onboarding 完成。
- active goal 落库。
- Dashboard 成为默认首页。
- 四 Tab 导航生效。
- 体重可记录。
- 7 日平均可计算。
- calories / protein 可记录。
- 快捷蛋白粉可一键记录。
- 3—4 日 Program 生效。
- 训练预览生效。
- 现有训练执行可用于 Program。
- active workout restart 恢复正常。
- workout history 保留。
- V1 → V2 migration 不丢数据。
- 全部核心流程离线可用。
- HAP build 通过。

## 22. 推荐第一批实际开发提交

为了减少大改风险，建议 Agent 严格从下面开始：

```text
Commit 1
refactor: add versioned database migration framework

Commit 2
feat: add v2 profile goal body and nutrition repositories

Commit 3
feat: seed fat loss program and quick foods

Commit 4
refactor: add dashboard and trend services

Commit 5
feat: replace onboarding with goal setup flow

Commit 6
feat: add goal-driven dashboard

Commit 7
feat: add lightweight nutrition logging

Commit 8
feat: migrate recommended training to program engine

Commit 9
feat: add progress trend screen

Commit 10
feat: add profile and goal settings
```

不要在 Commit 1 同时重做整个 UI。