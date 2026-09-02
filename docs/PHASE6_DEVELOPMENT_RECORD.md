# Phase 6 开发记录：Program Engine

## 已完成

- `ProgramRepository` 负责读取 active program、workout 模板及动作明细，并按 required 顺序推进 `next_required_workout_index`。
- 训练首页展示内置「减脂 · 上肢优先 · 3—4练」的 Push、Pull + 后链、Upper、Optional 及当前周次；Optional 单独入口不改变 required index。
- 推荐训练预览和执行改为使用数据库 `program_workout` / `program_workout_exercise`，并将动作目录快照写入现有 `WorkoutSession`。
- 完成 required Program workout 后推进 Program 状态和周完成数；完成 Optional 不推进 required index，旧 A/B 路径保留为迁移兼容回退。
- 数据库启动时补齐 V2 schema、字段和内置 catalog，覆盖早期 V2 数据库已有版本号但缺少播种数据的情况。

## 验收状态

- `git diff --check`：通过。
- HAP 构建：通过 `TYPE CHECK SUCCESSFUL` 与 `BUILD SUCCESSFUL`；本机 SDK 6.0.2 与仓库目标 6.0.1 的目录元数据差异使用临时隔离映射，构建后已恢复仓库配置。
- HDC 设备验收：训练页显示 Program 名称、Push / Pull + 后链 / Upper / Optional；进入 Push 预览确认动作来自 DB（坐姿推胸 4 组 · 6–10 次、共 6 个动作 / 19 组）。

训练执行重启恢复、Progress、身体记录和设置一致性按后续 Phase 验收。
