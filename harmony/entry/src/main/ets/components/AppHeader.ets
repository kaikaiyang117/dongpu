import { APP_COLOR_GREEN_DARK, APP_COLOR_TEXT } from '../app/AppTheme';

@Component
export struct AppHeader {
  @Prop title: string = '';
  @Prop showBack: boolean = false;
  @Prop backGlyph: string = '‹';
  @Prop actionLabel: string = '';
  onBack: () => void = () => {};
  onAction: () => void = () => {};

  build() {
    Row() {
      if (this.showBack) {
        Button() {
          Text(this.backGlyph)
            .fontSize(this.backGlyph === '×' ? 25 : 34)
            .fontColor(APP_COLOR_TEXT)
            .fontWeight(FontWeight.Medium)
        }
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.onBack())
      } else {
        Blank().width(56)
      }

      Text(this.title)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)

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
        .onClick(() => this.onAction())
      } else {
        Blank().width(48)
      }
    }
    .width('100%')
    .height(54)
    .padding({ left: 8, right: 8 })
  }
}
