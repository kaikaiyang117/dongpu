import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { DashboardChecklistItem, DashboardViewModel } from '../../services/DashboardService';
import { WeightTrendStatus } from '../../domain/progress/ProgressModels';
import { TodayTrainingState } from '../../domain/program/ProgramV2Models';
import { formatWeight, formatWeightChange } from '../../utils/WeightUnit';

@Component
export struct DashboardPage {
  @Prop viewModel: DashboardViewModel = new DashboardViewModel();
  @Prop weightUnit: string = 'kg';
  onResumeWorkout: () => void = () => {};
  onOpenTraining: () => void = () => {};
  onOpenNutrition: () => void = () => {};
  onRecordBody: () => void = () => {};
  onRecordActivity: () => void = () => {};

  private formatWeight(kg: number): string {
    return formatWeight(kg, this.weightUnit);
  }

  private trendText(): string {
    const trend = this.viewModel.weightTrend;
    if (trend.status === WeightTrendStatus.Insufficient) {
      return '数据积累中';
    }
    return `${formatWeightChange(trend.changeKg, this.weightUnit)} · ${trend.changePercent > 0 ? '+' : ''}${trend.changePercent.toFixed(1)}% / 7日`;
  }

  private statusText(): string {
    const status: WeightTrendStatus = this.viewModel.weightTrend.status;
    if (status === WeightTrendStatus.Normal) return '进度正常';
    if (status === WeightTrendStatus.Slow) return '下降偏慢';
    if (status === WeightTrendStatus.Fast) return '下降偏快';
    return '数据不足';
  }

  private latestWeightText(): string {
    return this.viewModel.latestWeight === undefined ? '记录第一笔体重' :
      this.formatWeight(this.viewModel.latestWeight.weightKg);
  }

  private checklistCount(): number {
    return this.viewModel.checklist.filter((item: DashboardChecklistItem) => item.completed).length;
  }

  @Builder
  GoalSummaryCard() {
    Column({ space: 10 }) {
      Row() {
        Text('当前目标').fontSize(14).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
        Blank()
        Text(this.viewModel.goal?.goalType === 'fat_loss' ? '减脂' : '目标').fontSize(13).fontColor(APP_COLOR_GREEN_DARK)
      }.width('100%')
      Row() {
        Column({ space: 5 }) {
          Text(this.latestWeightText()).fontSize(28).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
          Text('最近体重').fontSize(12).fontColor(APP_COLOR_MUTED)
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Column({ space: 5 }) {
        Text(this.viewModel.goal === undefined ? '--' : this.formatWeight(this.viewModel.goal.targetWeightKg))
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
          Text('目标体重').fontSize(12).fontColor(APP_COLOR_MUTED)
        }.alignItems(HorizontalAlign.End)
      }.width('100%')
      Row() {
        Text(this.statusText()).fontSize(13).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_GREEN_DARK)
        Blank()
        Text(this.trendText()).fontSize(13).fontColor(APP_COLOR_MUTED)
      }.width('100%')
    }
    .width('100%').padding(18).borderRadius(20).backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
    .accessibilityText('记录体重')
    .onClick(() => this.onRecordBody())
  }

