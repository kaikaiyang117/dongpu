# 动谱 V2 页面结构与交互状态

| 项目 | 内容 |
| --- | --- |
| 版本 | 2.0 |
| 更新日期 | 2026-09-03 |
| 目标 | 作为 ArkUI 页面、路由和状态实现基线 |

## 1. 总体原则

页面结构围绕“目标 → 今日执行 → 记录 → 趋势 → 调整”组织，不再围绕“动作库”组织。

一级导航固定为四个 Tab：

```text
今日
训练
数据
我的
```

训练中的沉浸式页面不显示底部 Tab。

## 2. 推荐目录结构

```text
features/
├── dashboard/
│   ├── DashboardPage.ets
│   ├── BodyQuickEntrySheet.ets
│   └── DashboardComponents.ets
├── onboarding/
│   ├── OnboardingGoalPage.ets
│   ├── OnboardingBodyPage.ets
│   ├── OnboardingTrainingPage.ets
│   ├── OnboardingNutritionPage.ets
│   └── OnboardingSummaryPage.ets
├── nutrition/
│   ├── NutritionPage.ets
│   ├── FoodEntryEditorPage.ets
│   ├── QuickFoodEditorPage.ets
│   └── NutritionComponents.ets
├── training/
│   ├── TrainingHomePage.ets
│   ├── WorkoutPreviewPage.ets
│   ├── WorkoutPage.ets
│   ├── RestPage.ets
│   ├── ExerciseAlternativePage.ets
│   ├── WorkoutCompletePage.ets
│   └── TrainingComponents.ets
├── progress/
│   ├── ProgressPage.ets
│   ├── WeightTrendPage.ets
│   ├── TrainingTrendPage.ets
│   ├── NutritionTrendPage.ets
│   └── WeeklyReviewPage.ets
├── profile/
│   ├── ProfilePage.ets
│   ├── GoalSettingsPage.ets
│   ├── TrainingPreferencePage.ets
│   └── AppSettingsPage.ets
├── exercise/
│   ├── ExerciseLibraryPage.ets
│   └── ExerciseDetailPage.ets
└── history/
    └── WorkoutHistoryDetailPage.ets
```

旧页面可以逐步迁移，不要求一次性改名，但最终职责应收敛到以上结构。

## 3. AppRoute 建议

```ts
export enum AppRoute {
  Loading,

  OnboardingGoal,
  OnboardingBody,
  OnboardingTraining,
  OnboardingNutrition,
  OnboardingSummary,

  Dashboard,
  TrainingHome,
  Progress,
  Profile,

  Nutrition,
  FoodEntryEditor,
  QuickFoodEditor,
  BodyQuickEntry,

  WorkoutPreview,
  Workout,
  Rest,
  ExerciseCompleted,
  ExerciseAlternative,
  WorkoutComplete,
  ExitWorkout,

  ExerciseLibrary,
  ExerciseDetail,
  WorkoutHistoryDetail,
  WeeklyReview,

  GoalSettings,
  TrainingPreference,
  AppSettings
}
```

如果现有 `AppRoute` 已有对应值，优先兼容迁移，不要机械重复。

## 4. 启动路由

```text
App Launch
  ↓
Loading
  ↓
读取数据库 / 执行迁移
  ↓
读取 user_profile.onboarding_completed
  ├─ false → OnboardingGoal
  └─ true  → Dashboard
```

注意：active workout 不应强制把整个 App 启动到 Workout 页面。

正确行为：

- 启动仍进入 Dashboard。
- Dashboard 的训练卡变为“训练进行中”。
- 点击“继续训练”后根据 session.phase 进入 Workout / Rest / ExerciseCompleted。

## 5. 四 Tab 布局

### 5.1 今日

Route：`Dashboard`

职责：

- 当前目标概览。
- 今日 Checklist。
- 今日营养进度。
- 今日训练。
- 今日活动。
- 快速记录晨重。

不承载：

- 动作搜索。
- 大型历史列表。
- 复杂设置。

### 5.2 训练

Route：`TrainingHome`

职责：

- 当前 Program。
- 本周训练完成情况。
- 必做/可选训练日。
- 自定义训练。
- 我的计划。
- 动作库入口。
- 最近训练历史入口。

### 5.3 数据

Route：`Progress`

职责：

- 体重趋势。
- 训练趋势。
- 营养趋势。
- 周复盘入口。

### 5.4 我的

Route：`Profile`

职责：

- 当前目标。
- 身体信息。
- 训练偏好。
- 提醒和单位。
- 隐私、版权和数据设置。

