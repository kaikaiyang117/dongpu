import {
  APP_BUTTON_HEIGHT,
  APP_BUTTON_RADIUS,
  APP_COLOR_BG,
  APP_COLOR_GREEN,
  APP_COLOR_SURFACE_DISABLED,
  APP_COLOR_TEXT_DISABLED
} from '../app/AppTheme';

@Component
export struct PrimaryButton {
  @Prop title: string = '';
  @Prop isEnabled: boolean = true;
  onTap: () => void = () => {};

  build() {
    Column() {
      Button(this.title)
        .width('100%')
        .height(APP_BUTTON_HEIGHT)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isEnabled ? Color.White : APP_COLOR_TEXT_DISABLED)
        .borderRadius(APP_BUTTON_RADIUS)
        .backgroundColor(this.isEnabled ? APP_COLOR_GREEN : APP_COLOR_SURFACE_DISABLED)
        .enabled(this.isEnabled)
        .stateEffect(this.isEnabled)
        .onClick(() => this.onTap())
    }
    .width('100%')
    .height(86)
    .padding({ left: 20, right: 20, top: 10, bottom: 18 })
    .backgroundColor(APP_COLOR_BG)
  }
}
