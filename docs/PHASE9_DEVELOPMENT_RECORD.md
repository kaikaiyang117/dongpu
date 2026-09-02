# Phase 9 开发记录：Profile 与 Settings

## 实现内容

- 底部「我的」导航新增 `AppRoute.Profile`，复用现有设置容器并显示 Profile 入口标题。
- 目标区域支持查看并修改每日热量、蛋白质和步数目标。
- 训练区域支持每周训练次数、训练地点、独立腿日和器械偏好。
- 记录区域保留 kg / lb 切换；存储、隐私、版权和免责声明信息继续展示。
- `GoalRepository` 增加 active goal 目标值和训练偏好更新接口；保存后刷新 `DashboardService`，首页下一次渲染立即使用新目标。
- 修改训练频率只更新设置与 active goal 配置，不修改或删除历史 `workout_session` 记录。

## 验收记录

- HAP 构建：通过，日志包含 `TYPE CHECK SUCCESSFUL` 与 `BUILD SUCCESSFUL`。
- 真机验收：通过。底部「我的」可进入设置/Profile 页面，页面展示目标、训练、记录、存储和关于分区。
- 目标和偏好保存使用事务外的单条 active goal 更新，不创建新的 workout，历史训练数据保持不变。
- `git diff --check`：通过。

## 备注

当前测试设备此前遗留的是缺少 active goal 的迁移数据库，因此目标编辑框显示 `0` 并按无 active goal 保护；完整 Onboarding 创建 active goal 后，保存接口会正常更新 Dashboard 目标值。该保护避免在缺少目标时伪造业务数据。
