import { APP_COLOR_GREEN_DARK, APP_COLOR_LINE, APP_COLOR_MUTED, APP_COLOR_TEXT } from '../../app/AppTheme';
import { NutritionSummary } from '../../domain/nutrition/NutritionModels';
import { DailyRepresentativeWeight, WaistTrend, WeightTrend, WeightTrendStatus } from '../../domain/progress/ProgressModels';
import { WorkoutSession } from '../../domain/workout/WorkoutModels';

class ProgressTab {
  id: string;
  label: string;

  constructor(id: string, label: string) {
    this.id = id;
    this.label = label;
  }
}

@Component
export struct ProgressPage {
  @Prop trend: WeightTrend = new WeightTrend();
  @Prop waistTrend: WaistTrend = new WaistTrend();
  @Prop nutrition: NutritionSummary = new NutritionSummary();
  @Prop sessions: WorkoutSession[] = [];
  @Prop weeklyCompleted: number = 0;
  @Prop weeklyFrequency: number = 0;
  @State private selectedTab: string = 'weight';
  onBack: () => void = () => {};
  onOpenReview: () => void = () => {};

  private statusText(): string {
    if (this.trend.status === WeightTrendStatus.Normal) return '进度正常';
    if (this.trend.status === WeightTrendStatus.Slow) return '下降偏慢';
    if (this.trend.status === WeightTrendStatus.Fast) return '下降偏快';
    return '数据不足';
  }

  @Builder
  WeightTab() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 4 }) {
          Text(this.trend.currentAverageKg > 0 ? `${this.trend.currentAverageKg.toFixed(1)} kg` : '--')
            .fontSize(30).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
          Text('当前 7 日平均').fontSize(13).fontColor(APP_COLOR_MUTED)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Column({ space: 4 }) {
          Text(this.trend.changeKg === 0 ? '--' : `${this.trend.changeKg > 0 ? '+' : ''}${this.trend.changeKg.toFixed(1)} kg`)
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_GREEN_DARK)
          Text(this.statusText()).fontSize(13).fontColor(APP_COLOR_MUTED)
        }.alignItems(HorizontalAlign.End)
      }.width('100%')
      if (this.trend.status === WeightTrendStatus.Insufficient) {
        Text('至少记录 4 天体重后显示 7 日趋势。').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
      } else {
        Text(`上一周期 ${this.trend.previousAverageKg.toFixed(1)} kg · 当前周期 ${this.trend.currentAverageKg.toFixed(1)} kg`)
          .width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
      }
      Text('每日代表值').width('100%').fontSize(16).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      ForEach(this.trend.dailyWeights.slice(-7).reverse(), (item: DailyRepresentativeWeight) => {
        Row() {
          Text(item.dateKey).fontSize(13).fontColor(APP_COLOR_MUTED).layoutWeight(1)
          Text(`${item.weightKg.toFixed(1)} kg`).fontSize(15).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        }.width('100%').padding({ top: 9, bottom: 9 })
      }, (item: DailyRepresentativeWeight) => item.dateKey)
      if (this.waistTrend.hasData) {
        Row() {
          Text('腰围（最近）').fontSize(14).fontColor(APP_COLOR_MUTED).layoutWeight(1)
          Text(`${this.waistTrend.currentCm.toFixed(1)} cm${this.waistTrend.previousCm > 0 ?
            ` · ${this.waistTrend.changeCm > 0 ? '+' : ''}${this.waistTrend.changeCm.toFixed(1)}` : ''}`)
            .fontSize(14).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
        }.width('100%').padding({ top: 12 })
      } else {
        Text('腰围：每 1—2 周记录一次即可。').fontSize(13).fontColor(APP_COLOR_MUTED)
      }
    }.width('100%').padding(18).borderRadius(18).backgroundColor(Color.White)
      .border({ width: 1, color: APP_COLOR_LINE })
  }

  @Builder
  TrainingTab() {
    Column({ space: 14 }) {
      Text('训练趋势').width('100%').fontSize(18).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      Text(`${this.weeklyCompleted} / ${this.weeklyFrequency} 次 · 本周完成`).fontSize(27).fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK)
      Text(this.sessions.length === 0 ? '完成训练后，这里会保留最近训练记录。' : `最近完成 ${this.sessions.length} 次训练`)
        .fontSize(14).fontColor(APP_COLOR_MUTED)
      Button('查看本周复盘').width('100%').height(44).fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK).backgroundColor('#E4F2E9').borderRadius(12)
        .onClick(() => this.onOpenReview())
      ForEach(this.sessions.slice(0, 5), (session: WorkoutSession) => {
        Row() {
          Column({ space: 3 }) {
            Text(session.workoutNameSnapshot).fontSize(15).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
            Text(new Date(session.completedAt).toLocaleDateString()).fontSize(12).fontColor(APP_COLOR_MUTED)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          Text(`${session.exercises.length} 个动作`).fontSize(13).fontColor(APP_COLOR_MUTED)
        }.width('100%').padding({ top: 9, bottom: 9 })
      }, (session: WorkoutSession) => session.id.toString())
    }.width('100%').padding(18).borderRadius(18).backgroundColor(Color.White)
      .border({ width: 1, color: APP_COLOR_LINE })
  }

  @Builder
  NutritionTab() {
    Column({ space: 14 }) {
      Text('营养趋势').width('100%').fontSize(18).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
      Row() {
        Column({ space: 4 }) {
          Text(`${Math.round(this.nutrition.calories)} kcal`).fontSize(26).fontWeight(FontWeight.Bold)
          Text('今日热量').fontSize(13).fontColor(APP_COLOR_MUTED)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 4 }) {
          Text(`${Math.round(this.nutrition.proteinG)} g`).fontSize(26).fontWeight(FontWeight.Bold)
          Text('今日蛋白质').fontSize(13).fontColor(APP_COLOR_MUTED)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%')
      Text('持续记录饮食后，这里会显示周平均和达标天数。').width('100%').fontSize(14).fontColor(APP_COLOR_MUTED)
    }.width('100%').padding(18).borderRadius(18).backgroundColor(Color.White)
      .border({ width: 1, color: APP_COLOR_LINE })
  }

  build() {
    Column() {
      Row() {
        Button('‹').width(48).height(48).fontSize(34).fontColor(APP_COLOR_TEXT)
          .backgroundColor(Color.Transparent).onClick(() => this.onBack())
        Text('数据趋势').layoutWeight(1).textAlign(TextAlign.Center).fontSize(19).fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Blank().width(48)
      }.width('100%').height(58)
      Row({ space: 8 }) {
        ForEach([new ProgressTab('weight', '体重'), new ProgressTab('training', '训练'),
          new ProgressTab('nutrition', '营养')], (tab: ProgressTab) => {
            Button(tab.label).layoutWeight(1).height(42).fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.selectedTab === tab.id ? APP_COLOR_GREEN_DARK : APP_COLOR_MUTED)
              .backgroundColor(this.selectedTab === tab.id ? '#E4F2E9' : Color.White).borderRadius(12)
              .onClick(() => this.selectedTab = tab.id)
          }, (tab: ProgressTab) => tab.id)
      }.width('100%').padding({ left: 20, right: 20, top: 6, bottom: 10 })
      Scroll() {
        Column({ space: 16 }) {
          if (this.selectedTab === 'weight') {
            this.WeightTab()
          } else if (this.selectedTab === 'training') {
            this.TrainingTab()
          } else {
            this.NutritionTab()
          }
        }.width('100%').padding({ left: 20, right: 20, bottom: 28 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%')
  }
}
