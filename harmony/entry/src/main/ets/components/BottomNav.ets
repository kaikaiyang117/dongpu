import {
  APP_COLOR_BG,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../app/AppTheme';

@Component
export struct BottomNav {
  @Prop selectedTab: string = 'training';
  onSelect: (tab: string) => void = () => {};

  @Builder
  NavItem(id: string, label: string) {
    Button(label)
      .layoutWeight(1)
      .height(58)
      .fontSize(13)
      .fontWeight(this.selectedTab === id ? FontWeight.Bold : FontWeight.Medium)
      .fontColor(this.selectedTab === id ? APP_COLOR_GREEN_DARK : APP_COLOR_MUTED)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.onSelect(id))
  }

  build() {
    Row() {
      this.NavItem('training', '训练')
      this.NavItem('exercise', '动作')
      this.NavItem('history', '记录')
    }
    .width('100%')
    .height(72)
    .padding({ left: 12, right: 12, bottom: 8 })
    .backgroundColor(APP_COLOR_BG)
    .border({ width: { top: 1 }, color: APP_COLOR_LINE })
  }
}