## 6. Dashboard 页面结构

建议从上到下：

```text
Header
GoalSummaryCard
TodayChecklistCard
NutritionSummaryCard
TodayWorkoutCard
ActivityCard
BottomNav
```

### 6.1 Header

展示：

```text
动谱
9月3日 周四
早上好 / 下午好 / 晚上好
减脂第 N 天
```

不强制昵称。

### 6.2 GoalSummaryCard

ViewModel：

```ts
class GoalSummaryViewModel {
  currentWeightKg: number | undefined;
  targetWeightKg: number;
  sevenDayChangeKg: number | undefined;
  trendStatus: string;
}
```

状态：

- 没有体重记录：显示“记录第一笔体重”。
- 数据不足：趋势显示“数据积累中”。
- 数据足够：显示 7 日变化。

### 6.3 TodayChecklistCard

建议 item model：

```ts
class ChecklistItemViewModel {
  id: string;
  title: string;
  valueText: string;
  progress: number | undefined;
  completed: boolean;
  action: string;
}
```

Checklist 是派生状态，不单独持久化“完成”。例如：

```text
bodyRecorded = 今天有 weight entry
proteinDone = protein >= target
stepsDone = steps >= target
workoutDone = 今天 required workout completed
```

### 6.4 NutritionSummaryCard

点击整个卡片或 `记录饮食` → `Nutrition`。

快捷蛋白粉建议可显示为二级按钮：

```text
+ 1勺乳清
```

只有存在对应启用快捷食物时展示。

### 6.5 TodayWorkoutCard

状态优先级：

```text
active workout
> required workout due
> optional workout available
> rest/recovery message
```

active workout：

```text
训练进行中
Push
已完成 3 / 6 个动作
[继续训练]
```

required workout：

```text
今日训练
Push
6 个动作 · 约55分钟
[开始训练]
```

### 6.6 ActivityCard

P0：

- 显示本地 daily_activity。
- 允许进入简单编辑。

P1：

- 接健康数据后 source 显示 `health`。

## 7. Onboarding 状态流

```text
OnboardingGoal
   ↓
OnboardingBody
   ↓
OnboardingTraining
   ↓
OnboardingNutrition
   ↓
OnboardingSummary
   ↓
创建 profile
创建 active goal
创建 active program state
标记 onboarding completed
   ↓
Dashboard
```

### 7.1 中途退出

P0 可使用内存草稿。

若实现本地草稿，必须支持：

- 继续填写。
- 清空重来。

不允许出现“部分 profile 已保存但 onboarding 未完成”导致首页不可用的半状态。

## 8. TrainingHome 页面结构

建议：

```text
Header
CurrentProgramCard
WeeklyTrainingProgress
RequiredWorkoutList
OptionalWorkoutCard
CustomTrainingSection
ExerciseLibraryEntry
RecentWorkoutEntry
BottomNav
```

### 8.1 当前 Program

展示：

- Program 名称。
- 当前第几周。
- 最低要求训练次数。
- optional session 不计最低完成度。

### 8.2 Workout item 状态

```text
completed
active
next
available
locked(optional if desired)
```

MVP 不需要复杂日历绑定；按完成顺序推进即可。

## 9. WorkoutPreview 页面

输入：

```ts
ProgramWorkout / UserWorkoutPlan
```

展示：

- 名称。
- focus。
- estimated minutes。
- 动作列表。
- sets / rep range / rest。

操作：

```text
开始第一个动作
返回
```

开始按钮必须先成功创建 `WorkoutSession` 后再进入 Workout。

## 10. Workout 页面

### 10.1 页面状态

页面 ViewModel 不自行维护最终真相，数据库 session 为事实源。

展示：

```text
workout progress
exercise metadata
set progress
last performance
suggested performance
current weight
current reps
```

### 10.2 完成一组

```text
用户点击完成本组
  ↓
校验 weight / reps
  ↓
WorkoutRepository.completeSet
  ↓
commit 成功
  ↓
如果还有组 → Rest
如果动作完成 → ExerciseCompleted 或下一个动作
```

数据库保存失败时不得先进入 Rest。

## 11. Rest 页面

显示：

- 刚完成的组。
- 剩余时间。
- 下一组。
- +30s。
- 跳过。
- 暂停（若现实现不支持，可 P1）。

`rest_end_at` 继续作为恢复依据。App 切后台/被杀后不得重置计时。

## 12. Nutrition 页面

结构：

