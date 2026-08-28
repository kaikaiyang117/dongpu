# 动谱开发实现参考

| 项目 | 内容 |
| --- | --- |
| 文档版本 | 0.9 |
| 状态 | 实现中 |
| 更新日期 | 2026-08-28 |
| 对应产品规格 | `PRODUCT_SPEC.md` 0.3 |

## 1. 技术基线

- HarmonyOS NEXT 原生应用。
- ArkTS + ArkUI。
- ArkData 本地持久化，具体 API 以项目 SDK 为准。
- 首要真机：HUAWEI Mate 60 Pro。
- 核心流程不依赖登录、服务器或网络。
- 动作数据来自 `hasaneyldrm/exercises-dataset`，计划和新手内容独立维护并经过专业审核。

### 1.1 已落地工程

- 工程目录：`harmony/`。
- DevEco Studio：6.0.1。
- HarmonyOS SDK：6.0.1，API 21。
- 包名：`com.dongpu.fitness`。
- 首个可编译里程碑已完成“部位 → 动作 → 组次 → 开始训练”的内存态闭环。
- 目前未接入 ArkData；持久化、训练执行和历史记录按后续里程碑实现。
- 完整导入本地 vendor 数据集的 1324 个动作，并以数据源 ID 作为稳定主键。
- 已实现按 10 个训练部位和 28 类器械筛选的动作库页面，并接入 1324 张原始 180×180 缩略图及由原 GIF 生成的 12 FPS H.264 MP4 动作示范。
- 动作库采用“左侧部位、右侧动作与器械”的分栏交互，器械筛选随部位切换自动重置。
- 1324 个动作均支持点击进入“器械教练”式详情页，详情包含目标部位、器械、视频控制、器械调整、中文步骤、新手错误、建议组次及“加入今日训练”。
- 已在 HarmonyOS 6.0、API 21、ARM64 虚拟机完成安装、启动及六类动作筛选验证。
- 动作卡片只加载静态封面；详情页按需加载 MP4，并支持播放/暂停、重播和 0.75× 慢动作，避免长列表同时创建大量视频解码器。
- 页面保留 Gym visual 署名；文本和结构采用 MIT License，媒体在正式分发前必须确认独立授权。

## 2. 功能模块

```text
features/
├── training       首页、推荐训练、自定义计划、训练中和完成
├── exercise       动作查询、详情和替换动作
├── history        本周完成度与历史记录
└── settings       频率、训练日、单位、版权和隐私

domain/
├── program        推荐计划、自定义计划及执行进度
├── workout        训练场次和组记录
├── exercise       动作与替换关系
└── statistics     仅实现 MVP 所需的简单对比

data/
├── database       ArkData 初始化和迁移
├── importer       动作及计划内容导入
└── media          动画引用、缓存和失败状态
```

MVP 不实现后端服务、账号模块、社交模块、推荐算法或公开计划市场；自定义计划完全保存在本地。

## 3. 领域模型

### 3.1 Exercise

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 数据源稳定 ID，主键 |
| `nameZh` | string | 面向用户的中文名称 |
| `bodyPart` | string | 标准化部位 |
| `equipment` | string | 标准化器械 |
| `target` | string | 目标肌肉 |
| `gymEligible` | boolean | 是否允许出现在健身房动作选择中 |
| `stepsZh` | string[] | 最多 3 条动作步骤 |
| `cautionsZh` | string[] | 最多 3 条注意事项，需审核 |
| `equipmentSetupZh` | string[]? | 器械调整说明，需审核 |
| `thumbnailRef` | string? | 图片引用 |
| `animationRef` | string? | 动画引用 |
| `attribution` | string? | 媒体署名 |
| `contentReviewStatus` | enum | `unreviewed` / `approved` |

名称不能作为主键。未审核内容不能进入正式新手计划。

