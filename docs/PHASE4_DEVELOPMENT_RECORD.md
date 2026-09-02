# Phase 4 开发记录：Dashboard

## 已完成

- 新增 `features/dashboard/DashboardPage.ets`，展示目标摘要、今日 Checklist、营养摘要、今日训练与活动步数。
- Dashboard 优先展示进行中的训练，并保留今日训练入口。
- 底部导航调整为「今日 / 训练 / 数据 / 我的」，移除动作一级 Tab。
- 启动、完成 onboarding、设置返回和训练完成均回到 Dashboard；数据 Tab 暂复用历史页，训练 Tab 暂复用现有训练首页。
- UI 通过 `DashboardService` 获取聚合数据，不直接访问数据库。

## 验收状态

- `git diff --check`：通过。
- HAP 构建：通过 `TYPE CHECK SUCCESSFUL` 与 `BUILD SUCCESSFUL`。由于本机 SDK 6.0.2 的目录元数据与仓库目标 6.0.1 不一致，验收使用了隔离的临时 SDK 元数据映射；仓库配置已恢复。
- 设备验收：通过 HDC 安装并启动 HAP，确认 Dashboard 展示「今天还需要做什么」、营养摘要和四个 Tab；分别确认无足够趋势数据、无 active workout，以及 active workout 时显示「训练进行中 / 继续训练」。

Nutrition 录入、Program Engine、Progress 页面和训练执行适配按计划留到后续 Phase。
