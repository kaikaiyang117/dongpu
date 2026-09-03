import {
  APP_COLOR_GREEN_DARK,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT,
  APP_COLOR_OVERLAY
} from '../app/AppTheme';

@Component
export struct BottomNav {
  @Prop selectedTab: string = 'training';
  onSelect: (tab: string) => void = () => {};

  @Builder
  NavItem(id: string, label: string, icon: Resource) {
    Button() {
      Column({ space: 2 }) {
        Image(icon)
          .width(22)
          .height(22)
          .fillColor(this.selectedTab === id ? APP_COLOR_GREEN_DARK : APP_COLOR_MUTED)
        Text(label)
          .fontSize(11)
          .fontWeight(this.selectedTab === id ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedTab === id ? APP_COLOR_GREEN_DARK : APP_COLOR_MUTED)
      }
    }
      .layoutWeight(1)
      .height(62)
      .backgroundColor(Color.Transparent)
      .stateEffect(true)
      .accessibilityText(label)
      .accessibilitySelected(this.selectedTab === id)
      .onClick(() => this.onSelect(id))
  }

  build() {
    Row() {
      this.NavItem('today', '今日', $r('app.media.tab_today'))
      this.NavItem('training', '训练', $r('app.media.tab_training'))
      this.NavItem('progress', '数据', $r('app.media.tab_progress'))
      this.NavItem('profile', '我的', $r('app.media.tab_profile'))
    }
    .width('100%')
    .height(76)
    .padding({ left: 12, right: 12, bottom: 6 })
    .backgroundColor(APP_COLOR_OVERLAY)
    .backgroundBlurStyle(BlurStyle.Thin)
    .border({ width: { top: 1 }, color: APP_COLOR_LINE })
  }
}
