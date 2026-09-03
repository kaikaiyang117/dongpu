import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT,
  APP_COLOR_WARNING,
  APP_COLOR_WARNING_SOFT
} from '../../app/AppTheme';
import { Exercise } from '../../model/Exercise';
import { WorkoutExerciseRecord } from '../../domain/workout/WorkoutModels';

@Component
export struct ExerciseCompletedPage {
  @Prop completedExercise: WorkoutExerciseRecord = new WorkoutExerciseRecord(0, 0, '', '', '', '', '', '', 0, 3, 8, 12, 60);
  @Prop nextExercise: WorkoutExerciseRecord = new WorkoutExerciseRecord(0, 0, '', '', '', '', '', '', 0, 3, 8, 12, 60);
  @Prop allExercises: Exercise[] = [];
  @State showTips: boolean = false;
  onStartNext: () => void = () => {};

  build() {
    Column({ space: 18 }) {
      Text('✓')
        .width(118)
        .height(118)
        .textAlign(TextAlign.Center)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(59)
        .backgroundColor(APP_COLOR_GREEN)
        .margin({ top: 86 })
      Text(`${this.completedExercise.exerciseNameSnapshot}完成`)
        .fontSize(27)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text(`${this.completedExercise.completedSets} / ${this.completedExercise.targetSets} 组`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK)

      Text('接下来')
        .width('100%')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
        .margin({ top: 34 })

      Row({ space: 16 }) {
        Image($rawfile(this.nextExercise.imagePathSnapshot))
          .width(106)
          .height(106)
          .objectFit(ImageFit.Contain)
          .borderRadius(14)
        Column({ space: 7 }) {
          Text(this.nextExercise.exerciseNameSnapshot)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Text(`${this.nextExercise.partNameSnapshot} · ${this.nextExercise.equipmentNameSnapshot}`)
            .fontSize(13)
            .fontColor(APP_COLOR_MUTED)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .borderRadius(18)
      .backgroundColor(Color.White)
      .border({ width: 1, color: APP_COLOR_LINE })

      Blank()

      Button('开始下一个动作')
        .width('100%')
        .height(58)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(18)
        .backgroundColor(APP_COLOR_GREEN)
        .onClick(() => this.onStartNext())
      Button('动作要点')
        .height(44).fontSize(14).fontColor(APP_COLOR_GREEN_DARK)
        .backgroundColor(Color.Transparent).stateEffect(true)
        .margin({ bottom: 18 })
        .onClick(() => this.showTips = true)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
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
      Text(this.tipsExercise().name)
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
      (e: Exercise) => e.id === this.nextExercise.actualExerciseId
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
