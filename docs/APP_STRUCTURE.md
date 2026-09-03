# 动谱当前 App 结构

| 项目 | 内容 |
| --- | --- |
| 状态 | 当前实现说明 |
| 更新日期 | 2026-09-03 |
| 入口 | `harmony/entry/src/main/ets/app/AppRoot.ets` |

本文只描述当前代码真实结构，不描述历史计划。

## 1. 顶层目录

```text
harmony/entry/src/main/ets/
├── app/          AppRoot / AppRoutes / AppTheme
├── components/   公共 UI
├── data/         ExerciseCatalog / database / repository
├── domain/       goal / body / nutrition / activity / program / progress / workout
├── services/     Dashboard / Onboarding / WeeklyReview / Trend
├── features/     页面与 feature-local UI
└── model/        仍在使用的兼容模型
```

业务边界原则：

```text
Page / AppRoot
↓
Service
↓
Repository
↓
ArkData
```

SQL 不进入 UI。

统计、趋势和推荐逻辑优先放 Service。

## 2. 当前四个一级 Tab

```text
今日      AppRoute.Dashboard
训练      AppRoute.TrainingHome
数据      AppRoute.Progress
我的      AppRoute.Profile
```

底部导航由 `components/BottomNav.ets` 统一实现。

沉浸式训练流程和子页面不显示底部 Tab。

## 3. 当前 Routes

`AppRoutes.ets` 当前包含：

```text
Loading
Onboarding
V2Upgrade
Dashboard
Nutrition
FoodEntryEditor
Progress
WeeklyReview
Profile
TrainingHome
WorkoutPreview
Workout
Rest
ExerciseCompleted
WorkoutComplete
History
HistoryDetail
Settings
ExerciseAlternatives
CustomBody
CustomExercise
CustomConfirm
TrainingReady
ExerciseLibrary
ExerciseDetail
```

### 不再是 Route 的交互

当前实现已经将部分短操作改为 Sheet：

```text
身体快速记录 → Sheet
训练退出确认 → Sheet
训练动作要点 → Sheet
```

不要重新为这些场景增加独立 Route，除非交互复杂度明显增长。

## 4. 启动流程

当前启动主流程：

```text
App Launch
↓
Loading
↓
初始化 ArkData / migration / repair
↓
读取 settings / profile / active goal / active program / active workout
↓
检查 V2 readiness
├── 新用户 → Onboarding
├── V1 老用户且 V2 数据不完整 → V2Upgrade
└── ready → Dashboard
```

active workout 不强制把 App 启动到训练页面。

正确行为：

```text
启动进入 Dashboard
↓
Dashboard 显示“训练进行中”
↓
用户点击继续训练
↓
根据 session phase 恢复 Workout / Rest / ExerciseCompleted
```

## 5. 今日 Feature

主要文件：

```text
features/dashboard/DashboardPage.ets
services/DashboardService.ets
```

当前职责：

- active goal。
- 最近体重。
- 7 日体重/腰围趋势。
- 当日营养。
- 当日活动。
- active workout。
- 今日 Program workout。
- Checklist。

下一步必须把“Required / Optional / Recovery”统一决策抽到 Program/Today Plan Service，避免 Dashboard 自己根据 Program cursor 猜今天该练什么。

## 6. 训练 Feature

主要页面：

```text
TrainingHomePage
WorkoutPreviewPage
WorkoutPage
RestPage
ExerciseCompletedPage
WorkoutCompletePage
ExerciseAlternativePage
HistoryPage
WorkoutHistoryDetailPage
```

当前支持：

- Required / Optional Program 展示。
- 推荐训练。
- 自定义训练与已保存计划。
- 训练中逐组记录。
- Double Progression 建议。
- rest timer。
- 器械替换。
- active workout 恢复。
- 历史记录。

### 当前架构债务

`AppRoot` 仍直接负责较多 Program 业务：

```text
loadActiveProgram
Program V2 → UI model 转换
required workout 选择
preview workout 选择
```

做到可用版时不要求为了架构而全面重写，但在继续扩展多个 Program 之前应引入 `ProgramService` / `TodayPlanService`。

## 7. 营养 Feature

主要页面：

```text
NutritionPage
FoodEntryEditorPage
```

数据：

```text
quick_food
food_entry
```

当前主目标是快速记录热量和蛋白质，不做大型食物搜索平台。

下一阶段体验优化优先：

```text
最近食物
复制上一餐
更快添加常用蛋白质来源
```

## 8. 数据 Feature

主要页面：

```text
ProgressPage
WeeklyReviewPage
```

主要 Service：

```text
TrendService
WeeklyReviewService
```

统计口径必须使用真实记录日：

- 未记录步数不等于 0 步。
- 未记录饮食不等于摄入 0 kcal。
- Program 完成状态从 completed workout_session 推导。

## 9. 我的与设置

主要页面：

```text
ProfilePage
SettingsPage
BodyQuickEntryPage（作为 Sheet 内容）
```

Profile 是一级 Tab。

Settings 是子页面，并通过 `settingsReturnRoute` 返回调用来源。

身体记录是低摩擦 Sheet，不应强制用户进入设置页。

下一步建议把“今日步数”也改成快速 Sheet，而不是绕到 Settings。

## 10. 动作目录

当前用户层部位统一为：

```text
胸部
背部
肩部
手臂
腿部
核心
```

`ExerciseCatalog.ets` 负责把上游 upper/lower arms、upper/lower legs、waist 映射到用户层六类。

正式动作入口应继续遵守内容审核字段：

```text
contentReviewStatus
libraryVisible
gymEligible
recommendedForBeginner
```

Program 使用稳定 exercise ID，不使用中文名称做关联。

## 11. 当前关键 Services

```text
DashboardService
OnboardingService
WeeklyReviewService
TrendService
```

下一步最值得新增：

```text
ProgramService
TodayPlanService
UnitFormatter / UnitService
```

其中 Today Plan 必须成为 Dashboard 与 TrainingHome 的共同训练建议来源。

## 12. 当前状态真相原则

以下数据是事实：

```text
workout_session
workout_exercise_record
set_record
body_measurement
food_entry
daily_activity
```

以下数据是游标或缓存，不能反推历史事实：

```text
next_required_workout_index
legacy weekly_completed
页面本地 @State
```

页面只展示 Service 解释后的事实，不自己创造另一套业务语义。

## 13. 下一步

只看：

`docs/ROADMAP.md`

不要从 Git 历史中的旧 Phase 文档恢复已经完成的任务。