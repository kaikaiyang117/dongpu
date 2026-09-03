# 动谱可用版 Roadmap

> 当前目标：先把现有产品做到可以真实连续使用，不扩大战线。

## P0：做到可用前必须完成

### 1. Today Plan 统一决策

新增统一业务层，建议 `TodayPlanService` 或并入 `ProgramService`。

必须输出明确状态：

```text
Active
Required
Optional
Recovery
Completed
```

验收：

```text
周一 Push
周三 Pull
周五 Upper

3练用户周六
→ 本周 3 / 3
→ Recovery
→ 不再推荐 Push

4练用户周六
→ 本周 3 / 3
→ Optional
```

Dashboard 与 TrainingHome 必须使用同一个 Today Plan，不允许各自推断。

### 2. Program 周状态真实化

训练页的：

```text
已完成
下一项
待完成
Optional
```

必须从本周 completed `workout_session` 推导。

禁止继续使用：

```text
index < nextRequiredWorkoutIndex
```

推测历史完成状态。

### 3. 自重动作可正常训练

自重动作允许：

```text
weight = 0
reps > 0
```

并且“完成本组”按钮可用。

当前阶段不要求完整实现 duration / assisted weight，只先保证自重动作不被重量输入阻断。

### 4. R10 数据一致性收尾

完成：

- V2 Upgrade 实际预填已有身高、体重和频率。
- 清理 `frequency === 3 ? 4 : 4` 等无意义表达式。
- 统一 3练/4练在 goal 中的 frequency min/max 语义。
- 检查 V2→V3 repair 顺序：seed 数据必须在依赖它的历史 backfill 前可用。
- Onboarding / Upgrade 至少做到幂等；理想状态为单事务完成 Profile + Goal + ProgramState + Measurement。

### 5. kg/lb 统一

数据库始终存 kg。

新增统一 Formatter/Converter：

```text
formatWeight
kgToDisplay
inputToKg
```

替换 Profile、Dashboard、Body Entry、Workout、History、Progress 中散落的单位转换。

### 6. 关键恢复路径验收

必须真实验证：

- Workout 中杀 App。
- Rest 中杀 App。
- 完成最后一组后杀 App。
- 返回首页再继续训练。
- 重复 finish 不推进两次 Program。

## P1：让每天使用更省事

### 7. 步数快速记录 Sheet

Dashboard 点活动卡后直接记录步数，不再绕到 Profile → Settings。

### 8. 饮食快速记录

优先：

- 最近使用食物。
- 复制上一餐。
- 一键添加乳清蛋白等快捷食物。
- 默认保留上一份量。

不做大型食物库。

### 9. ProgramService

从 AppRoot 搬出：

- active Program 加载。
- Program → UI model 转换。
- 当前周状态。
- Required / Optional 选择。
- Workout preview 选择。

AppRoot 最终只负责 lifecycle、route 和 feature wiring。

### 10. 业务自动测试

至少覆盖：

```text
TrendService
WeeklyReviewService
TodayPlanService
ProgramService
Workout finish 幂等
Double Progression
Fresh/V1/V2 migration
kg/lb conversion
bodyweight set
```

重点固定场景：

```text
3 Required 全部完成后：
3练 → Recovery
4练 → Optional
```

## P2：P0/P1 稳定后再做

- HarmonyOS 健康步数接入。
- 更完整活动数据。
- 14 天规则调整建议。
- 自动建议热量/步数调整，但必须由用户确认。
- 更多 Program 模板。

## 暂缓

做到可用版前不要实现：

- AI Coach。
- AI 聊天页。
- AI 自动改计划。
- 云同步。
- 社区/排行榜/积分。
- 商城。
- 大型食物数据库。
- 复杂 1RM / fatigue 模型。

## Definition of Done：可用版

满足以下条件后，可以把 V2 视为“可以开始真实长期使用”：

- [ ] Fresh install 正常。
- [ ] V1 老用户升级不丢训练历史。
- [ ] Dashboard 每天给出的训练建议正确。
- [ ] 本周 3 / 3 后不会重新催 Push。
- [ ] 4练用户能正确进入 Optional。
- [ ] 自重动作可完成。
- [ ] Program / Custom / Saved workout 均可开始和完成。
- [ ] Active workout / Rest 可重启恢复。
- [ ] 训练历史和 Double Progression 数据正确。
- [ ] 体重、饮食、步数都能低成本记录。
- [ ] 周统计不把未记录日当 0。
- [ ] kg/lb 全 App 一致。
- [ ] HAP Type Check / Build 通过。
- [ ] 核心业务规则有自动测试或可重复脚本测试。

完成上述内容后，再进入 Health 数据与自动调整阶段。