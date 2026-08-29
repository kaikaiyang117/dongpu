import {
  APP_COLOR_GREEN,
  APP_COLOR_LINE_STRONG
} from '../app/AppTheme';

@Component
export struct StepProgress {
  @Prop currentStep: number = 1;

  build() {
    Row({ space: 8 }) {
      ForEach([1, 2, 3], (step: number) => {
        Row()
          .layoutWeight(1)
          .height(6)
          .borderRadius(3)
          .backgroundColor(step <= this.currentStep ? APP_COLOR_GREEN : APP_COLOR_LINE_STRONG)
      })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(34)
    .padding({ left: 20, right: 20 })
  }
}
