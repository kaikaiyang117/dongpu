import { APP_COLOR_GREEN_DARK, APP_COLOR_LINE, APP_COLOR_MUTED, APP_COLOR_TEXT } from '../../app/AppTheme';
import { NutritionSummary } from '../../domain/nutrition/NutritionModels';
import { WaistTrend, WeightTrend, WeightTrendStatus } from '../../domain/progress/ProgressModels';

@Component
export struct WeeklyReviewPage {
  @Prop trend: WeightTrend = new WeightTrend();
  @Prop waistTrend: WaistTrend = new WaistTrend();
  @Prop nutrition: NutritionSummary = new NutritionSummary();
  @Prop weeklyCompleted: number = 0;
  @Prop weeklyFrequency: number = 0;
  @Prop todaySteps: number = 0;
  onBack: () => void = () => {};

  @Builder
  Metric(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor(APP_COLOR_MUTED).layoutWeight(1)
      Text(value).fontSize(16).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
    }.width('100%').padding({ top: 12, bottom: 12 })
  }

  build() {
    Column() {
      Row() {
        Button('‹').width(48).height(48).fontSize(34).fontColor(APP_COLOR_TEXT)
          .backgroundColor(Color.Transparent).onClick(() => this.onBack())
        Text('本周复盘').layoutWeight(1).textAlign(TextAlign.Center).fontSize(19).fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Blank().width(48)
      }.width('100%').height(58)
      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 4 }) {
            Text('把数据看清楚，再决定下一步').fontSize(25).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
            Text('只展示已记录的数据，不用猜测或自动调整目标。').fontSize(14).fontColor(APP_COLOR_MUTED)
          }.width('100%').alignItems(HorizontalAlign.Start)
          Column() {
            this.Metric('体重变化', this.trend.status === WeightTrendStatus.Insufficient ? '数据不足' :
              `${this.trend.changeKg > 0 ? '+' : ''}${this.trend.changeKg.toFixed(1)} kg`)
            this.Metric('腰围变化', this.waistTrend.hasData && this.waistTrend.previousCm > 0 ?
              `${this.waistTrend.changeCm > 0 ? '+' : ''}${this.waistTrend.changeCm.toFixed(1)} cm` : '数据不足')
            this.Metric('训练完成', `${this.weeklyCompleted} / ${this.weeklyFrequency} 次`)
            this.Metric('今日蛋白质', `${Math.round(this.nutrition.proteinG)} g`)
            this.Metric('今日步数', `${this.todaySteps} 步`)
          }.width('100%').padding(18).borderRadius(18).backgroundColor(Color.White)
            .border({ width: 1, color: APP_COLOR_LINE })
          Text('建议：继续记录体重、饮食和训练，积累足够周期数据后再评估趋势。')
            .width('100%').fontSize(14).fontColor(APP_COLOR_GREEN_DARK).padding(16)
            .borderRadius(16).backgroundColor('#E4F2E9')
        }.width('100%').padding({ left: 20, right: 20, bottom: 28 })
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%')
  }
}
