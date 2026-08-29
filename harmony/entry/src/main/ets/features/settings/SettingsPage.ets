import {
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';

@Component
export struct SettingsPage {
  @Prop weeklyFrequency: number = 2;
  @Prop weightUnit: string = 'kg';
  onBack: () => void = () => {};
  onChangeFrequency: (frequency: number) => void = () => {};
  onChangeWeightUnit: (unit: string) => void = () => {};

  @Builder
  ChoiceButton(label: string, selected: boolean, onTap: () => void) {
    Button(label)
      .height(40)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(selected ? APP_COLOR_GREEN_DARK : APP_COLOR_MUTED)
      .borderRadius(12)
      .backgroundColor(selected ? APP_COLOR_GREEN_SOFT : Color.White)
      .border({ width: 1, color: selected ? APP_COLOR_GREEN_DARK : APP_COLOR_LINE })
      .onClick(() => onTap())
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor(APP_COLOR_TEXT)
      Blank()
      Text(value).fontSize(13).fontColor(APP_COLOR_MUTED)
    }
    .width('100%')
    .height(48)
    .border({ width: { bottom: 1 }, color: APP_COLOR_LINE })
  }

  @Builder
  SectionHeader(title: string) {
    Text(title).width('100%').fontSize(13).fontWeight(FontWeight.Bold).fontColor(APP_COLOR_MUTED)
  }

  build() {
    Column() {
      Row() {
        Button('‹')
          .width(48)
          .height(48)
          .fontSize(34)
          .fontColor(APP_COLOR_TEXT)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onBack())
        Text('设置')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Blank().width(48)
      }
      .width('100%')
      .height(56)

      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 13 }) {
            this.SectionHeader('训练')
            Row() {
              Text('每周训练次数').layoutWeight(1).fontSize(15).fontColor(APP_COLOR_TEXT)
              Row({ space: 8 }) {
                this.ChoiceButton('2 次', this.weeklyFrequency === 2, () => this.onChangeFrequency(2))
                this.ChoiceButton('3 次', this.weeklyFrequency === 3, () => this.onChangeFrequency(3))
              }
            }
            .width('100%')
            this.InfoRow('训练日提醒', '未开启')
          }
          .width('100%')
          .padding(17)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          Column({ space: 13 }) {
            this.SectionHeader('记录')
            Row() {
              Text('重量单位').layoutWeight(1).fontSize(15).fontColor(APP_COLOR_TEXT)
              Row({ space: 8 }) {
                this.ChoiceButton('kg', this.weightUnit === 'kg', () => this.onChangeWeightUnit('kg'))
                this.ChoiceButton('lb', this.weightUnit === 'lb', () => this.onChangeWeightUnit('lb'))
              }
            }
            .width('100%')
          }
          .width('100%')
          .padding(17)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          Column({ space: 13 }) {
            this.SectionHeader('存储')
            this.InfoRow('动作媒体', '本地离线')
            this.InfoRow('清理缓存', '无需清理')
          }
          .width('100%')
          .padding(17)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })

          Column({ space: 13 }) {
            this.SectionHeader('关于')
            this.InfoRow('动作数据来源', 'exercises-dataset')
            this.InfoRow('媒体版权', 'Gym visual · gymvisual.com')
            this.InfoRow('隐私说明', '所有数据仅存本机')
            this.InfoRow('训练免责声明', '量力而行，如有不适请停止')
            this.InfoRow('版本', '1.0.0')
          }
          .width('100%')
          .padding(17)
          .borderRadius(18)
          .backgroundColor(Color.White)
          .border({ width: 1, color: APP_COLOR_LINE })
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
