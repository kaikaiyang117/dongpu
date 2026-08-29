# 动谱 HarmonyOS APP UI 落地执行文档（Agent 执行版）

> 文档用途：指导 Coding Agent / UI Agent 在现有 `dongpu` 仓库上持续开发，把当前 HarmonyOS 原型推进为与已确认效果图一致的、可完成真实训练闭环的 MVP。
>
> 目标平台：HarmonyOS NEXT / HarmonyOS 6.0.1 / API 21  
> 技术栈：ArkTS + ArkUI + ArkData  
> 首要设备：HUAWEI Mate 60 Pro  
> 产品原则：本地优先、无登录也可使用、面向第一次进入健身房进行力量训练的成年人。

---

## 0. Agent 执行总原则

Agent 在开始任何代码修改前，必须先理解以下优先级：

1. **先完成训练主闭环，再扩动作库。**
2. **先拆架构，再继续向 `Index.ets` 塞功能。**
3. **训练状态和本地持久化优先于视觉微调。**
4. **推荐训练是主入口，自定义训练是次入口。**
5. **一次只给用户一个明确下一步。**
6. **任何页面必须考虑异常退出、后台、锁屏和恢复。**
7. **动作内容与媒体属于可替换资源层，业务流程不得依赖某一个媒体文件才能继续。**
8. **未经审核的动作内容不能进入正式推荐训练。**
9. **不要增加账号、服务器、社区、饮食、排行榜、RPE、1RM、训练容量等 MVP 外功能。**
10. **所有代码改动必须保持项目可编译、可安装、可运行。**

如果一个任务同时包含“继续增加动作展示”和“训练闭环”，优先做训练闭环。

---

# 1. 当前仓库状态判断

当前 HarmonyOS 原生工程已经具备：

- 完整动作目录导入；
- 1324 个动作基础数据；
- 图片与视频资源；
- 动作库筛选；
- 动作详情；
- 视频播放/暂停/慢动作；
- 自定义训练：选择部位、选择动作、修改组数与次数、确认训练；
- ArkTS / HAP 构建可通过。

当前主要问题：

- `harmony/entry/src/main/ets/pages/Index.ets` 已成为大型单页原型；
- 页面导航主要通过 `@State` 和条件渲染模拟；
- 领域模型非常薄；
- 尚未真正接入训练执行状态；
- 尚未完成 ArkData 持久化；
- 尚未完成历史记录；
- 尚未完成异常退出恢复；
- 尚未完成 A/B 推荐训练；
- 动作库实现进度已经超前于核心训练产品闭环。

因此下一阶段不是“继续做更多 UI”，而是：

> **把现有效果图作为视觉基线，把训练执行引擎、本地数据库和页面架构补齐。**

---

# 2. MVP 最终用户闭环

Agent 必须围绕下面这一条路径开发：

```text
首次启动
  ↓
选择每周训练 2 / 3 次
  ↓
训练首页
  ↓
今天训练 A / B
  ↓
训练预览
  ↓
开始第一个动作
  ↓
完成一组
  ↓
休息倒计时
  ↓
下一组 / 下一个动作
  ↓
训练完成
  ↓
记录页出现历史
  ↓
下一次训练读取上次重量与次数
```

必须支持训练过程中锁屏、退到后台、返回首页、应用被系统回收以及应用重新启动。

重新进入 APP 后：

```text
首页优先显示“训练进行中”
点击“继续训练”
恢复到正确动作、正确组数、正确重量/次数与正确休息剩余时间
```

这条能力是 MVP 的核心 Definition of Done。

---

# 3. 信息架构

底部只保留三个主 Tab：

```text
训练
动作
记录
```

设置通过“训练”首页右上角进入。

最终页面结构建议：

