# 动谱 HarmonyOS 6

原生 ArkTS / ArkUI 工程，目标系统为 HarmonyOS 6.0.1（API 21）。

## 当前范围

- 选择 1—2 个训练部位
- 从完整的 1324 个动作目录中多选动作
- 调整每个动作的组数和次数
- 确认并进入训练准备状态
- 复用项目内六类部位插画
- 按 10 个训练部位和 28 类器械浏览 1324 个动作
- 查看器械调整、动作步骤、新手错误和建议组次，并从详情页加入今日训练

动作元数据通过 `sourceId` 映射到：

`../assets/vendor/exercises-dataset/data/exercises.json`

开发测试包接入了全部 1324 张原始 180×180 缩略图，并从对应 GIF 生成 12 FPS H.264 MP4。列表只加载静态封面，进入详情页后才加载视频，避免大量动作同时占用解码器；详情支持播放/暂停、重播和 0.75× 慢动作，并保留
`© Gym visual — https://gymvisual.com/` 署名。正式分发前必须另行确认媒体授权。

动作目录由 `tools/sync_exercise_catalog.mjs` 生成，视频由 `tools/transcode_exercise_media.sh` 批量转换。新增或更新上游数据时重新运行脚本，不需要修改页面代码或添加资源分支。

相关职责已拆分：`model/Exercise.ets` 定义动作模型，`data/ExerciseCatalog.ets` 负责目录加载与查询，`model/WorkoutData.ets` 只保留训练计划模型。

## 本地构建

工程使用 DevEco Studio 6.0.1 内置的 HarmonyOS 6.0.1 SDK。命令行构建前，工程内 `.sdk/HarmonyOS-6.0.1` 会映射到 IDE 的只读 SDK。

```bash
DEVECO_SDK_HOME="$PWD/.sdk" \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
  assembleHap --mode module \
  -p product=default \
  -p module=entry@default \
  -p buildMode=debug \
  --no-daemon
```

构建产物位于：

`entry/build/default/outputs/default/entry-default-signed.hap`

工程已通过 DevEco Studio 自动签名配置在开发设备上运行。签名材料仅保存在本机配置中。
