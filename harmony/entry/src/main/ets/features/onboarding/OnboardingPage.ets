import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_GREEN_SOFT,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';

@Component
export struct OnboardingPage {
  @Prop selectedFrequency: number = 2;
  @Prop isSaving: boolean = false;
  onSelectFrequency: (frequency: number) => void = () => {};
  onStart: () => void = () => {};

  @Builder
  FrequencyCard(frequency: number) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Row({ space: 8 }) {
        Text(frequency.toString())
          .fontSize(42)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedFrequency === frequency ? APP_COLOR_GREEN_DARK : APP_COLOR_TEXT)
        Text('次')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
          .margin({ top: 20 })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')

      if (this.selectedFrequency === frequency) {
        Text('✓')
          .width(25)
          .height(25)
          .textAlign(TextAlign.Center)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .borderRadius(13)
          .backgroundColor(APP_COLOR_GREEN)
          .margin({ top: 14, right: 14 })
      }
    }
    .layoutWeight(1)
    .height(158)
    .borderRadius(20)
    .backgroundColor(this.selectedFrequency === frequency ? APP_COLOR_GREEN_SOFT : Color.White)
    .border({ width: this.selectedFrequency === frequency ? 1.5 : 1, color: this.selectedFrequency === frequency ?
      APP_COLOR_GREEN : APP_COLOR_LINE })
    .onClick(() => this.onSelectFrequency(frequency))
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 24 }) {
          Text('动谱')
            .width('100%')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
            .margin({ top: 16 })

          Column({ space: 12 }) {
            Text('第一次健身，\n不用先研究计划')
              .width('100%')
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_TEXT)
              .lineHeight(46)
            Text('动谱帮你安排好，从第一步开始就很简单。')
              .width('100%')
              .fontSize(15)
              .fontColor(APP_COLOR_MUTED)
              .lineHeight(22)
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 92, bottom: 24 })

          Text('每周准备练几次？')
            .width('100%')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)

          Row({ space: 14 }) {
            this.FrequencyCard(2)
            this.FrequencyCard(3)
          }
          .width('100%')

          Column({ space: 12 }) {
            Text('推荐每周 2 次')
              .fontSize(13)
              .fontColor(APP_COLOR_GREEN_DARK)
            Text('无伤病限制的成年人适用')
              .fontSize(13)
              .fontColor(APP_COLOR_MUTED)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Column() {
        Button(this.isSaving ? '正在保存…' : '开始使用')
          .width('100%')
          .height(58)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .borderRadius(18)
          .backgroundColor(APP_COLOR_GREEN)
          .enabled(!this.isSaving)
          .onClick(() => this.onStart())
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 22 })
    }
    .width('100%')
    .height('100%')
  }
}