```text
ets/
├── app/
│   ├── AppRoot.ets
│   ├── AppRoutes.ets
│   └── AppTheme.ets
│
├── features/
│   ├── onboarding/
│   │   └── OnboardingPage.ets
│   ├── training/
│   │   ├── TrainingHomePage.ets
│   │   ├── WorkoutPreviewPage.ets
│   │   ├── WorkoutPage.ets
│   │   ├── RestPage.ets
│   │   ├── ExerciseCompletedPage.ets
│   │   └── WorkoutCompletePage.ets
│   ├── custom/
│   │   ├── BodyPartSelectPage.ets
│   │   ├── ExerciseSelectPage.ets
│   │   ├── PlanConfirmPage.ets
│   │   └── SavePlanSheet.ets
│   ├── exercise/
│   │   ├── ExerciseLibraryPage.ets
│   │   ├── ExerciseDetailPage.ets
│   │   ├── ExerciseTipsSheet.ets
│   │   └── ExerciseAlternativeSheet.ets
│   ├── history/
│   │   ├── HistoryPage.ets
│   │   └── WorkoutHistoryDetailPage.ets
│   └── settings/
│       └── SettingsPage.ets
│
├── components/
│   ├── AppHeader.ets
│   ├── PrimaryButton.ets
│   ├── SecondaryButton.ets
│   ├── AppCard.ets
│   ├── MetricCard.ets
│   ├── ExerciseMedia.ets
│   ├── NumberStepper.ets
│   ├── WeeklyProgress.ets
│   └── BottomNav.ets
│
├── domain/
│   ├── exercise/
│   ├── program/
│   ├── workout/
│   ├── plan/
│   └── settings/
│
├── data/
│   ├── catalog/
│   ├── database/
│   ├── repository/
│   └── seed/
│
└── model/
```

不要机械照搬目录名；允许结合 ArkUI 工程约束调整，但必须达到：

- 页面与领域逻辑分离；
- 静态动作数据与用户训练数据分离；
- 可复用组件不继续堆在单个 Page；
- `Index.ets` 最终只负责应用根入口或被移除。

---

# 4. 视觉系统

## 4.1 色彩

统一定义，不允许页面自行散落颜色常量。

```text
Background        #FBFAF5
Surface           #FFFFFF
SecondarySurface  #F4F5EF
PrimaryGreen      #65BF2F
DarkGreen         #3F8D19
SoftGreen         #EDF8E7
TextPrimary       #11120F
TextSecondary     #777970
Border            #E5E6DC
Warning           #D96D00
Danger            用于“放弃训练”等危险操作
```

要求：

- 页面背景使用温暖浅米白；
- 主 CTA 使用绿色；
- 卡片以白色为主；
- 仅训练进行中 Hero 卡片允许使用大面积绿色；
- 不做黑底、荧光绿、赛博 HUD、硬核 bodybuilding 风格。

## 4.2 尺寸规范

```text
页面左右 Margin     18–20 vp
主按钮高度          56–58 vp
主按钮圆角          16–18 vp
普通卡片圆角        16–20 vp
最小点击区域        >= 44 vp
页面主标题          28–32 fp
动作名称            24–28 fp
模块标题            16–18 fp
正文                13–15 fp
辅助文字            11–12 fp
```

大数字需要更强层级：重量、次数、休息倒计时、周训练完成数。

## 4.3 风格关键词

```text
干净
轻松
年轻
友好
有力量感但不竞技
新手可理解
信息密度低
```

---

# 5. 页面详细执行规格

## 5.1 首次使用页 OnboardingPage

### 页面目标

让完全不了解训练计划的用户在 1 分钟内完成初始化。

### 内容

```text
动谱

第一次健身，
不用先研究计划

动谱帮你安排好，从第一步开始就很简单。

每周准备练几次？

[ 2 次 ]  [ 3 次 ]

推荐每周 2 次
无伤病限制的成年人适用

[ 开始使用 ]
```

默认选中 2 次。

### 禁止

首次使用不要请求姓名、手机号、登录、身高、体重、体脂、饮食目标、复杂目标设置。

### 数据写入

点击“开始使用”：

```text
AppSettings.weeklyFrequency = 2 / 3
onboardingCompleted = true
```

保存到本地。

---

## 5.2 训练首页 TrainingHomePage

这是最重要的产品首页。

### 状态 1：普通状态

