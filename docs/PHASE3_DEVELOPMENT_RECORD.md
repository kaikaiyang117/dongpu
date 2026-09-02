# Phase 3 开发记录

- `OnboardingPage` 已改为五步向导：目标、身体数据、训练条件、饮食记录偏好、方案确认；内存 draft 在完成前维护，不增加中途退出持久化。
- 首个 MVP 只完整生成减脂方案；增肌和保持体型入口明确标注“后续支持”，不会伪装成已完成的专业方案。
- 方案目标使用可解释的体重公式：热量按体重与训练频率估算并设最低值，蛋白质按体重 × 1.8，步数初始为 8000；summary 会在确认前展示并说明可调整。
- 确认后按 profile → body_measurement → active fitness_goal → active_program_state → onboarding completed 顺序写入，并保留旧 `app_settings` 的完成状态兼容现有启动流程。
- HAP 构建通过；设备在本次构建后暂时断开，完整的五步点击/重启烟测待设备恢复后执行。
