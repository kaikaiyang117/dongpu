import {
  APP_COLOR_BG,
  APP_COLOR_CONTROL_SURFACE,
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_OVERLAY,
  APP_COLOR_PROGRESS_TRACK,
  APP_COLOR_TEXT,
  APP_COLOR_TEXT_TERTIARY,
  APP_COLOR_WARNING,
  APP_COLOR_WARNING_SOFT
} from '../../app/AppTheme';
import { Exercise } from '../../model/Exercise';

@Component
export struct ExerciseDetailPage {
  @Prop exercise: Exercise = new Exercise({
    id: '',
    name: '',
    partId: '',
    equipment: '',
    target: '',
    steps: [],
    caution: '',
    imagePath: '',
    motionPath: '',
    recommended: false
  });
  @Prop isSelected: boolean = false;
  @State isVideoPlaying: boolean = true;
  @State isSlowMode: boolean = false;
  @State videoTime: number = 0;
  @State videoDuration: number = 3;
  @State videoFailed: boolean = false;
  onAddExercise: () => void = () => {};
  private videoController: VideoController = new VideoController();

  aboutToDisappear(): void {
    this.videoController.pause();
  }

  private exerciseMotion(): Resource {
    return $rawfile(this.exercise.motionPath);
  }

  private exercisePoster(): Resource {
    return $rawfile(this.exercise.imagePath);
  }

  private toggleVideo(): void {
    if (this.isVideoPlaying) {
      this.videoController.pause();
      return;
    }
    this.videoController.start();
  }

  private replayVideo(): void {
    this.videoController.setCurrentTime(0);
    this.videoController.start();
  }

  private videoTimeLabel(value: number): string {
    const seconds: number = Math.max(0, Math.floor(value));
    return `00:${seconds.toString().padStart(2, '0')}`;
  }

