# V2 整改记录（R1–R9）

## 已完成

- R1：新增 `V2Readiness`，旧 V1 已完成 onboarding 但缺少 profile/goal/program 时进入 `V2UpgradePage`，不会直接进入空目标 Dashboard。
- R2：`WorkoutRepository.finishWorkout` 在同一事务中完成 session close 与 required program index 推进，并对重复完成保持幂等。
- R3–R5：设置与 Onboarding 统一为 3 / 4 练；Program 周次按自然周推导；周训练、Optional 与 Dashboard 完成状态均从 completed session 推导。
- R6：数据库升级到 V3，训练记录快照保存 slot identity 与 `weight_increment_kg`；动作替换和重复 slot 使用精确历史回退规则。
- R7–R9：新增 `WeeklyReviewService` 统一周统计；步数/热量按已记录天数求平均；力量亮点收紧为同重量多次数或更高重量且达到最低次数；趋势状态使用百分比阈值。
- Apple Design：关键 CTA、步进器、导航和选择按钮启用即时按压反馈；底部导航使用轻量半透明层，保留清晰层级与可逆返回路径。

## 验收

- 临时 OpenHarmony SDK 类型检查：`TYPE CHECK SUCCESSFUL`。
- HAP 构建：`BUILD SUCCESSFUL`（构建后已恢复项目与 SDK 配置）。
- SQLite migration smoke check：V2 → V3 slot / increment 回填成功；迁移不删除历史表。
- 原型 `npm run build` 与 `npm run test:sites` 通过；Playwright runtime 仍需本机安装 Chromium。
