# Phase 2 开发记录

- 新增 `ProgressModels`、`TrendService` 和 `DashboardService`，把 V2 趋势与今日聚合从 UI 侧预留到 service 层。
- `TrendService` 使用本地日期分组，每天取最后一条有效体重；当前/前一窗口各覆盖连续 7 个本地日，窗口少于 4 个有效日返回 `insufficient`。
- `changeKg` 与 `changePercent` 按产品文档定义计算。产品未规定 coaching 阈值，当前 MVP 使用显式区间：周变化 ≤ -1kg 为 `fast`，≤ -0.2kg 为 `normal`，其余为 `slow`，后续可独立替换。
- `DashboardService` 聚合 active goal、最近体重、趋势、当日营养、步数、今日 Program workout、五项 checklist 和 active workout；AppRoot 当前没有 V2 SQL 或趋势计算，后续页面接入可直接消费 ViewModel。
