# Phase 1 开发记录

- 数据库版本从 V1 升级到 V2；首次安装先创建 V1，再执行同一套 V1→V2 migration，成功后才写入版本号。
- V2 新表、索引、`workout_session` 扩展列和 `suggested_weight_kg` 均按 `DATABASE_DESIGN.md` 实现。
- 内置快捷食物和 `fat_loss_upper_priority_3_4` 计划使用 `INSERT OR IGNORE`，重复启动不会重复种子。
- 动作目录中没有审核通过且 gymEligible 的卧推、三头伸展、胸托划船、罗马尼亚硬拉、面拉、哑铃弯举；分别采用最接近的本地动作 ID，并在 `AppDatabase.ets` 注释中保留替代说明。
- 新增六个 Repository 和对应 V2 domain models；本阶段不改 UI、Dashboard、Onboarding 或 Program Engine。
