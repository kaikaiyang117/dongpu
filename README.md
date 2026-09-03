# 动谱

动谱是一款面向 HarmonyOS NEXT 的**目标驱动型减脂与力量训练执行助手**。

核心承诺：

> 打开动谱，就知道今天该吃多少、蛋白质还差多少、该不该训练、练什么，以及当前减脂趋势是否正常。

当前目标不是继续扩功能，而是先把现有 V2 做到可以真实、连续使用。

## 当前产品范围

首个完整支持场景：

```text
目标：减脂
训练：每周 3 次必做 + 可选第 4 次
场景：健身房
偏好：上肢优先，不安排独立腿日，但保留基础腿部训练
跟踪：体重 / 热量 / 蛋白质 / 步数 / 力量训练
```

一级导航：

```text
今日 / 训练 / 数据 / 我的
```

## 技术基线

- 平台：HarmonyOS NEXT / HarmonyOS 6.0.1（API 21）
- 技术：ArkTS + ArkUI + ArkData
- 原生工程：`harmony/`
- 数据策略：本地优先
- 数据库当前版本：3
- 动作数据使用稳定上游 ID，不使用中文名称做主键

核心功能不依赖账号、服务器或网络。

## 开发前必读

任何 Codex / Claude Code / Coding Agent 开工前按顺序阅读：

1. `AGENTS.md`
2. `docs/PRODUCT_SPEC.md`
3. `docs/DATABASE_DESIGN.md`
4. `docs/APP_STRUCTURE.md`
5. `docs/ROADMAP.md`
6. 当前 `harmony/` 源码

文档职责：

```text
PRODUCT_SPEC.md      产品应该是什么
DATABASE_DESIGN.md   当前数据库是什么
APP_STRUCTURE.md     当前代码与页面怎么组织
ROADMAP.md           做到可用版还剩什么
```

历史实现过程以 Git commit 为准，不再维护 `PHASE*_DEVELOPMENT_RECORD.md` 等阶段流水账。

## 当前已有能力

- V2 Onboarding / V1 用户升级入口。
- Goal 与身体数据。
- 今日 Dashboard。
- 简单饮食和快捷食物。
- 3 次 Required + Optional Program。
- 推荐训练、自定义训练和保存计划。
- WorkoutSession / 逐组记录 / Rest。
- Active workout 重启恢复。
- 动作替换。
- Double Progression。
- 训练历史。
- 7 日体重趋势。
- Weekly Review。
- Profile / Settings。

## 当前最重要的未完成项

不要从旧产品文档重新实现功能，只按 `docs/ROADMAP.md` 继续。

当前 P0 重点：

```text
Today Plan 统一决策
→ 3/3 后正确进入 Recovery / Optional
→ Program 周状态真实化
→ 自重动作可完成
→ V2 Upgrade / migration consistency 收尾
→ kg/lb 全 App 统一
→ 核心恢复流程验收
```

在这些完成前，不做 AI Coach、自动改热量、云同步或社区功能。

## 构建

从 `harmony/` 目录执行：

```bash
DEVECO_SDK_HOME="$PWD/.sdk" /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --mode module -p product=default -p module=entry@default -p buildMode=debug --no-daemon
```

输出：

```text
harmony/entry/build/default/outputs/default/entry-default-signed.hap
```

数据库相关修改至少验证：

```text
Fresh install
V1 → latest
V2 → latest
Current DB restart
Active workout recovery
Rest recovery
History intact
```

## 文档策略

主分支只保留当前有效文档。

旧 UI 效果图、旧 Agent 执行指南、阶段开发记录和旧产品研究不再作为仓库开发输入。需要追溯历史时使用 Git history。