```text
动谱                    [设置]
今天练了么？

本周训练进度
已完成 1 / 2 次

今天的训练
A · 全身训练
5 个动作 · 约 40 分钟
腿举 · 坐姿推胸 · 高位下拉 · …

[ 开始今天训练 ]

自定义训练

我的计划
胸 + 肩
5 个动作 · 约 35 分钟
```

### 状态 2：存在 active WorkoutSession

首页顶部主卡替换为：

```text
训练进行中
A · 全身训练
已完成 2 / 5 个动作
已训练 21 分钟

[ 继续训练 ]
```

此状态不显示“开始今天训练”，不允许启动第二场训练，“继续训练”是最高优先级 CTA。

### 状态 3：本周已经完成目标

```text
本周已经完成 2 / 2 次

下次训练
B · 全身训练

[ 仍然开始训练 ]
```

不阻止用户额外训练。

---

## 5.3 今日训练预览 WorkoutPreviewPage

页面目的：让用户开始前知道要做什么、大概多久。

```text
<            今日训练

A · 全身训练

约 40 分钟
5 个动作 · 15 组

01 腿举
   3 组 · 8–12 次

02 坐姿推胸
   3 组 · 8–12 次

03 高位下拉
   3 组 · 8–12 次

04 腿弯举
   3 组 · 10–12 次

05 坐姿划船
   3 组 · 8–12 次

[ 开始第一个动作 ]
```

推荐计划预览页不要允许编辑推荐计划、重排动作、改训练结构。

---

## 5.4 训练中 WorkoutPage

这是全 APP 核心页面。

### 顶部

```text
X            训练中               2 / 5
训练总进度 ProgressBar
```

### 当前动作

```text
坐姿推胸
胸部 · 推胸机
[动作媒体]

第 2 组 · 共 3 组
目标 8–12 次
```

如果存在历史：

```text
上一次
30 kg × 10
```

如果第一次：

```text
第一次做这个动作
从轻重量开始，能稳定完成 8–12 次即可。
```

### 重量输入

```text
重量
[ - ]       30.0 kg       [ + ]
```

点击数字允许数字输入。MVP 加减步长 2.5 kg。第一次训练显示“选择重量”，不要显示 `0 kg` 作为默认视觉值。

### 次数

```text
次数
[ - ]         10          [ + ]
```

步长 1。

### 主按钮

```text
完成本组
```

点击后的业务：

```text
validate
↓
保存当前 SetRecord
↓
更新 WorkoutExerciseRecord 进度
↓
保存数据库事务
↓
如果还有下一组 -> Rest
如果当前动作完成 -> ExerciseCompleted
如果最后动作完成 -> WorkoutComplete
```

### 次级操作

```text
动作要点
器械被占用
```

---

# 6. 动作要点 Sheet

点击“动作要点”使用 Bottom Sheet，不离开训练状态。

```text
坐姿推胸

怎么做
1 调整座椅，让把手接近胸部高度
2 肩胛稳定，向前推
3 缓慢回到起始位置

注意什么
• 不要耸肩
• 不要突然锁死手肘

[ 知道了 ]
```

要求：Sheet 关闭后仍在原来的组，不重建 WorkoutSession，不重置输入。

---

# 7. 休息页 RestPage

视觉安静，信息极少。

```text
休息

01:24
组间休息

坐姿推胸 · 第 3 组
上一组 30 kg × 10

[-30 秒]    [+30 秒]

[ 跳过休息 ]

查看动作要点
```

### 关键数据设计

不要只保存：

```text
remainingSeconds = 84
```

必须保存：

```text
restEndAt
```

恢复逻辑：

```text
remainingSeconds = max(0, restEndAt - now)
```

倒计时结束：轻振动、短提示，并显示：

```text
休息结束
准备好开始第 3 组
[ 开始 ]
```

---

# 8. 动作完成过渡页 ExerciseCompletedPage

当最后一组完成：

```text
✓

坐姿推胸完成
3 / 3 组

接下来
高位下拉
背部 · 高位下拉机

[ 开始下一个动作 ]

动作要点
```

页面不需要倒计时，这是用户移动到下一台器械的过渡状态。

---

# 9. 器械被占用 ExerciseAlternativeSheet

