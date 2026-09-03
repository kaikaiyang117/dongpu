import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { ProgramExercise, ProgramWorkout } from '../../domain/program/ProgramModels';
import { AppHeader } from '../../components/AppHeader';

@Component
export struct WorkoutPreviewPage {
  @Prop workout: ProgramWorkout = new ProgramWorkout('A', '全身训练', 40, []);
  @Prop isStarting: boolean = false;
  onBack: () => void = () => {};
  onStart: () => void = () => {};

  private totalSets(): number {
    return this.workout.exercises.reduce((total: number, exercise: ProgramExercise) => total + exercise.sets, 0);
  }

  build() {
    Column() {
      AppHeader({ title: '今日训练', showBack: true, onBack: () => this.onBack() })

      Scroll() {
        Column({ space: 15 }) {
          Column({ space: 12 }) {
            Text(`${this.workout.code} · ${this.workout.name}`)
              .width('100%')
              .fontSize(29)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_TEXT)
            Text(`约 ${this.workout.estimatedMinutes} 分钟`)
              .width('100%')
              .fontSize(14)
              .fontColor(APP_COLOR_GREEN_DARK)
            Text(`${this.workout.exercises.length} 个动作 · ${this.totalSets()} 组`)
              .width('100%')
              .fontSize(14)
              .fontColor(APP_COLOR_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(18)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          ForEach(this.workout.exercises, (exercise: ProgramExercise, index: number) => {
            Row({ space: 13 }) {
              Text((index + 1).toString().padStart(2, '0'))
                .width(36)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(APP_COLOR_GREEN_DARK)
              Image($rawfile(exercise.imagePath))
                .width(72)
                .height(72)
                .objectFit(ImageFit.Contain)
                .borderRadius(12)
              Column({ space: 5 }) {
                Text(exercise.nameSnapshot)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(APP_COLOR_TEXT)
                Text(`${exercise.sets} 组 · ${exercise.repMin}–${exercise.repMax} 次`)
                  .fontSize(12)
                  .fontColor(APP_COLOR_MUTED)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(13)
            .borderRadius(17)
            .backgroundColor(Color.White)
            .border({ width: 1, color: APP_COLOR_LINE })
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Column() {
        Button(this.isStarting ? '正在准备训练…' : '开始第一个动作')
          .width('100%')
          .height(58)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .borderRadius(18)
          .backgroundColor(APP_COLOR_GREEN)
          .enabled(!this.isStarting)
          .onClick(() => this.onStart())
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
  }
}
