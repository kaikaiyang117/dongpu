# 动谱 HarmonyOS App

原生 ArkTS / ArkUI 工程，目标系统为 HarmonyOS 6.0.1（API 21）。

当前产品是**目标驱动的减脂与力量训练执行助手**，不是旧版“从 1324 个动作中自由组训练”的动作库原型。

## 当前主要能力

- V2 Onboarding / V1 用户升级。
- 当前减脂 Goal。
- 今日 Dashboard。
- 体重、腰围和 7 日趋势。
- 简单饮食与快捷食物。
- 手动步数记录。
- 3 次 Required + Optional 第 4 次训练 Program。
- 推荐训练、自定义训练和保存计划。
- WorkoutSession / 逐组记录 / Rest。
- Active workout 重启恢复。
- 动作替换。
- Double Progression。
- 训练历史。
- Weekly Review。
- 今日 / 训练 / 数据 / 我的 四个 Tab。

## 工程结构

```text
entry/src/main/ets/
├── app/
├── components/
├── data/
│   ├── database/
│   └── repository/
├── domain/
├── services/
├── features/
└── model/
```

当前代码结构说明见仓库根目录：

```text
../docs/APP_STRUCTURE.md
```

做到可用版前的剩余任务见：

```text
../docs/ROADMAP.md
```

## 动作目录

动作数据保留上游稳定 ID。

正式入口通过内容审核字段过滤，不应直接把全部原始动作暴露给用户：

```text
contentReviewStatus
libraryVisible
gymEligible
recommendedForBeginner
```

用户层训练部位收敛为：

```text
胸部 / 背部 / 肩部 / 手臂 / 腿部 / 核心
```

上游动作和媒体仍由现有同步/转换脚本维护。正式分发前必须确认媒体授权和署名要求。

## 数据库

当前数据库版本：3。

数据库详细结构与 migration 约束见：

```text
../docs/DATABASE_DESIGN.md
```

不要通过删除数据库解决 migration 问题。

## 本地构建

```bash
DEVECO_SDK_HOME="$PWD/.sdk" \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
  assembleHap --mode module \
  -p product=default \
  -p module=entry@default \
  -p buildMode=debug \
  --no-daemon
```

构建产物：

```text
entry/build/default/outputs/default/entry-default-signed.hap
```

涉及数据库、训练状态或恢复逻辑的修改，除编译外还必须验证：

```text
Fresh install
旧数据库升级
active workout restart
rest restart
finish idempotency
history intact
```

开发签名材料仅保存在本机，不提交仓库。