### 3.2 BeginnerProgram

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 计划 ID |
| `version` | string | 内容版本 |
| `title` | string | 计划名称 |
| `durationWeeks` | number | MVP 固定为 4 |
| `reviewStatus` | enum | 专业审核状态 |

### 3.3 ProgramWorkout

定义 A/B 训练模板。

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 模板 ID |
| `programId` | string | 所属计划 |
| `code` | `A` / `B` | 训练编号 |
| `estimatedMinutes` | number | 预计时长 |

### 3.4 ProgramExercise

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 计划动作项 ID |
| `programWorkoutId` | string | 所属 A/B 训练 |
| `exerciseId` | string | 动作 ID |
| `orderIndex` | number | 顺序 |
| `plannedSets` | number | 计划组数 |
| `repMin` | number | 次数范围下限 |
| `repMax` | number | 次数范围上限 |
| `restSeconds` | number | 默认休息秒数 |

### 3.5 ExerciseAlternative

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `exerciseId` | string | 原动作 |
| `alternativeExerciseId` | string | 替换动作 |
| `priority` | number | 展示顺序 |
| `reviewStatus` | enum | 审核状态 |

替换关系只来自审核后的内容，不在客户端根据肌群随机生成。

### 3.6 UserWorkoutPlan

自定义临时训练和已保存计划共用该模型。

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 用户计划 ID |
| `name` | string? | 草稿可为空，保存时必填 |
| `status` | enum | `draft` / `saved` |
| `createdAt` | datetime | 创建时间 |
| `updatedAt` | datetime | 最后修改时间 |

数据库中最多保留一个 `draft`。删除 `saved` 计划不得删除由它产生的历史训练。

### 3.7 UserPlanExercise

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 计划动作项 ID |
| `userPlanId` | string | 所属用户计划 |
| `exerciseId` | string | 动作 ID |
| `orderIndex` | number | 顺序 |
| `plannedSets` | number | 默认 3 |
| `repMin` | number | 默认 8 |
| `repMax` | number | 默认 12 |
| `restSeconds` | number | 默认 90 |

同一用户计划内同一个 `exerciseId` 只保留一次。

### 3.8 UserProgramState

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `programId` | string | 当前计划 |
| `programVersion` | string | 开始时版本快照 |
| `weeklyFrequency` | `2` / `3` | 每周训练次数 |
| `nextWorkoutCode` | `A` / `B` | 下一次训练 |
| `startedAt` | datetime | 开始日期 |

### 3.9 WorkoutSession

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 本地生成 ID |
| `nameSnapshot` | string | 本次训练名称快照 |
| `sourceType` | enum | `recommended` / `userPlan` / `adHoc` |
| `sourcePlanId` | string? | 推荐模板或用户计划 ID |
| `sourceVersion` | string? | 推荐计划版本快照 |
| `workoutCode` | `A` / `B` / null | 仅推荐训练使用 |
| `status` | enum | `active` / `completed` |
| `startedAt` | datetime | 开始时间 |
| `completedAt` | datetime? | 完成时间 |

数据库中最多存在一个 `active` 训练。放弃训练可删除，不进入历史。
`sourcePlanId` 不设置级联删除；历史展示依赖名称和动作快照，不依赖原计划继续存在。

### 3.10 WorkoutExerciseRecord

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 本次动作实例 ID |
| `sessionId` | string | 所属训练 |
| `originalExerciseId` | string | 计划原动作 |
| `actualExerciseId` | string | 本次实际动作 |
| `exerciseNameSnapshot` | string | 历史名称快照 |
| `orderIndex` | number | 本次顺序 |
| `plannedSets` | number | 本次计划组数快照 |
| `repMin` | number | 次数下限快照 |
| `repMax` | number | 次数上限快照 |
| `restSeconds` | number | 休息时间快照 |
| `status` | enum | `pending` / `completed` / `skipped` |

### 3.11 SetRecord