  @Builder
  ChecklistCard() {
    Column({ space: 12 }) {
      Row() {
        Text('今天还需要做什么').fontSize(17).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Blank()
        Text(`${this.checklistCount()} / ${this.viewModel.checklist.length}`)
          .fontSize(14).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_GREEN_DARK)
      }.width('100%')
      ForEach(this.viewModel.checklist, (item: DashboardChecklistItem) => {
        Row() {
          Text(item.completed ? '✓' : '○').fontSize(18).fontColor(item.completed ? APP_COLOR_GREEN : APP_COLOR_MUTED)
          Text(item.label).layoutWeight(1).fontSize(14).fontColor(item.completed ? APP_COLOR_MUTED : APP_COLOR_TEXT)
          Text(item.completed ? '完成' : '待办').fontSize(12).fontColor(APP_COLOR_MUTED)
        }.width('100%').height(31)
      })
    }
    .width('100%').padding(18).borderRadius(20).backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
  }

  @Builder
  NutritionCard() {
    Column({ space: 12 }) {
      Row() {
        Text('今日营养').fontSize(17).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Blank()
        Text('记录饮食 ›').fontSize(13).fontColor(APP_COLOR_GREEN_DARK)
      }.width('100%')
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text(`${Math.round(this.viewModel.nutrition.calories)} kcal`).fontSize(21).fontWeight(FontWeight.Bold)
          Text(this.viewModel.goal === undefined ? '热量' : `/ ${this.viewModel.goal.targetCalories} kcal`)
            .fontSize(12).fontColor(APP_COLOR_MUTED)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 4 }) {
          Text(`${Math.round(this.viewModel.nutrition.proteinG)} g`).fontSize(21).fontWeight(FontWeight.Bold)
          Text(this.viewModel.goal === undefined ? '蛋白质' : `/ ${this.viewModel.goal.targetProteinG} g`)
            .fontSize(12).fontColor(APP_COLOR_MUTED)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%')
      if (this.viewModel.goal !== undefined) {
        Row() {
          Text(`还可摄入 ${Math.max(0, this.viewModel.goal.targetCalories - this.viewModel.nutrition.calories).toFixed(0)} kcal`)
            .fontSize(12).fontColor(APP_COLOR_MUTED).layoutWeight(1)
          Text(`蛋白质还差 ${Math.max(0, this.viewModel.goal.targetProteinG - this.viewModel.nutrition.proteinG).toFixed(0)} g`)
            .fontSize(12).fontColor(APP_COLOR_MUTED)
        }.width('100%')
      }
    }
    .width('100%').padding(18).borderRadius(20).backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
    .accessibilityText('打开营养记录')
    .onClick(() => this.onOpenNutrition())
  }

  @Builder
  WorkoutCard() {
    if (this.viewModel.activeWorkout !== undefined) {
      Column({ space: 12 }) {
        Text('训练进行中').fontSize(14).fontWeight(FontWeight.Bold).fontColor(Color.White)
        Text(this.viewModel.activeWorkout.workoutNameSnapshot).fontSize(25).fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Text(`已完成 ${this.viewModel.activeWorkout.exercises.filter((item) => item.completedSets >= item.targetSets).length} / ${this.viewModel.activeWorkout.exercises.length} 个动作`)
          .fontSize(14).fontColor(Color.White)
        Button('继续训练').width('100%').height(52).fontSize(16).fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_GREEN_DARK).borderRadius(16).backgroundColor(Color.White)
          .stateEffect(true)
          .onClick(() => this.onResumeWorkout())
      }.width('100%').padding(20).borderRadius(20).backgroundColor(APP_COLOR_GREEN)
    } else if (this.viewModel.todayPlan.state === TodayTrainingState.Completed ||
      this.viewModel.todayPlan.state === TodayTrainingState.Recovery) {
      Column({ space: 8 }) {
        Text(this.viewModel.todayPlan.title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
        Text(this.viewModel.todayPlan.subtitle).fontSize(25).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Text(this.viewModel.todayPlan.reason).fontSize(14).fontColor(APP_COLOR_MUTED)
      }.width('100%').padding(18).borderRadius(20).backgroundColor(APP_COLOR_GREEN_SOFT)
    } else if (this.viewModel.todayWorkout !== undefined) {
      Column({ space: 10 }) {
        Text(this.viewModel.todayPlan.title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
        Text(this.viewModel.todayPlan.subtitle).fontSize(25).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        Text(`${this.viewModel.todayWorkout.exercises.length} 个动作 · 约 ${this.viewModel.todayWorkout.estimatedMinutes} 分钟`)
          .fontSize(14).fontColor(APP_COLOR_MUTED)
        Text(this.viewModel.todayPlan.reason).fontSize(13).fontColor(APP_COLOR_MUTED)
        Button('开始训练').width('100%').height(52).fontSize(16).fontWeight(FontWeight.Bold)
          .fontColor(Color.White).borderRadius(16).backgroundColor(APP_COLOR_GREEN)
          .stateEffect(true)
          .onClick(() => this.onOpenTraining())
      }.width('100%').padding(18).borderRadius(20).backgroundColor(Color.White)
        .border({ width: 1, color: APP_COLOR_LINE })
    } else {
      Column({ space: 8 }) {
        Text('今日训练').fontSize(14).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
        Text('完成目标设置后生成计划').fontSize(17).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      }.width('100%').padding(18).borderRadius(20).backgroundColor(APP_COLOR_GREEN_SOFT)
    }
  }

  @Builder
  ActivityCard() {
    Row() {
      Column({ space: 5 }) {
        Text('今日活动').fontSize(14).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
        Text(this.viewModel.activity === undefined ? '暂无记录' : `${this.viewModel.activity.steps} 步`)
          .fontSize(24).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Text(this.viewModel.goal === undefined ? '目标 --' : `目标 ${this.viewModel.goal.targetSteps} 步`)
        .fontSize(13).fontColor(APP_COLOR_MUTED)
    }.width('100%').padding(18).borderRadius(20).backgroundColor(Color.White)
      .border({ width: 1, color: APP_COLOR_LINE })
      .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.98 })
      .accessibilityText('记录今日步数')
      .onClick(() => this.onRecordActivity())
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          Row() {
            Column({ space: 4 }) {
              Text('动谱').fontSize(25).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
              Text('今天，做一点就很好').fontSize(13).fontColor(APP_COLOR_MUTED)
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Text('今日').fontSize(14).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_GREEN_DARK)
          }.width('100%')
          this.GoalSummaryCard()
          this.ChecklistCard()
          this.NutritionCard()
          this.WorkoutCard()
          this.ActivityCard()
        }.width('100%').padding({ left: 20, right: 20, top: 14, bottom: 28 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').layoutWeight(1)
  }
}