点击“器械被占用”打开 Bottom Sheet。

```text
器械被占用了？
试试用下面动作替代，继续训练吧

器械夹胸
胸部 · 蝴蝶机
[ 换成这个动作 ]

哑铃卧推
胸部 · 哑铃
[ 换成这个动作 ]

稍后再做这个动作
取消
```

最多显示 2 个审核后的替换动作。

替换逻辑：

```text
WorkoutExerciseRecord.originalExerciseId 不变
WorkoutExerciseRecord.actualExerciseId 更新
exerciseNameSnapshot 更新
```

只影响本次训练。

“稍后再做”：调整当前 session 内 `orderIndex`，不修改原 Program，不修改 UserPlan。

---

# 10. 退出训练流程

WorkoutPage 左上角 `X` 点击后：

```text
暂时离开训练？

训练会自动保存，
下次打开可以继续。

[ 返回首页 ]
[ 继续训练 ]

放弃本次训练
```

“放弃本次训练”使用危险色，再次点击必须二次确认。

放弃后不进入历史、不计入本周完成。

---

# 11. 训练完成 WorkoutCompletePage

```text
✓

今天完成了
A · 全身训练

41 分钟
5 动作
15 组

今天有进步
坐姿推胸 27.5 kg → 30 kg
高位下拉 10 次 → 12 次

本周
已完成 2 / 2 次

[ 完成并返回 ]
```

完成训练必须使用完整事务：

```text
WorkoutSession.status = completed
completedAt = now

如果 recommended:
  A -> nextWorkoutCode = B
  B -> nextWorkoutCode = A
```

只有事务成功后才能进入完成页最终状态。

---

# 12. 自定义训练流程

## 12.1 第一步：选择部位

```text
<           自定义训练

第 1 / 3 步

今天想练哪里？
先选训练部位，接下来只显示相关动作

胸   背
肩   手臂
腿   核心

[ 下一步 · 选择动作 ]
```

用户层分类固定为胸、背、肩、手臂、腿、核心。不要直接暴露 dataset 原始英文分类。

建议 1–2 个部位，但不要硬限制最大 2 个。

## 12.2 第二步：选择动作

```text
第 2 / 3 步

已选部位：胸 ×  肩 ×

[ 搜索动作… ]

推荐

[图] 坐姿推胸       ✓
     器械 · 胸

[图] 哑铃侧平举     +
     哑铃 · 肩

已选择 3 个
```

排序：审核后的新手推荐 → 器械动作 → 其它 approved 动作。

## 12.3 第三步：确认训练

```text
今天就按这个练

5 个动作 · 15 组 · 约 40 分钟

01 坐姿推胸
组数 3
每组次数 10–12
休息 60 秒

+ 添加动作

[ 开始训练 ]

保存为我的计划
```

需要支持删除、调整顺序、组数、repMin、repMax、restSeconds。主 CTA 必须是“开始训练”，不是保存。

---

# 13. 动作 Tab

动作页不是首页。

```text
动作

[ 搜索动作、器械… ]

胸   背   肩
手臂 腿   核心

常用动作
坐姿推胸
高位下拉
腿举

全部动作
```

正式版动作过滤：

```text
gymEligible = true
contentReviewStatus = approved
```

不要直接把全部原始 dataset 内容视为审核内容。

---

# 14. 动作详情页 ExerciseDetailPage

内容结构固定：

```text
坐姿推胸

[视频 / 示范]

胸部
推胸机

练哪里
怎么做
注意什么
器械怎么调

[ 加入今日训练 ]
```

数据字段必须分开：

```text
stepsZh
cautionsZh
equipmentSetupZh
```

禁止继续使用 `steps[0] => 器械位置`、`steps[1] => 起始姿势` 这种语义伪映射。

---

# 15. 记录页 HistoryPage

```text
记录

本周训练概览
已完成 2 / 2 次

训练历史

8 月 28 日
A · 全身训练
41 分钟 · 5 个动作

8 月 24 日
B · 全身训练
38 分钟 · 5 个动作
```

历史详情：

