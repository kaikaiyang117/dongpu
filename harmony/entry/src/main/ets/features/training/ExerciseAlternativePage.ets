import {
  APP_COLOR_GREEN,
  APP_COLOR_GREEN_DARK,
  APP_COLOR_LINE,
  APP_COLOR_MUTED,
  APP_COLOR_TEXT
} from '../../app/AppTheme';
import { BODY_PARTS, userPartId } from '../../data/ExerciseCatalog';
import { BodyPart, Exercise } from '../../model/Exercise';

@Component
export struct ExerciseAlternativePage {
  @Prop alternatives: Exercise[] = [];
  @Prop canReplace: boolean = true;
  onReplace: (exerciseId: string) => void = () => {};
  onMoveToEnd: () => void = () => {};
  onCancel: () => void = () => {};

  private partName(partId: string): string {
    const found: BodyPart | undefined = BODY_PARTS.find((part: BodyPart) => part.id === partId);
    if (found !== undefined) {
      return found.name;
    }
    return partId;
  }

  @Builder
  AlternativeCard(exercise: Exercise) {
    Row({ space: 14 }) {
      Image($rawfile(exercise.imagePath))
        .width(90)
        .height(90)
        .objectFit(ImageFit.Contain)
        .borderRadius(14)
        Column({ space: 7 }) {
          Text(exercise.name)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(APP_COLOR_TEXT)
          Text(`${this.partName(userPartId(exercise))} · ${exercise.equipment}`)
            .fontSize(13)
            .fontColor(APP_COLOR_MUTED)
        Button(this.canReplace ? '换成这个动作' : '已记录，不能替换')
          .height(42)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .borderRadius(13)
          .backgroundColor(APP_COLOR_GREEN)
          .enabled(this.canReplace)
          .onClick(() => this.onReplace(exercise.id))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .borderRadius(18)
    .backgroundColor(Color.White)
    .border({ width: 1, color: APP_COLOR_LINE })
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Button('‹')
          .width(48)
          .height(48)
          .fontSize(34)
          .fontColor(APP_COLOR_TEXT)
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onCancel())
        Text('替换动作')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(APP_COLOR_TEXT)
        Blank().width(48)
      }
      .width('100%')

      Text('器械被占用了？')
        .width('100%')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_TEXT)
      Text('试试用下面动作替代，继续训练吧。替换只影响本次训练。')
        .width('100%')
        .fontSize(14)
        .fontColor(APP_COLOR_MUTED)
        .lineHeight(22)

      ForEach(this.alternatives, (exercise: Exercise) => {
        this.AlternativeCard(exercise)
      }, (exercise: Exercise) => exercise.id)

      Blank()

      Button('稍后再做这个动作')
        .width('100%')
        .height(52)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(APP_COLOR_GREEN_DARK)
        .borderRadius(16)
        .backgroundColor(Color.White)
        .border({ width: 1, color: APP_COLOR_LINE })
        .onClick(() => this.onMoveToEnd())
      Button('取消')
        .width('100%')
        .height(48)
        .fontSize(14)
        .fontColor(APP_COLOR_MUTED)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.onCancel())
        .margin({ bottom: 18 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
  }
}
