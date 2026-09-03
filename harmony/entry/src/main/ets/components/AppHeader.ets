import { APP_COLOR_GREEN_DARK, APP_COLOR_TEXT } from '../app/AppTheme';

@Component
export struct AppHeader {
  @Prop title: string = '';
  @Prop showBack: boolean = false;
  @Prop backGlyph: string = '‹';
  @Prop actionLabel: string = '';
  onBack: () => void = () => {};
  onAction: () => void = () => {};

  private backIcon(): Resource {
    return this.backGlyph === '×' ? $r('app.media.icon_close') : $r('app.media.icon_back');
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.title)
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
        .padding({ left: 64, right: 64 })
      Row() {
        if (this.showBack) {
          Button() {
            Image(this.backIcon()).width(22).height(22).fillColor(APP_COLOR_TEXT)
          }
          .width(48)
          .height(48)
          .backgroundColor(Color.Transparent)
          .stateEffect(true)
          .accessibilityText(this.backGlyph === '×' ? '关闭' : '返回')
          .onClick(() => this.onBack())
        } else {
          Blank().width(48)
        }
        Blank()
        if (this.actionLabel !== '') {
          Button() {
            Text(this.actionLabel)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(APP_COLOR_GREEN_DARK)
          }
          .width(56)
          .height(48)
          .backgroundColor(Color.Transparent)
          .stateEffect(true)
          .accessibilityText(this.actionLabel)
          .onClick(() => this.onAction())
        } else {
          Blank().width(48)
        }
      }.width('100%')
    }
    .width('100%')
    .height(54)
    .padding({ left: 8, right: 8 })
  }
}
