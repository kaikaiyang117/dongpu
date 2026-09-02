# Phase 4 开发记录：Dashboard

## 已完成

- 新增 `features/dashboard/DashboardPage.ets`，展示目标摘要、今日 Checklist、营养摘要、今日训练与活动步数。
- Dashboard 优先展示进行中的训练，并保留今日训练入口。
- 底部导航调整为「今日 / 训练 / 数据 / 我的」，移除动作一级 Tab。
- 启动、完成 onboarding、设置返回和训练完成均回到 Dashboard；数据 Tab 暂复用历史页，训练 Tab 暂复用现有训练首页。
- UI 通过 `DashboardService` 获取聚合数据，不直接访问数据库。

## 验收状态

- `git diff --check`：通过。
- HAP 构建：待本机 DevEco SDK 修复后执行。当前安装的 SDK 为 6.0.2，缺少仓库目标 6.0.1 所需的可识别组件元数据，Hvigor 在编译前报 `00303168 SDK component missing`。
- 设备验收：待 HAP 构建恢复后执行 Dashboard 三状态验收。

Nutrition 录入、Program Engine、Progress 页面和训练执行适配按计划留到后续 Phase。
