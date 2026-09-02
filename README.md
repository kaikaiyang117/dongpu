# 动谱

动谱是一款面向 HarmonyOS NEXT 的**目标驱动型减脂与力量训练执行助手**。

它不只是记录训练，而是围绕一个明确目标，把每天真正需要完成的事情收敛为：

- 今天吃多少。
- 蛋白质还差多少。
- 今天练什么。
- 步数还差多少。
- 当前体重趋势是否正常。

核心承诺：**打开动谱，就知道今天该吃什么、练什么，以及离目标还差多少。**

## V2 当前产品基线

V2 从原“新手力量训练助手”升级为“减脂 + 力量训练执行系统”。

首个重点使用场景：

```text
目标：减脂
训练：每周 3—4 次
场景：健身房
偏好：上肢优先，不安排独立腿日，但保留基础腿部训练量
跟踪：体重 / 热量 / 蛋白质 / 步数 / 力量训练
```

一级导航：

```text
今日 / 训练 / 数据 / 我的
```

## 开发必读

代码 Agent、Codex 或 Claude Code 开工前按以下顺序阅读：

1. [仓库开发规范](AGENTS.md)
2. [V2 产品功能规格](docs/PRODUCT_SPEC.md)
3. [V2 数据库设计](docs/DATABASE_DESIGN.md)
4. [V2 页面结构与交互状态](docs/PAGE_STRUCTURE.md)
5. [V2 Agent 开发任务拆解](docs/AGENT_IMPLEMENTATION_PLAN.md)
6. [现有实现参考](docs/IMPLEMENTATION_REFERENCE.md)

若文档存在冲突，以前五项为准。

## 技术基线

- 原生工程：[harmony](harmony)
- 平台：HarmonyOS NEXT
- 目标环境：HarmonyOS 6.0.1（API 21）
- 技术：ArkTS + ArkUI + ArkData
- 数据策略：本地优先
- 首要测试设备：HUAWEI Mate 60 Pro
- 动作数据保留上游稳定 ID，不使用中文名称作为主键

## 现有可复用能力

V1 已经建立的训练执行能力不会推翻，V2 会继续复用并适配：

- 推荐/自定义训练启动。
- `WorkoutSession`。
- 动作与组记录。
- 休息倒计时。
- active workout 恢复。
- 动作替换。
- 训练历史。
- 本地动作目录与媒体。

V2 的主要重构集中在：

- 新 Onboarding 与 Goal。
- 今日 Dashboard。
- 身体数据与 7 日趋势。
- 简单饮食/蛋白质记录。
- 3—4 日 Program Engine。
- 四 Tab 信息架构。
- AppRoot 业务状态拆分。

## 开发顺序

不要先重做所有 UI。

推荐执行顺序：

```text
数据库 V2
→ Repository / Service
→ Onboarding
→ Dashboard
→ Nutrition
→ Program Engine
→ 训练执行适配
→ Progress
→ Profile
→ P1 周复盘 / Double Progression
```

详细任务和验收标准见：

[docs/AGENT_IMPLEMENTATION_PLAN.md](docs/AGENT_IMPLEMENTATION_PLAN.md)

## 历史资料

- [健身小白习惯与需求研究](docs/BEGINNER_RESEARCH.md)
- [现有实现参考](docs/IMPLEMENTATION_REFERENCE.md)

历史资料可用于理解已有实现，但不得覆盖 V2 产品规格。