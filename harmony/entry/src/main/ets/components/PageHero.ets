import { APP_COLOR_GREEN_DARK, APP_COLOR_MUTED, APP_COLOR_TEXT } from '../app/AppTheme';

@Component
export struct PageHero {
  @Prop eyebrow: string = '';
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    Column({ space: 6 }) {
      Text(this.eyebrow)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK)
        .letterSpacing(0.5)
      Text(this.title)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text(this.subtitle)
        .fontSize(14)
        .fontColor(APP_COLOR_MUTED)
        .lineHeight(21)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
