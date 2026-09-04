import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT,
  APP_COLOR_WARNING,
  APP_COLOR_WARNING_SOFT
} from '../../app/AppTheme';
import { Exercise } from '../../model/Exercise';
import { WorkoutExerciseRecord } from '../../domain/workout/WorkoutModels';

@Component
export struct RestPage {
  @Prop exercise: WorkoutExerciseRecord = new WorkoutExerciseRecord(0, 0, '', '', '', '', '', '', 0, 3, 8, 12, 60);
  @Prop restEndAt: number = 0;
  @Prop allExercises: Exercise[] = [];
  @State remainingSeconds: number = 0;
  @State showTips: boolean = false;
  private timerId: number = -1;
  onAdjust: (deltaSeconds: number) => void = () => {};
  onFinish: () => void = () => {};

  aboutToAppear(): void {
    this.updateRemaining();
    this.timerId = setInterval(() => this.updateRemaining(), 1000);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
    }
  }

  private updateRemaining(): void {
    this.remainingSeconds = Math.max(0, Math.ceil((this.restEndAt - Date.now()) / 1000));
  }

  private timeLabel(): string {
    const minutes: number = Math.floor(this.remainingSeconds / 60);
    const seconds: number = this.remainingSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  private restProgress(): number {
    if (this.exercise.restSeconds <= 0) return 0;
    return Math.max(0, Math.min(100, this.remainingSeconds / this.exercise.restSeconds * 100));
  }

  build() {
    Column({ space: 24 }) {
      Text(this.remainingSeconds > 0 ? '休息' : '休息结束')
        .width('100%')
        .fontSize(29)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)

      Stack({ alignContent: Alignment.Center }) {
        Progress({ value: this.restProgress(), total: 100, type: ProgressType.Ring })
          .width(270).height(270).color(APP_COLOR_GREEN)
          .backgroundColor(APP_COLOR_WARNING_SOFT)
          .style({ strokeWidth: 8 })
        Column({ space: 10 }) {
          Text(this.timeLabel())
            .fontSize(58)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Text(this.remainingSeconds > 0 ? '组间休息' : `准备好开始第 ${this.exercise.completedSets + 1} 组`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_GREEN_DARK)
        }.alignItems(HorizontalAlign.Center)
      }
      .width(270)
      .height(270)
      .margin({ top: 38, bottom: 18 })

      Text(`${this.exercise.exerciseNameSnapshot} · 第 ${this.exercise.completedSets + 1} 组`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)

      Row({ space: 14 }) {
        Button('−30 秒')
          .layoutWeight(1)
          .height(58)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)
          .backgroundColor(Color.White)
          .onClick(() => this.onAdjust(-30))
        Button('+30 秒')
          .layoutWeight(1)
          .height(58)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)
          .backgroundColor(Color.White)
          .onClick(() => this.onAdjust(30))
      }
      .width('100%')
      .margin({ top: 34 })

      Blank()

      Button(this.remainingSeconds > 0 ? '跳过休息' : '开始')
        .width('100%')
        .height(58)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(18)
        .backgroundColor(APP_COLOR_GREEN)
        .onClick(() => this.onFinish())
      Button('查看动作要点')
        .height(44).fontSize(14).fontColor(APP_COLOR_GREEN_DARK)
        .backgroundColor(Color.Transparent).stateEffect(true)
        .margin({ bottom: 18 })
        .onClick(() => this.showTips = true)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 18 })
    .bindSheet($$this.showTips, this.TipsContent(), {
      height: SheetSize.LARGE,
      dragBar: true,
      backgroundColor: Color.White,
      onDisappear: () => this.showTips = false
    })
  }

  @Builder
  TipsContent() {
    Column({ space: 18 }) {
      Text(this.tipsExercise().displayName)
        .width('100%')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)

      Column({ space: 14 }) {
        Text('怎么做')
          .width('100%')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)

        ForEach(this.tipsExercise().stepsZh, (step: string, index: number) => {
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
              .fontSize(14)
              .fontColor(APP_COLOR_TEXT)
              .lineHeight(20)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: 8 }) {
        Text('注意什么')
          .width('100%')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_WARNING)
        Text(this.tipsExercise().cautionsZh)
          .width('100%')
          .fontSize(13)
          .fontColor(APP_COLOR_TEXT)
          .lineHeight(20)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(14)
      .borderRadius(13)
      .backgroundColor(APP_COLOR_WARNING_SOFT)

      Button('知道了')
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(16)
        .backgroundColor(APP_COLOR_GREEN)
        .onClick(() => this.showTips = false)
    }
    .padding({ left: 20, right: 20, top: 18, bottom: 28 })
  }

  private tipsExercise(): Exercise {
    const found: Exercise | undefined = this.allExercises.find(
      (e: Exercise) => e.id === this.exercise.actualExerciseId
    );
    if (found !== undefined) {
      return found;
    }
    return new Exercise({
      id: '', name: '', partId: '', equipment: '', target: '',
      steps: [], caution: '', imagePath: '', motionPath: '', recommended: false
    });
  }
}
