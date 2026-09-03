import {
  APP_COLOR_GREEN_DARK,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { SetRecord, WorkoutExerciseRecord, WorkoutSession, WorkoutStatus, WorkoutPhase } from '../../domain/workout/WorkoutModels';
import { AppHeader } from '../../components/AppHeader';

@Component
export struct WorkoutHistoryDetailPage {
  @Prop session: WorkoutSession = new WorkoutSession(0, '', '', '', 
    WorkoutStatus.Completed, WorkoutPhase.Complete, 0, 0);
  @Prop weightUnit: string = 'kg';
  onBack: () => void = () => {};

  private dateText(timestamp: number): string {
    const date: Date = new Date(timestamp);
    return `${date.getMonth() + 1} 月 ${date.getDate()} 日`;
  }

  private minutes(): number {
    return Math.max(1, Math.floor((this.session.completedAt - this.session.startedAt) / 60000));
  }

  private setCount(): number {
    return this.session.exercises.reduce((total: number, exercise: WorkoutExerciseRecord) =>
      total + exercise.setRecords.length, 0);
  }

  private formatWeight(kg: number): string {
    if (this.weightUnit === 'lb') {
      return `${(kg * 2.2046226218).toFixed(1)} lb`;
    }
    return `${kg.toFixed(1)} kg`;
  }

  @Builder
  ExerciseSection(exercise: WorkoutExerciseRecord) {
    Column({ space: 8 }) {
      Row() {
        Text(exercise.exerciseNameSnapshot)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
          .layoutWeight(1)
        Text(`${exercise.completedSets} 组`)
          .fontSize(13)
          .fontColor(APP_COLOR_MUTED)
      }
      .width('100%')

      ForEach(exercise.setRecords, (record: SetRecord, index: number) => {
        Row() {
          Text(`第 ${index + 1} 组`)
            .fontSize(13)
            .fontColor(APP_COLOR_MUTED)
            .width(60)
          Text(this.formatWeight(record.weight))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
            .layoutWeight(1)
          Text(`× ${record.reps}`)
            .fontSize(14)
            .fontColor(APP_COLOR_TEXT)
        }
        .width('100%')
        .height(38)
        .border({ width: { bottom: 1 }, color: APP_COLOR_LINE })
      }, (record: SetRecord) => record.id.toString())
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: 14 })
    .border({ width: { top: 1 }, color: APP_COLOR_LINE })
  }

  build() {
    Column() {
      AppHeader({ title: '训练详情', showBack: true, onBack: () => this.onBack() })

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 10 }) {
            Text(this.dateText(this.session.completedAt))
              .width('100%')
              .fontSize(14)
              .fontColor(APP_COLOR_GREEN_DARK)
            Text(`${this.session.workoutCode} · ${this.session.workoutNameSnapshot}`)
              .width('100%')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_TEXT)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Row({ space: 24 }) {
            Column({ space: 4 }) {
              Text(this.minutes().toString())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(APP_COLOR_TEXT)
              Text('分钟')
                .fontSize(11)
                .fontColor(APP_COLOR_MUTED)
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(this.session.exercises.length.toString())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(APP_COLOR_TEXT)
              Text('动作')
                .fontSize(11)
                .fontColor(APP_COLOR_MUTED)
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(this.setCount().toString())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(APP_COLOR_TEXT)
              Text('组')
                .fontSize(11)
                .fontColor(APP_COLOR_MUTED)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding({ top: 18, bottom: 18 })
          .border({ width: { top: 1, bottom: 1 }, color: APP_COLOR_LINE })

          ForEach(this.session.exercises, (exercise: WorkoutExerciseRecord) => {
            this.ExerciseSection(exercise)
          }, (exercise: WorkoutExerciseRecord) => exercise.id.toString())
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 28 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}