  @Builder
  DetailMeta(label: string, value: string) {
    Row({ space: 7 }) {
      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_MUTED)
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK)
    }
    .layoutWeight(1)
  }

  @Builder
  DetailPhaseHeader(index: string, title: string) {
    Row({ space: 10 }) {
      Text(index)
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(14)
        .backgroundColor(APP_COLOR_GREEN)
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK)
    }
    .width('100%')
  }

  @Builder
  DetailSetupItem(title: string, description: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text(description)
        .fontSize(13)
        .fontColor(APP_COLOR_MUTED)
        .lineHeight(20)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 38 })
  }

  @Builder
  DetailMetric(value: string, label: string) {
    Column({ space: 3 }) {
      Text(value)
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text(label)
        .fontSize(10)
        .fontColor(APP_COLOR_MUTED)
    }
    .layoutWeight(1)
  }

  @Builder
  DetailVideo() {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (this.videoFailed) {
          Column() {
            Image(this.exercisePoster())
              .width('100%')
              .height(245)
              .objectFit(ImageFit.Contain)
              .borderRadius(17)
            Text('示范暂时无法加载')
              .fontSize(13)
              .fontColor(APP_COLOR_MUTED)
              .margin({ top: 8 })
          }
        } else {
          Video({
            src: this.exerciseMotion(),
            previewUri: this.exercisePoster(),
            currentProgressRate: this.isSlowMode ? PlaybackSpeed.Speed_Forward_0_75_X :
              PlaybackSpeed.Speed_Forward_1_00_X,
            controller: this.videoController
          })
            .width('100%')
            .height(245)
            .controls(false)
            .autoPlay(true)
            .loop(true)
            .muted(true)
            .objectFit(ImageFit.Fill)
            .onStart(() => this.isVideoPlaying = true)
            .onPause(() => this.isVideoPlaying = false)
            .onPrepared((event: PreparedInfo) => this.videoDuration = event.duration)
            .onUpdate((event: PlaybackInfo) => this.videoTime = event.time)
            .onError(() => this.videoFailed = true)
        }

        if (!this.isVideoPlaying) {
          Button('播放')
            .width(68)
            .height(44)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
            .borderRadius(22)
            .backgroundColor(APP_COLOR_OVERLAY)
            .onClick(() => this.toggleVideo())
        }
      }
      .width('100%')
      .height(245)
      .borderRadius(17)
      .backgroundColor(Color.White)

      Progress({ value: this.videoTime, total: this.videoDuration, type: ProgressType.Linear })
        .width('100%')
        .height(4)
        .color(APP_COLOR_GREEN)
        .backgroundColor(APP_COLOR_PROGRESS_TRACK)

      Row({ space: 7 }) {
        Button(this.isSlowMode ? '0.75x 慢动作' : '1x 正常')
          .height(36)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isSlowMode ? APP_COLOR_GREEN_DARK : APP_COLOR_MUTED)
          .borderRadius(12)
          .backgroundColor(this.isSlowMode ? APP_COLOR_GREEN_SOFT : APP_COLOR_CONTROL_SURFACE)
          .onClick(() => this.isSlowMode = !this.isSlowMode)

        Blank()

        Button(this.isVideoPlaying ? '暂停' : '播放')
          .height(36)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
          .borderRadius(12)
          .backgroundColor(APP_COLOR_CONTROL_SURFACE)
          .onClick(() => this.toggleVideo())

        Button('重播')
          .height(36)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
          .borderRadius(12)
          .backgroundColor(APP_COLOR_CONTROL_SURFACE)
          .onClick(() => this.replayVideo())

        Text(`${this.videoTimeLabel(this.videoTime)} / ${this.videoTimeLabel(this.videoDuration)}`)
          .fontSize(10)
          .fontColor(APP_COLOR_MUTED)
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .borderRadius(19)
    .backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
  }

  @Builder
  Content() {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          this.DetailMeta('锻炼部位', this.exercise.target)
          Divider()
            .vertical(true)
            .height(22)
            .strokeWidth(1)
            .color(APP_COLOR_LINE)
          this.DetailMeta('使用器械', this.exercise.equipment)
        }
        .width('100%')
        .height(44)
        .padding({ left: 10, right: 10 })

        this.DetailVideo()

        Column({ space: 14 }) {
          this.DetailPhaseHeader('1', '先调器械')
          this.DetailSetupItem('器械怎么调', this.exercise.equipmentSetupZh)

          Divider().strokeWidth(1).color(APP_COLOR_LINE)

          this.DetailPhaseHeader('2', '再做动作')
          ForEach(this.exercise.stepsZh, (step: string, index: number) => {
            Row({ space: 10 }) {
              Text((index + 1).toString())
                .width(24)
                .height(24)
                .textAlign(TextAlign.Center)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .borderRadius(12)
                .backgroundColor(APP_COLOR_GREEN)

              Text(step)
                .fontSize(13)
                .fontColor(APP_COLOR_TEXT)
                .lineHeight(20)
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          })

          Column({ space: 7 }) {
            Text('避免错误')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_WARNING)
            Text(this.exercise.cautionsZh)
              .fontSize(13)
              .fontColor(APP_COLOR_TEXT)
              .lineHeight(20)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(14)
          .borderRadius(13)
          .backgroundColor(APP_COLOR_WARNING_SOFT)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .borderRadius(18)
        .backgroundColor(Color.White)
        .border({ width: 1, color: APP_COLOR_LINE })

        Row() {
          this.DetailMetric('3组', '建议组数')
          Divider().vertical(true).height(34).color(APP_COLOR_LINE)
          this.DetailMetric('10次', '每组次数')
          Divider().vertical(true).height(34).color(APP_COLOR_LINE)
          this.DetailMetric('60秒', '组间休息')
        }
        .width('100%')
        .height(70)
        .padding({ left: 10, right: 10 })
        .borderRadius(16)
        .backgroundColor(Color.White)
        .border({ width: 1, color: APP_COLOR_LINE })

        Text('动作数据来自 exercises-dataset；示范媒体 © Gym visual · gymvisual.com')
          .width('100%')
          .fontSize(10)
          .fontColor(APP_COLOR_TEXT_TERTIARY)
          .lineHeight(15)
          .textAlign(TextAlign.Center)
          .padding({ top: 2, bottom: 14 })
      }
      .width('100%')
      .padding({ left: 18, right: 18 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  Footer() {
    Column() {
      Button(this.isSelected ? '已加入今日训练' : '加入今日训练')
        .width('100%')
        .height(56)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(17)
        .backgroundColor(this.isSelected ? APP_COLOR_GREEN_DARK : APP_COLOR_GREEN)
        .enabled(!this.isSelected)
        .onClick(() => this.onAddExercise())
    }
    .width('100%')
    .height(78)
    .padding({ left: 18, right: 18, top: 7, bottom: 15 })
    .backgroundColor(APP_COLOR_BG)
  }

  build() {
    Column() {
      this.Content()
      this.Footer()
    }
    .layoutWeight(1)
    .width('100%')
  }
}
