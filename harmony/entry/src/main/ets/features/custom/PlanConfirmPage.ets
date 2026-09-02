import {
  APP_COLOR_DRAG_HANDLE,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_ICON_MUTED,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_STEPPER_SURFACE,
  APP_COLOR_TEXT,
  APP_PAGE_MARGIN
} from '../../app/AppTheme';
import { PageHero } from '../../components/PageHero';
import { findExercise } from '../../data/ExerciseCatalog';
import { Exercise } from '../../model/Exercise';
import { PlanItem } from '../../model/WorkoutData';

@Component
export struct PlanConfirmPage {
  @Prop exercises: Exercise[] = [];
  @Prop planItems: PlanItem[] = [];
  onUpdatePlan: (id: string, field: string, delta: number) => void = () => {};
  onRemovePlanItem: (id: string) => void = () => {};
  onMovePlanItem: (id: string, delta: number) => void = () => {};
  onEditExercises: () => void = () => {};
  onSavePlan: () => void = () => {};
  @Prop isSaved: boolean = false;
  @Prop errorText: string = '';

  private exercise(id: string): Exercise {
    return findExercise(this.exercises, id);
  }

  private totalSets(): number {
    return this.planItems.reduce((total: number, item: PlanItem) => total + item.sets, 0);
  }

  @Builder
  NumberControl(item: PlanItem, field: string) {
    Row() {
      Text('−')
        .width(30)
        .height(34)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontColor(APP_COLOR_TEXT)
        .onClick(() => this.onUpdatePlan(item.exerciseId, field, -1))
      Text((field === 'sets' ? item.sets : field === 'repMin' ? item.repMin :
        field === 'repMax' ? item.repMax : item.restSeconds).toString())
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text('+')
        .width(30)
        .height(34)
        .textAlign(TextAlign.Center)
        .fontSize(17)
        .fontColor(APP_COLOR_TEXT)
        .onClick(() => this.onUpdatePlan(item.exerciseId, field, 1))
    }
    .width('100%')
    .height(34)
    .borderRadius(10)
    .backgroundColor(APP_COLOR_STEPPER_SURFACE)
  }

  @Builder
  PlanRow(item: PlanItem, index: number) {
    Row({ space: 9 }) {
      Column({ space: 4 }) {
        Text('▲')
          .fontSize(10)
          .fontColor(APP_COLOR_DRAG_HANDLE)
          .onClick(() => this.onMovePlanItem(item.exerciseId, -1))
        Text('▼')
          .fontSize(10)
          .fontColor(APP_COLOR_DRAG_HANDLE)
          .onClick(() => this.onMovePlanItem(item.exerciseId, 1))
      }
      Text((index + 1).toString().padStart(2, '0'))
        .width(28)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK)

      Column({ space: 4 }) {
        Row() {
          Text(this.exercise(item.exerciseId).name)
            .layoutWeight(1)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Text('×')
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .fontSize(18)
            .fontColor(APP_COLOR_ICON_MUTED)
            .onClick(() => this.onRemovePlanItem(item.exerciseId))
        }
        Text(this.exercise(item.exerciseId).equipment)
          .fontSize(11)
          .fontColor(APP_COLOR_MUTED)
        Row({ space: 8 }) {
          Column({ space: 5 }) {
            Text('组数').fontSize(10).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
            this.NumberControl(item, 'sets')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Column({ space: 5 }) {
            Text('最少次数').fontSize(10).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
            this.NumberControl(item, 'repMin')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Column({ space: 5 }) {
            Text('最多次数').fontSize(10).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
            this.NumberControl(item, 'repMax')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .margin({ top: 8 })
        Column({ space: 5 }) {
          Text('休息秒数').fontSize(10).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
          this.NumberControl(item, 'restSeconds')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .borderRadius(17)
    .backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        PageHero({
          eyebrow: '第 3 步 · 确认计划',
          title: '今天就按这个练',
          subtitle: `${this.planItems.length} 个动作 · ${this.totalSets()} 组 · 约 ${Math.max(20,
            this.planItems.length * 7)} 分钟`
        })
        Column({ space: 10 }) {
          ForEach(this.planItems, (item: PlanItem, index: number) => {
            this.PlanRow(item, index)
          }, (item: PlanItem) => item.exerciseId)
        }
        .width('100%')

        Button() {
          Row({ space: 7 }) {
            Text('+').fontSize(18)
            Text('添加或修改动作').fontSize(13).fontWeight(FontWeight.Bold)
          }
        }
        .width('100%')
        .height(48)
        .fontColor(APP_COLOR_TEXT)
        .borderRadius(14)
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: APP_COLOR_LINE })
        .onClick(() => this.onEditExercises())

        Button(this.isSaved ? '已保存为我的计划' : '保存为我的计划')
          .width('100%')
          .height(48)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)
          .borderRadius(14)
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: APP_COLOR_LINE })
          .onClick(() => this.onSavePlan())
        if (this.errorText !== '') {
          Text(this.errorText)
            .width('100%')
            .fontSize(12)
            .fontColor(Color.Red)
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: APP_PAGE_MARGIN, right: APP_PAGE_MARGIN, bottom: 24 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
}
