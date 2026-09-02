import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { ProgramWorkout } from '../../domain/program/ProgramModels';

@Component
export struct TrainingHomePage {
  @Prop weeklyFrequency: number = 2;
  @Prop weeklyCompleted: number = 0;
  @Prop workout: ProgramWorkout = new ProgramWorkout('A', '全身训练', 40, []);
  @Prop hasActiveWorkout: boolean = false;
  @Prop activeWorkoutCode: string = '';
  @Prop activeWorkoutName: string = '';
  @Prop activeCompletedExercises: number = 0;
  @Prop activeMinutes: number = 0;
  @Prop hasSavedPlan: boolean = false;
  @Prop savedPlanName: string = '我的计划';
  @Prop savedPlanActionCount: number = 0;
  @Prop savedPlanMinutes: number = 0;
  @Prop savedPlanSummary: string = '';
  onStartRecommended: () => void = () => {};
  onResumeWorkout: () => void = () => {};
  onStartCustom: () => void = () => {};
  onStartSavedPlan: () => void = () => {};
  onOpenSettings: () => void = () => {};
  onOpenHistory: () => void = () => {};

  private progressValue(): number {
    if (this.weeklyFrequency <= 0) {
      return 0;
    }
    return Math.min(100, this.weeklyCompleted / this.weeklyFrequency * 100);
  }

  @Builder
  WeeklyProgress() {
    Column({ space: 13 }) {
      Row() {
        Text('本周训练进度')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Blank()
        Text('查看记录 ›')
          .fontSize(12)
          .fontColor(APP_COLOR_MUTED)
      }
      .onClick(() => this.onOpenHistory())
      Row({ space: 7 }) {
        Text('已完成')
          .fontSize(15)
          .fontColor(APP_COLOR_TEXT)
        Text(`${this.weeklyCompleted} / ${this.weeklyFrequency}`)
          .fontSize(23)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK)
        Text('次')
          .fontSize(14)
          .fontColor(APP_COLOR_TEXT)
      }
      .width('100%')
      Progress({ value: this.progressValue(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(9)
        .color(APP_COLOR_GREEN)
        .backgroundColor(APP_COLOR_LINE)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .borderRadius(18)
    .backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
  }

  @Builder
  ActiveWorkoutCard() {
    Column({ space: 16 }) {
      Row() {
        Text('训练进行中')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Blank()
        Text('LIVE')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 9, right: 9, top: 5, bottom: 5 })
          .borderRadius(7)
          .backgroundColor(APP_COLOR_GREEN_DARK)
      }
      .width('100%')
      Text(`${this.activeWorkoutCode === '' ? this.workout.code : this.activeWorkoutCode} · ${this.activeWorkoutName === '' ? this.workout.name : this.activeWorkoutName}`)
        .width('100%')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ top: 18 })
      Text(`已完成 ${this.activeCompletedExercises} / ${this.workout.exercises.length} 个动作`)
        .width('100%')
        .fontSize(15)
        .fontColor(Color.White)
      Text(`已训练 ${this.activeMinutes} 分钟`)
        .width('100%')
        .fontSize(15)
        .fontColor(Color.White)
      Button('继续训练')
        .width('100%')
        .height(54)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK)
        .borderRadius(17)
        .backgroundColor(Color.White)
        .margin({ top: 8 })
        .onClick(() => this.onResumeWorkout())
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(22)
    .borderRadius(20)
    .backgroundColor(APP_COLOR_GREEN)
  }

  @Builder
  TodayWorkoutCard() {
    Column({ space: 10 }) {
      Text(this.weeklyCompleted >= this.weeklyFrequency ? '下次训练' : '今天的训练')
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text(`${this.workout.code} · ${this.workout.name}`)
        .width('100%')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
        .margin({ top: 8 })
      Text(`${this.workout.exercises.length} 个动作 · 约 ${this.workout.estimatedMinutes} 分钟`)
        .width('100%')
        .fontSize(14)
        .fontColor(APP_COLOR_MUTED)
      Text(this.workout.exercises.map((item) => item.nameSnapshot).slice(0, 3).join(' · ') + ' · …')
        .width('100%')
        .fontSize(13)
        .fontColor(APP_COLOR_MUTED)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Button(this.weeklyCompleted >= this.weeklyFrequency ? '仍然开始训练' : '开始今天训练')
        .width('100%')
        .height(56)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(17)
        .backgroundColor(APP_COLOR_GREEN)
        .margin({ top: 6 })
        .onClick(() => this.onStartRecommended())
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .borderRadius(18)
    .backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Text('动谱')
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Blank()
          Button('设置')
            .height(44)
            .fontSize(13)
            .fontColor(APP_COLOR_GREEN_DARK)
            .backgroundColor(Color.Transparent)
            .onClick(() => this.onOpenSettings())
        }
        .width('100%')

        Text('今天练了么？')
          .width('100%')
          .fontSize(31)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
          .margin({ bottom: 8 })

        if (this.hasActiveWorkout) {
          this.ActiveWorkoutCard()
          this.WeeklyProgress()
        } else {
          this.WeeklyProgress()
          this.TodayWorkoutCard()
        }

        Column({ space: 10 }) {
          Text('自定义训练')
            .width('100%')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)

          if (this.hasSavedPlan) {
            Column({ space: 8 }) {
              Row() {
                Column({ space: 4 }) {
                  Text(this.savedPlanName)
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(APP_COLOR_TEXT)
                  Text(`${this.savedPlanActionCount} 个动作 · 约 ${this.savedPlanMinutes} 分钟`)
                    .fontSize(13)
                    .fontColor(APP_COLOR_MUTED)
                  if (this.savedPlanSummary !== '') {
                    Text(this.savedPlanSummary)
                      .fontSize(12)
                      .fontColor(APP_COLOR_MUTED)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Blank()
                Text('开始 ›')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(APP_COLOR_GREEN_DARK)
              }
              .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(16)
            .borderRadius(16)
            .backgroundColor(Color.White)
            .border({ width: 1, color: APP_COLOR_LINE })
            .onClick(() => this.onStartSavedPlan())
          }

          Button('＋  自定义训练')
            .width('100%')
            .height(52)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_GREEN_DARK)
            .borderRadius(16)
            .backgroundColor(APP_COLOR_GREEN_SOFT)
            .border({ width: 1, color: APP_COLOR_LINE })
            .onClick(() => this.onStartCustom())
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 28 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
}