```text
8 月 28 日
A · 全身训练
41 分钟
5 动作
15 组

坐姿推胸
30kg × 10
30kg × 10
30kg × 9
```

MVP 不做复杂图表、1RM、训练容量、RPE、卡路里、排名。

---

# 16. 设置 SettingsPage

```text
设置

训练
  每周训练次数      2 次 >
  训练日提醒        未开启 >

记录
  重量单位          kg >

存储
  动作媒体          243 MB >
  清理缓存               >

关于
  动作数据来源           >
  媒体版权               >
  隐私说明               >
  训练免责声明           >
  关于动谱               >
```

---

# 17. 正式领域模型

不要继续以当前简化 `PlanItem` 承载全部业务。

至少建立：

```text
Exercise
BeginnerProgram
ProgramWorkout
ProgramExercise
ExerciseAlternative
UserWorkoutPlan
UserPlanExercise
UserProgramState
WorkoutSession
WorkoutExerciseRecord
SetRecord
AppSettings
```

核心关系：

```text
BeginnerProgram
  └── ProgramWorkout A / B
       └── ProgramExercise[]
```

开始训练时：

```text
ProgramWorkout / UserWorkoutPlan
          ↓ snapshot
WorkoutSession
          ↓
WorkoutExerciseRecord[]
          ↓
SetRecord[]
```

原则：**计划是模板，WorkoutSession 是本次真实训练事实。**

历史展示必须基于 snapshot，而不能依赖原计划永远存在。

---

# 18. 数据库第一版

建议先建立：

```text
app_settings
user_program_state
user_workout_plan
user_plan_exercise
workout_session
workout_exercise_record
set_record
```

1324 个静态动作 MVP 可以继续 JSON / rawfile 加载，不要求第一阶段全部导入数据库。

必须保证：

```text
数据库中最多一个 active WorkoutSession
数据库中最多一个 draft UserWorkoutPlan
```

删除 UserWorkoutPlan 不得级联删除历史 WorkoutSession。

---

# 19. Repository 层

UI 不直接写 SQL / ArkData。

至少抽象：

```text
WorkoutRepository
PlanRepository
SettingsRepository
HistoryRepository
ExerciseRepository
```

例如：

```text
WorkoutRepository.startRecommendedWorkout()
WorkoutRepository.getActiveWorkout()
WorkoutRepository.completeSet()
WorkoutRepository.finishWorkout()
WorkoutRepository.abandonWorkout()
WorkoutRepository.moveExerciseToEnd()
WorkoutRepository.replaceExercise()
```

UI 负责展示、用户输入、调用 use-case/repository、处理 loading/error 状态。

---

# 20. Workout 状态机

Agent 需要显式维护状态机，而不是继续依赖页面布尔值堆叠。

推荐状态：

```text
HOME
PREVIEW
EXERCISE
REST
EXERCISE_COMPLETED
COMPLETE
```

核心转换：

```text
HOME
  ↓ start
PREVIEW
  ↓ begin
EXERCISE
  ↓ completeSet
REST
  ↓ restFinished
EXERCISE
  ↓ finalSetOfExercise
EXERCISE_COMPLETED
  ↓ nextExercise
EXERCISE
  ↓ finalExercise
COMPLETE
```

异常：

```text
任何训练状态
  ↓ leave
HOME（active session 保留）
  ↓ resume
恢复到数据库真实状态
```

禁止以 `currentStep`、`isExerciseLibraryOpen`、`detailExerciseId` 等状态不断扩展为整个 APP 的路由系统。

---

# 21. 错误和异常状态

每个页面实现时至少考虑：

### 动作媒体加载失败

显示静态封面或“示范暂时无法加载”，但训练继续。

### 数据库写入失败

“完成本组”不得假装成功。需要提示：

```text
保存失败，请重试
```

并保持当前输入。

### APP 被回收

重新启动先检查 active WorkoutSession。存在时首页显示“训练进行中”。

### 休息计时过期

如果恢复时 `now > restEndAt`，直接显示“休息结束”。

### 动作不存在/资源缺失

历史 snapshot 仍要可展示文字。

---

# 22. 内容与媒体规则