```text
Header
DailyNutritionSummary
QuickFoodGrid
MealSections
AddFoodButton
```

### 12.1 QuickFoodGrid

点击快捷食物：

```text
选择 meal_type（可使用当前时段默认）
→ 直接新增 food_entry
→ summary 刷新
```

推荐时段映射：

```text
05:00—10:30 breakfast
10:30—14:30 lunch
14:30—17:30 snack
17:30—22:30 dinner
其他 snack
```

用户可修改。

### 12.2 FoodEntryEditor

字段：

- meal type。
- 食物名称。
- servings。
- calories。
- protein。
- carbs optional。
- fat optional。

不做搜索全量云食物数据库。

## 13. 快速体重记录

从 Dashboard 点击当前体重或晨重 Checklist：

```text
BodyQuickEntrySheet
```

字段：

```text
体重 kg
腰围 optional
```

主按钮：

```text
保存
```

保存后：

- Dashboard 立即刷新。
- TrendService 重新计算。
- 不弹“今天比昨天重了”。

## 14. Progress 页面

顶部 Segmented Control：

```text
体重
训练
营养
```

### 14.1 体重 Tab

```text
7日平均
与前7日比较
30天折线图
目标体重进度
最近腰围
```

图表若项目没有稳定 chart 组件，P0 可以先用自绘 Canvas/简化趋势或数据卡；不要为了图表依赖阻塞主闭环。

### 14.2 训练 Tab

```text
本周完成率
最近训练
关键动作趋势
```

### 14.3 营养 Tab

```text
本周平均热量
蛋白质达标天数
每日摄入列表/简单柱形图
```

## 15. WeeklyReview 页面

P1。

输入时间窗口：上一个完整自然周或用户当前计划周。

展示：

```text
体重变化
腰围变化
训练完成
蛋白质达标
平均步数
力量亮点
下周建议
```

规则结论必须可追溯到明确数据，不生成心理化评价。

## 16. Profile 页面

结构：

```text
CurrentGoalCard
GoalSettingsEntry
BodyInfoEntry
TrainingPreferenceEntry
ReminderEntry
UnitSettings
DataAndPrivacy
Attribution
```

修改 active goal 的每日热量/蛋白质/步数后，Dashboard 下一次刷新立即使用新值。

## 17. BottomNav 行为

BottomNav 不应直接持有业务状态。

```ts
onSelect(tab) {
  dashboard -> AppRoute.Dashboard
  training -> AppRoute.TrainingHome
  progress -> AppRoute.Progress
  profile -> AppRoute.Profile
}
```

如果 active workout 存在，用户仍可浏览四个 Tab；只有进入训练执行时隐藏 BottomNav。

## 18. AppRoot 重构目标

当前 `AppRoot` 已经承担过多业务状态。V2 不应继续把所有 state 加进去。

最终建议：

```text
AppRoot
├── current route
├── selected tab
├── dependency wiring
└── global lifecycle

feature pages
└── feature-specific state

services
└── cross-domain aggregation / calculations

repositories
└── persistence
```

P0 允许渐进迁移，但新增 Nutrition、Body、Trend 逻辑禁止直接堆到一个巨型 AppRoot 方法中。

## 19. UI 视觉原则

延续现有绿色品牌，但整体升级为偏 Apple 风格：

- 大面积浅背景。
- 大圆角卡片。
- 少量阴影，不使用厚重描边。
- 主色用于 CTA、状态和关键数字，不大面积铺绿色。
- 信息密度低于传统健身记录器。
- 一屏最多一个强主按钮。
- 数字优先对齐，单位弱化。
- 训练执行页避免复杂装饰。

继续复用 `AppTheme` token，不在各页面散落颜色 literal。

## 20. 页面验收主路径

### Flow A：新用户

```text
首次启动
→ Onboarding
→ 生成目标
→ Dashboard
→ 记录体重
→ 记录一勺乳清
→ 开始 Push
→ 完成一组
→ Rest
→ 退出 App
→ 重启
→ Dashboard 显示继续训练
→ 完成训练
→ 历史可见
```

### Flow B：减脂趋势

```text
连续录入 7+ 天体重
→ Dashboard 显示 7 日变化
→ Data/体重显示平均趋势
→ 不因单日反弹显示失败
```

### Flow C：营养

```text
Dashboard
→ 记录饮食
→ 快捷添加乳清
→ 返回 Dashboard
→ protein / calories 即时更新
```

以上 3 条 flow 是 V2 P0 的核心 UI 验收。