# 动谱第一阶段架构整改设计 QA

- Source visual truth path: `/Users/mika/project/dongpu/docs/效果图/4.png`
- Implementation screenshot path: `/Users/mika/project/dongpu/harmony/test-artifacts/architecture-2026-08-29/01-custom-step-1.jpeg`
- Full-view comparison path: `/Users/mika/project/dongpu/harmony/test-artifacts/architecture-2026-08-29/07-step-1-comparison.png`
- Viewport: HarmonyOS 6.0.1（API 21）ARM64 虚拟机，1316 × 2832 px；应用内容区域约 y=137..2734。
- Source pixels: 1448 × 1086 px，参考图左侧手机画面约占 482 × 1086 px。
- Implementation pixels: 1316 × 2832 px；对比图按高度缩放到 1086 px，并保留设备画面比例。
- Density normalization: 参考图保留手机框，实机截图保留系统状态栏和导航条；两者按相同显示高度并排，只判断信息层级、布局节奏、色彩与内容，不做像素级尺寸结论。
- State: 自定义训练第 1 / 3 步，默认选择胸部。

**Findings**

- [P1] 应用入口仍是自定义训练，而不是训练首页
  Location: `AppRoot` 初始路由。
  Evidence: 效果图与执行文档要求推荐训练为主入口，当前实机仍直接进入“自定义训练”。
  Impact: 用户第一次打开应用仍需自行配置训练，核心推荐训练闭环尚未建立。
  Fix: 在 ArkData / Domain Model 完成后新增 Onboarding 与 TrainingHome，并把自定义训练放到次级入口。

- [P1] 用户层训练部位尚未收敛为六类
  Location: 自定义训练第 1、2 步与动作目录。
  Evidence: 效果图固定为胸、背、肩、手臂、腿、核心；当前沿用数据集的胸部、背部、肩部、上臂、前臂、大腿、小腿、核心、有氧、颈部。
  Impact: 新手需要理解数据集分类，且与确认稿信息架构不一致。
  Fix: 在内容审核层建立六类用户映射，原始数据分类仅保留在资源层。

- [P1] 动作内容仍含英文原始名称与未审核目录
  Location: 动作选择页、动作库、动作详情。
  Evidence: 实机出现 `archer push up` 等英文名称，当前 1324 条原始数据均可浏览；执行文档要求正式入口只展示 `gymEligible = true` 且 `contentReviewStatus = approved` 的内容。
  Impact: 破坏新手可理解性，也绕过内容审核门槛。
  Fix: 在 Exercise Domain / Repository 阶段补充中文字段、审核状态和正式过滤。

- [P2] 步骤进度与确认稿的视觉结构不同
  Location: 自定义训练三步页顶部。
  Evidence: 效果图使用“第 N / 3 步”与三段横向进度条；当前使用三个圆形节点与连接线。
  Impact: 视觉语言与确认稿不一致，但不阻塞现有流程。
  Fix: 页面架构稳定后，将公共 `StepProgress` 调整为分段条样式。

**Required Fidelity Surfaces**

- Fonts and typography: 字号层级、粗细和中文可读性整体接近确认稿；英文动作名是内容层 P1，不是字体渲染问题。
- Spacing and layout rhythm: 20 vp 页面边距、白卡片、固定主按钮和低信息密度成立；步骤区占高和卡片密度仍与确认稿不同。
- Colors and visual tokens: 暖米白背景、白色卡片、绿色主 CTA 已统一到 `AppTheme.ets`，页面内不再散落颜色常量。
- Image quality and asset fidelity: 使用仓库现有真实部位插画与动作媒体，无占位资源；部位插画风格与效果图的立体渲染不同，暂作为后续 P3 视觉精修。
- Copy and content: 自定义训练主文案基本一致；六类部位、中文动作名和审核过滤仍未达到确认稿。

**Comparison History**

- Pass 1: 对比 `docs/效果图/4.png` 左侧自定义训练第 1 步与实机截图，确认上述 P1/P2 差异。
- Fixes made in this milestone: `Index.ets` 拆分、统一 Theme、明确 AppRoute、页面组件化；这些是后续修复入口、内容映射和训练闭环的前置结构，不会消除本轮视觉 P1/P2。
- Post-fix evidence: `test-artifacts/architecture-2026-08-29/07-step-1-comparison.png`。

**Focused Region Comparison**

- 本轮未另做局部裁切。并排全屏图中的顶部步骤区、六宫格和底部主 CTA 已足够清晰；媒体播放器与动作详情不是本轮视觉整改目标。

**Implementation Checklist**

1. Milestone 2：建立正式 Domain Model、ArkData schema v1 与 Repository。
2. Milestone 3：实现 Onboarding、TrainingHome、A/B 推荐训练和训练预览。
3. 将六类用户部位映射、中文动作字段和审核过滤接入正式数据层。
4. 在页面状态与数据来源稳定后，按效果图完成 StepProgress 与卡片视觉收敛。

final result: blocked
