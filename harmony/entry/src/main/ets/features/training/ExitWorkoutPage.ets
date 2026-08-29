import {
  APP_COLOR_DANGER,
  APP_COLOR_GREEN,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';

@Component
export struct ExitWorkoutPage {
  @State abandonArmed: boolean = false;
  onReturnHome: () => void = () => {};
  onContinue: () => void = () => {};
  onAbandon: () => void = () => {};

  build() {
    Column({ space: 18 }) {
      Text('暂时离开训练？')
        .width('100%')
        .fontSize(29)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
        .margin({ top: 80 })
      Text('训练会自动保存，\n下次打开可以继续。')
        .width('100%')
        .fontSize(16)
        .fontColor(APP_COLOR_MUTED)
        .lineHeight(25)

      Blank()

      Button('返回首页')
        .width('100%')
        .height(58)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .borderRadius(18)
        .backgroundColor(APP_COLOR_GREEN)
        .onClick(() => this.onReturnHome())
      Button('继续训练')
        .width('100%')
        .height(54)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
        .borderRadius(17)
        .backgroundColor(Color.White)
        .border({ width: 1, color: APP_COLOR_LINE })
        .onClick(() => this.onContinue())
      Button(this.abandonArmed ? '再次点击，确认放弃' : '放弃本次训练')
        .width('100%')
        .height(50)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_DANGER)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.abandonArmed) {
            this.onAbandon();
          } else {
            this.abandonArmed = true;
          }
        })
        .margin({ bottom: 24 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding({ left: 22, right: 22 })
  }
}
