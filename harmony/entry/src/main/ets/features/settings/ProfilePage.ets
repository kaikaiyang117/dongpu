import {
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { AppHeader } from '../../components/AppHeader';

@Component
export struct ProfilePage {
  @Prop targetWeightKg: number = 0;
  @Prop targetCalories: number = 0;
  @Prop targetProteinG: number = 0;
  @Prop targetSteps: number = 0;
  @Prop latestWeightKg: number = 0;
  @Prop todaySteps: number = 0;
  @Prop weeklyFrequency: number = 3;
  @Prop weightUnit: string = 'kg';
  onOpenSettings: () => void = () => {};
  onRecordBody: () => void = () => {};

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .width('100%')
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(APP_COLOR_MUTED)
      .padding({ left: 4 })
  }

  @Builder
  Entry(label: string, value: string, onTap: () => void) {
    Button() {
      Row({ space: 12 }) {
        Text(label)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(APP_COLOR_TEXT)
        Text(value).fontSize(13).fontColor(APP_COLOR_MUTED).maxLines(1)
        Text('›').fontSize(24).fontColor(APP_COLOR_MUTED)
      }.width('100%')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 14 })
    .backgroundColor(Color.White)
    .stateEffect(true)
    .accessibilityText(`${label}，${value}`)
    .onClick(() => onTap())
  }

  @Builder
  EntryGroup(firstLabel: string, firstValue: string, firstAction: () => void,
    secondLabel: string, secondValue: string, secondAction: () => void) {
    Column() {
      this.Entry(firstLabel, firstValue, firstAction)
      Divider().strokeWidth(1).color(APP_COLOR_LINE).margin({ left: 16 })
      this.Entry(secondLabel, secondValue, secondAction)
    }
    .width('100%')
    .borderRadius(18)
    .clip(true)
    .border({ width: 1, color: APP_COLOR_LINE })
  }

  build() {
    Column() {
      AppHeader({ title: '我的' })
      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 14 }) {
            Row() {
              Column({ space: 5 }) {
                Text('当前目标').fontSize(13).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_GREEN_DARK)
                Text(this.targetWeightKg > 0 ? `${this.targetWeightKg.toFixed(1)} kg` : '待设置')
                  .fontSize(28).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
                Text('目标体重').fontSize(12).fontColor(APP_COLOR_MUTED)
              }.alignItems(HorizontalAlign.Start)
              Blank()
              Column({ space: 5 }) {
                Text(this.latestWeightKg > 0 ? `${this.latestWeightKg.toFixed(1)} kg` : '--')
                  .fontSize(21).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_TEXT)
                Text('最近体重').fontSize(12).fontColor(APP_COLOR_MUTED)
              }.alignItems(HorizontalAlign.End)
            }.width('100%')
            Text(`${this.targetCalories} kcal · ${this.targetProteinG} g 蛋白质 · ${this.targetSteps} 步`)
              .width('100%').fontSize(13).fontColor(APP_COLOR_MUTED)
          }
          .width('100%').padding(18).borderRadius(20).backgroundColor(APP_COLOR_GREEN_SOFT)

          this.SectionTitle('目标与记录')
          this.EntryGroup('目标设置', `${this.targetCalories} kcal`, () => this.onOpenSettings(),
            '记录身体', this.latestWeightKg > 0 ? `${this.latestWeightKg.toFixed(1)} kg` : '未记录',
            () => this.onRecordBody())

          this.SectionTitle('训练与活动')
          this.EntryGroup('训练偏好', `每周 ${this.weeklyFrequency} 次`, () => this.onOpenSettings(),
            '今日步数', `${this.todaySteps} 步`, () => this.onOpenSettings())

          this.SectionTitle('应用')
          this.EntryGroup('单位与隐私', this.weightUnit, () => this.onOpenSettings(),
            '数据来源', '本地离线', () => this.onOpenSettings())
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 28 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .layoutWeight(1)
  }
}