正式推荐计划中的动作必须：

```text
contentReviewStatus = approved
```

需要独立维护：

```text
nameZh
stepsZh
cautionsZh
equipmentSetupZh
alternativeExerciseIds
```

业务逻辑不要假设媒体永久可用。媒体商业授权未完全确认前，不将其作为发布不可替代依赖；保留 attribution；允许后续整体替换媒体资源而不重写领域逻辑。

---

# 23. 实施里程碑

## Milestone 1：拆页面架构

任务：建立 AppRoot、主 Tab、拆 TrainingHome、ExerciseLibrary、ExerciseDetail、自定义训练三步页、提取 Theme 与通用组件。

验收：所有已有功能还能运行；HAP 可构建；无明显回归。

## Milestone 2：ArkData + Domain Model

任务：数据库初始化、schema v1、repository、settings、user program state、workout session、set record。

验收：重启 APP 后 settings 保留；可以创建 active session；active session 重启后仍存在。

## Milestone 3：A/B 推荐计划 + 首页

任务：最小 A/B 样本、首页 nextWorkoutCode、TrainingHome 状态、PreviewPage。

验收：`首页 -> A 训练 -> 预览`，无需进入动作库即可开始推荐训练。

## Milestone 4：Workout Engine

任务：WorkoutPage、weight/reps、completeSet、SetRecord、动作进度、最后组判断。

验收：可以完整完成一个动作的第 1/2/3 组并正确落库。

## Milestone 5：Rest + Resume

任务：restEndAt、休息 UI、±30、skip、锁屏/后台/重启恢复。

验收：训练过程中杀 APP，重开后恢复正确动作/组和休息状态。

## Milestone 6：Exercise Complete + Workout Complete

任务：下一个动作过渡、complete workout、A/B 切换、weekly progress。

验收：完成 A 后历史出现 A，首页下一次变 B。

## Milestone 7：History

任务：history list、detail、last set lookup、下次自动预填。

验收：第二次做同动作显示上次重量和次数。

## Milestone 8：把现有自定义训练接回正式数据层

任务：draft、saved plan、reorder、rep range、rest seconds、start adHoc、save plan。

验收：选部位 -> 选动作 -> 保存 -> 重启 -> 计划仍在 -> 可以训练。

## Milestone 9：替换动作 + 内容审核过滤

任务：alternative sheet、move to end、approved 过滤、gymEligible 过滤。

验收：替换只影响当前 session。

## Milestone 10：发布前 QA

覆盖首次使用、推荐训练、自定义训练、锁屏、后台、杀进程、恢复、媒体失败、数据库失败、历史、删除计划、A/B 切换、kg/lb。

---

# 24. 每次 Agent 修改代码的执行协议

## Step 1：确认当前代码

先查看目标页面、相关 model、repository、是否已有类似组件、是否已有未提交实现。不要直接创建重复代码。

## Step 2：限定本次范围

每个 PR/任务只解决一个可验收目标。例如：

```text
实现 RestPage + restEndAt 恢复
```

不要顺手重做动作库、添加账号或重构全部视觉。

## Step 3：实现

遵循页面无数据库细节、Repository 无 UI、Theme 集中、错误状态可恢复。

## Step 4：构建

必须确保 ArkTS 类型检查通过、HAP build 通过。

## Step 5：回归

至少人工检查当前任务相关主路径。

## Step 6：汇报

Agent 结束时必须说明：

```text
完成了什么
修改了哪些文件
还有什么没做
验证了什么
下一步建议
```

---

# 25. UI 验收标准

视觉效果以当前确认的效果图为基线，不要求像素级复制，但要求信息层级、操作优先级和整体视觉语言一致。

训练页信息层级：

```text
动作名称
>
动作媒体
>
组数/目标
>
上次记录
>
重量次数
>
完成本组
>
次级操作
```

要求：

- 每屏最多一个明显主 CTA；
- 不使用 RPE、1RM、Volume 等新手不需要理解的词；
- 核心操作满足单手点击；
- 训练输入避免表格感；
- 推荐计划减少用户决策，而不是增加配置项。