| 字段 | 类型示意 | 说明 |
| --- | --- | --- |
| `id` | string | 组 ID |
| `workoutExerciseRecordId` | string | 所属动作 |
| `orderIndex` | number | 组序号 |
| `weightKg` | decimal? | 统一以公斤保存 |
| `reps` | number? | 实际次数 |
| `status` | enum | `pending` / `completed` |
| `completedAt` | datetime? | 完成时间 |

### 3.12 AppSettings

| 字段 | 类型示意 | 默认值 |
| --- | --- | --- |
| `weightUnit` | `kg` / `lb` | `kg` |
| `trainingDays` | number[] | 空，不提醒 |
| `reminderEnabled` | boolean | `false` |

## 4. 核心状态与规则

### 4.1 开始推荐训练

```text
当前 nextWorkoutCode → 创建 active session
→ 复制该模板动作到 WorkoutExerciseRecord
→ 读取每个动作最近一次完成记录作为输入默认值
```

- 创建场次和动作实例使用事务。
- 已有 `active` 场次时只能继续或放弃，不能创建第二场。
- 计划模板更新不修改已经创建的训练场次。

### 4.2 创建与开始自定义训练

```text
创建/恢复 draft → 选择部位并查询 approved 动作
→ 写入 UserPlanExercise → 调整组次和顺序
→ 直接开始 adHoc / 命名后转为 saved 并开始 userPlan
```

- 部位只是筛选条件，不单独写入计划；计划以实际动作列表为准。
- 草稿每次增删、排序和修改组次后立即保存。
- 从已保存计划开始训练时，将计划动作复制为训练快照，之后修改原计划不影响进行中训练。
- 从动作详情加入时，复用现有草稿；没有草稿则创建。
- 直接开始临时训练后可以删除草稿；完成页保存时根据训练快照新建 `saved` 计划。

### 4.3 完成一组

```text
校验输入 → 保存 SetRecord → 启动休息计时
→ 最后一组完成后切换到下一个 pending 动作
```

- 重量不能为负数，最多一位小数。
- 次数为非负整数。
- 每次输入变更和完成操作都及时落库。
- 休息计时的目标结束时间需要持久化；恢复时用当前时间重新计算剩余秒数，不能只保存内存倒计时。

### 4.4 替换动作

- 最多读取两个 `approved` 替换项。
- 替换后更新 `actualExerciseId` 和名称快照。
- 替换只影响当前 `WorkoutExerciseRecord`。
- “稍后再做”只调整本次 `orderIndex`。

### 4.5 完成训练

- 允许跳过动作，但结束前需要一次确认。
- 使用事务写入 `completedAt`、状态并切换 `nextWorkoutCode`。
- 只有 `sourceType = recommended` 时，A 完成后下一次为 B，B 完成后下一次为 A。
- 自定义训练完成后不改变推荐计划进度。
- 首页本周完成度只统计 `completed` 场次。

## 5. 简单反馈口径

MVP 只计算：

- 本周已完成训练次数。
- 本次时长：`completedAt - startedAt`。
- 完成动作数与组数。
- 某动作是否较最近一次增加重量或次数。

不实现训练容量、1RM、RPE、卡路里、连续打卡和排行榜。

## 6. 动作与媒体导入

- `tools/sync_exercise_catalog.mjs` 从 vendor JSON 生成轻量运行时目录，并同步 1324 张封面；页面不维护动作常量或资源映射分支。
- `tools/transcode_exercise_media.sh` 将 1324 个源 GIF 批量转换为 12 FPS H.264 MP4；已存在的视频会跳过，支持增量更新。
- 动作领域模型、目录加载和训练计划模型分别位于 `model/Exercise.ets`、`data/ExerciseCatalog.ets`、`model/WorkoutData.ets`，避免数据扩容继续推高页面复杂度。
- 完整目录负责浏览和自定义训练；推荐计划仍只引用经过专业审核的动作 ID，二者互不混淆。
- `category` 与 `body_part` 重复时，以清洗后的 `bodyPart` 为准。
- 重名动作保留不同 ID。
- 数据集原始步骤不自动视为已经适合小白；发布前需要中文编辑和专业审核。
- 列表使用静态封面，详情按需加载视频；动作文字和训练流程不依赖媒体解码。
- 媒体商业授权未确认时不进入发布包。
- 动作库升级采用 upsert，不级联删除训练历史。

