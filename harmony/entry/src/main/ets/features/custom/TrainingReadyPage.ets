import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { findExercise } from '../../data/ExerciseCatalog';
import { Exercise } from '../../model/Exercise';
import { PlanItem } from '../../model/WorkoutData';

@Component
export struct TrainingReadyPage {
  @Prop exercises: Exercise[] = [];
  @Prop planItems: PlanItem[] = [];
  onEditPlan: () => void = () => {};

  private exercise(id: string): Exercise {
    return findExercise(this.exercises, id);
  }

  private totalSets(): number {
    return this.planItems.reduce((total: number, item: PlanItem) => total + item.sets, 0);
  }

  @Builder
  SummaryMetric(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text(label)
        .fontSize(11)
        .fontColor(APP_COLOR_MUTED)
    }
    .layoutWeight(1)
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Stack() {
          Text('✓')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(72)
        .height(72)
        .borderRadius(36)
        .backgroundColor(APP_COLOR_GREEN)
        .margin({ top: 40 })

        Text('计划已准备好')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)
        Text('开始今天的训练')
          .fontSize(31)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Text('先从轻重量热身，感觉动作稳定后再慢慢加重。')
          .fontSize(14)
          .fontColor(APP_COLOR_MUTED)
          .lineHeight(21)
          .textAlign(TextAlign.Center)

        Row() {
          this.SummaryMetric(this.planItems.length.toString(), '个动作')
          this.SummaryMetric(this.totalSets().toString(), '组')
          this.SummaryMetric(Math.max(20, this.planItems.length * 7).toString(), '分钟')
        }
        .width('100%')
        .padding({ top: 18, bottom: 18 })
        .margin({ top: 8 })
        .border({ width: { top: 1, bottom: 1 }, color: APP_COLOR_LINE })

        Column() {
          ForEach(this.planItems, (item: PlanItem, index: number) => {
            Row({ space: 12 }) {
              Text((index + 1).toString())
                .width(18)
                .fontSize(11)
                .fontColor(APP_COLOR_GREEN_DARK)
              Text(this.exercise(item.exerciseId).name)
                .layoutWeight(1)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(APP_COLOR_TEXT)
            }
            .width('100%')
            .height(48)
            .border({ width: { bottom: 1 }, color: APP_COLOR_LINE })
          }, (item: PlanItem) => item.exerciseId)
        }
        .width('100%')

        Button('返回调整计划')
          .width('100%')
          .height(48)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
          .borderRadius(14)
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: APP_COLOR_LINE })
          .onClick(() => this.onEditPlan())
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 32 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
}
