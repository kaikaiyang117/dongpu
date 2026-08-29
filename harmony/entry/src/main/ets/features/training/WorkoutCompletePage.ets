import { APP_COLOR_GREEN, APP_COLOR_GREEN_DARK, APP_COLOR_LINE, APP_COLOR_MUTED, APP_COLOR_TEXT } from '../../app/AppTheme';
import { ExerciseProgress } from '../../domain/workout/WorkoutModels';

@Component
export struct WorkoutCompletePage {
  @Prop workoutCode: string = 'A';
  @Prop workoutName: string = '全身训练';
  @Prop minutes: number = 0;
  @Prop exerciseCount: number = 0;
  @Prop setCount: number = 0;
  @Prop weeklyCompleted: number = 0;
  @Prop weeklyFrequency: number = 2;
  @Prop weightUnit: string = 'kg';
  @Prop progressHighlights: ExerciseProgress[] = [];
  onDone: () => void = () => {};

  private formatWeight(kg: number): string {
    if (this.weightUnit === 'lb') {
      return `${(kg * 2.2046226218).toFixed(1)} lb`;
    }
    return `${kg.toFixed(1)} kg`;
  }

  @Builder
  Metric(value: string, label: string) {
    Column({ space: 5 }) {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text(label)
        .fontSize(11)
        .fontColor(APP_COLOR_MUTED)
    }
    .layoutWeight(1)
  }

  build() {
    Column({ space: 14 }) {
      Text('✓')
        .width(92)
        .height(92)
        .textAlign(TextAlign.Center)
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(46)
        .backgroundColor(APP_COLOR_GREEN)
        .margin({ top: 68 })
      Text('今天完成了')
        .fontSize(29)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text(`${this.workoutCode} · ${this.workoutName}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)

      Row() {
        this.Metric(this.minutes.toString(), '分钟')
        this.Metric(this.exerciseCount.toString(), '动作')
        this.Metric(this.setCount.toString(), '组')
      }
      .width('100%')
      .padding({ top: 20, bottom: 20 })
      .margin({ top: 18 })
      .border({ width: { top: 1, bottom: 1 }, color: APP_COLOR_LINE })

      if (this.progressHighlights.length > 0) {
        Column({ space: 8 }) {
          Text('今天有进步')
            .width('100%')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          ForEach(this.progressHighlights, (progress: ExerciseProgress) => {
            if (progress.hasWeightProgress && progress.hasRepsProgress) {
              Text(`${progress.exerciseName} ${this.formatWeight(progress.previousWeight)} → ${this.formatWeight(progress.currentWeight)}，${progress.previousReps} 次 → ${progress.currentReps} 次`)
                .width('100%')
                .fontSize(14)
                .fontColor(APP_COLOR_GREEN_DARK)
            } else if (progress.hasWeightProgress) {
              Text(`${progress.exerciseName} ${this.formatWeight(progress.previousWeight)} → ${this.formatWeight(progress.currentWeight)}`)
                .width('100%')
                .fontSize(14)
                .fontColor(APP_COLOR_GREEN_DARK)
            } else {
              Text(`${progress.exerciseName} ${progress.previousReps} 次 → ${progress.currentReps} 次`)
                .width('100%')
                .fontSize(14)
                .fontColor(APP_COLOR_GREEN_DARK)
            }
          }, (progress: ExerciseProgress, index: number) => index.toString())
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .borderRadius(16)
        .backgroundColor(Color.White)
        .border({ width: 1, color: APP_COLOR_LINE })
        .margin({ top: 14 })
      }

      Column({ space: 8 }) {
        Text('本周')
          .width('100%')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Text(`已完成 ${this.weeklyCompleted} / ${this.weeklyFrequency} 次`)
          .width('100%')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(18)
      .borderRadius(18)
      .backgroundColor(Color.White)
      .border({ width: 1, color: APP_COLOR_LINE })
      .margin({ top: 22 })

      Blank()

      Button('完成并返回')
        .width('100%')
        .height(58)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(18)
        .backgroundColor(APP_COLOR_GREEN)
        .margin({ bottom: 22 })
        .onClick(() => this.onDone())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
  }
}