## 7. MVP 验收清单

### 首次使用

- [ ] 不注册账号也能进入 APP。
- [ ] 只选择每周 2 / 3 次即可完成必要设置。
- [ ] 首次设置在正常操作下不超过 1 分钟。

### 首页与训练

- [ ] 首页只有一个主要训练动作按钮。
- [ ] 不编辑计划即可开始 A/B 训练。
- [ ] 一次只显示当前动作，能打开简明要点。
- [ ] 上次重量和次数自动预填。
- [ ] 点击一次完成组并进入休息计时。
- [ ] 锁屏或应用回收后，训练和计时可恢复。
- [ ] 同时不能创建第二场进行中训练。

### 自定义计划

- [ ] 可以按一个或多个训练部位筛选动作。
- [ ] 未审核或不适合健身房的动作不会出现在可选列表。
- [ ] 至少选择一个动作才能进入确认页。
- [ ] 组数、次数范围、休息时间和动作顺序可以修改。
- [ ] 退出创建流程后可以恢复唯一草稿。
- [ ] 临时训练无需命名即可开始。
- [ ] 已保存计划在重启后仍可编辑和再次开始。
- [ ] 删除计划不删除历史训练。

### 替换与异常

- [ ] 器械占用时最多显示两个审核过的替换动作。
- [ ] 替换只影响本次训练。
- [ ] 无替换动作时可以移到末尾或跳过。
- [ ] 媒体加载失败不阻断训练。
- [ ] 断网时可完成整场训练。

### 完成与历史

- [ ] 完成 A 后下次显示 B。
- [ ] 记录页立即出现完成场次。
- [ ] 下次同动作能读取最近一次数据。
- [ ] 动作或计划升级后旧历史仍可阅读。
- [ ] 页面不显示 MVP 排除的专业指标。

## 8. 推荐开发顺序

### 里程碑 0：内容样本与工程验证

- 确定经审核的 A/B 训练草案。
- 选择 30—50 个动作和替换关系。
- 创建 HarmonyOS NEXT 工程并在 Mate 60 Pro 运行。

验收：真机离线打开“训练”首页并读取本地计划。

### 里程碑 1：完整训练主路径

- 首页、训练预览、单动作训练界面。
- 组记录、休息计时、动作切换。
- 异常退出恢复。

验收：不进入动作库也能完成一场 A 训练。

### 里程碑 2：自定义计划

- 按部位筛选动作。
- 自定义草稿、动作选择、组次与排序。
- 保存、编辑和删除用户计划。

验收：用户完成“选胸部 → 选动作 → 保存计划 → 开始训练”，重启后计划仍存在。

### 里程碑 3：动作指导与替换

- 动作示范和简明要点。
- 器械被占用的替换流程。
- 动作搜索。

验收：用户在训练中 10 秒内看懂当前动作要点并完成替换。

### 里程碑 4：记录与发布准备

- 本周完成度、历史和上次数据。
- 设置、隐私、免责声明和版权。
- 单手操作、锁屏、后台、性能和数据库迁移测试。

验收：产品规格中的八个 MVP 场景全部通过。

## 9. 开发前必须确定

1. 经专业审核的 A/B 训练内容。
2. 每个动作的简明步骤、注意事项和替换关系。
3. 媒体授权与正式发布资源。
4. DevEco Studio、HarmonyOS SDK、包名和签名。
5. 锁屏和后台计时在 Mate 60 Pro 上的实际行为。
6. 自定义计划中组数、次数和休息时间允许的上下限。