---

# 26. MVP 明确禁止范围

Agent 未经重新确认，不得实现：

- 登录 / 注册；
- 服务端；
- 社区；
- 好友；
- 排行榜；
- 商城；
- 饮食；
- 卡路里；
- AI 聊天教练；
- AI 自动无限生成训练计划；
- RPE；
- 1RM；
- 训练容量；
- 高级趋势图；
- 复杂社交分享；
- 会员体系。

---

# 27. 最终 MVP Definition of Done

只有下面场景完整通过，MVP 才算完成：

1. 首次安装：打开 APP -> 选每周 2 次 -> 进入首页，无登录。
2. 推荐训练：首页 -> 开始训练 A -> 预览 -> 第一个动作。
3. 完成一组：输入重量/次数 -> 完成本组 -> 数据落库 -> 自动进入休息。
4. 异常恢复：训练进行中 -> 锁屏/后台/杀进程 -> 重开 -> 恢复。
5. 完成训练：最后一组 -> 训练完成页 -> 历史出现 -> 本周 +1。
6. A/B 切换：完成 A -> 下一次 B；完成 B -> 下一次 A。
7. 历史预填：第二次进行同动作 -> 自动显示最近一次重量/次数。
8. 自定义训练：选部位 -> 选动作 -> 改组次 -> 保存 -> 重启 -> 计划仍存在 -> 可以训练。
9. 器械被占：打开替换 -> 换动作 -> 继续训练，原计划不变。
10. 完全离线：无网络仍能完成整场训练。

---

# 28. Agent 最高优先级任务队列

```text
P0
1. 拆 Index.ets
2. 建立 Navigation / AppRoot / Theme
3. 建正式 Domain Model
4. 建 ArkData schema v1
5. 建 WorkoutRepository

P1
6. TrainingHome
7. A/B Program
8. WorkoutPreview
9. WorkoutPage
10. SetRecord
11. Rest + restEndAt
12. active session resume

P2
13. ExerciseCompleted
14. WorkoutComplete
15. History
16. last workout preload

P3
17. 接回自定义训练
18. Saved Plan
19. 替换动作
20. approved 内容过滤

P4
21. 单手操作优化
22. 性能
23. 动画细节
24. 最终视觉打磨
```

除非出现阻塞，否则不要改变顺序。

---

# 29. 第一阶段 Agent Prompt

可直接把下面内容交给 Coding Agent：

```text
你正在维护 dongpu HarmonyOS NEXT 项目。

先阅读仓库 README、PRODUCT_SPEC、IMPLEMENTATION_REFERENCE，以及当前 harmony 工程。

本阶段目标不是新增业务功能，而是为后续训练执行闭环重构前端结构。

要求：

1. 不改变当前已有用户功能。
2. 将 harmony/entry/src/main/ets/pages/Index.ets 中的职责拆分。
3. 建立统一 Theme。
4. 建立 AppRoot / 主导航结构。
5. 将动作库、动作详情、自定义训练三步流程拆成独立页面/组件。
6. 不接入服务器。
7. 不增加新产品功能。
8. 确保 ArkTS 类型检查和 HAP 构建通过。
9. 尽可能减少巨型 Page 内的 @State 数量。
10. 完成后汇报：
   - 文件结构
   - 每个文件职责
   - 原 Index.ets 缩减结果
   - 构建验证结果
   - 下一步如何接 ArkData 和 WorkoutSession

不要为了“架构漂亮”过度设计；这次重构的唯一目的是为 TrainingHome、WorkoutSession、Rest 和 History 提供清晰扩展点。
```

---

# 30. 最终指导思想

动谱不是一个拥有 1324 个动作的健身数据库，也不是一个复杂的专业训练记录器。

它应该是：

> **一个第一次走进健身房的人打开以后，不需要研究、不需要做很多决定，就能知道现在该做什么，并且能够把整场训练顺利完成的本地训练助手。**

Agent 做任何设计和代码决策时，都应该用下面这个问题判断：

> **这个改动是否让用户更快、更确定地完成下一步训练？**

如果答案不是“是”，优先级就应该降低。
